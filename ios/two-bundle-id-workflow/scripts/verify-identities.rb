#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "pathname"
require "tmpdir"

options = { report: nil }
OptionParser.new do |parser|
  parser.banner = "Usage: verify-identities.sh APP_ROOT [--report PATH]"
  parser.on("--report PATH") { |value| options[:report] = value }
end.parse!

root = Pathname.new(ARGV.fetch(0) { abort "APP_ROOT is required" }).realpath
report_path = options[:report] || File.join(Dir.tmpdir, "two-bundle-identities-#{Process.pid}.json")
discover = File.expand_path("discover-identities.rb", __dir__)
system("ruby", discover, root.to_s, "--output", report_path) or abort "Discovery failed"
report = JSON.parse(File.read(report_path))

failures = []
configs = report.fetch("configurations")
%w[Debug Preview Release].each do |required|
  failures << "missing configuration #{required}" unless configs.include?(required)
end

targets = report.fetch("targets").reject { |target| target =~ /(Tests|UITests|Snapshot)/i }
app_target = targets.find { |target| target !~ /(Widget|Extension|Watch)/i } || targets.first
failures << "no app target discovered" unless app_target

if app_target
  app_settings = report.fetch("settings").fetch(app_target, {})
  debug = app_settings.fetch("Debug", {})
  preview = app_settings.fetch("Preview", {})
  release = app_settings.fetch("Release", {})
  debug_id = debug["PRODUCT_BUNDLE_IDENTIFIER"]
  preview_id = preview["PRODUCT_BUNDLE_IDENTIFIER"]
  release_id = release["PRODUCT_BUNDLE_IDENTIFIER"]
  failures << "Debug bundle ID is missing" if debug_id.to_s.empty?
  failures << "Preview bundle ID is missing" if preview_id.to_s.empty?
  failures << "Release bundle ID is missing" if release_id.to_s.empty?
  failures << "development and production bundle IDs are equal" if !debug_id.to_s.empty? && debug_id == release_id
  failures << "Preview must use the Debug bundle ID" if !preview_id.to_s.empty? && preview_id != debug_id
  failures << "Debug and Release entitlements are not split" if debug["CODE_SIGN_ENTITLEMENTS"].to_s == release["CODE_SIGN_ENTITLEMENTS"].to_s
  failures << "Debug and Release display names are not split" if debug["INFOPLIST_KEY_CFBundleDisplayName"].to_s == release["INFOPLIST_KEY_CFBundleDisplayName"].to_s
  failures << "Debug and Release app icons are not split" if debug["ASSETCATALOG_COMPILER_APPICON_NAME"].to_s == release["ASSETCATALOG_COMPILER_APPICON_NAME"].to_s
  failures << "Preview must define PREVIEW or DEVELOPMENT" unless preview["SWIFT_ACTIVE_COMPILATION_CONDITIONS"].to_s.match?(/(?:PREVIEW|DEVELOPMENT)/)
end

targets.each do |target|
  target_settings = report.fetch("settings").fetch(target, {})
  next unless target_settings.key?("Debug") && target_settings.key?("Preview") && target_settings.key?("Release")

  development = target_settings.dig("Debug", "PRODUCT_BUNDLE_IDENTIFIER")
  production = target_settings.dig("Release", "PRODUCT_BUNDLE_IDENTIFIER")
  failures << "#{target}: development and production bundle IDs are equal" if development == production
  failures << "#{target}: Preview does not equal Debug bundle ID" unless target_settings.dig("Preview", "PRODUCT_BUNDLE_IDENTIFIER") == development
end

report.fetch("urlSchemes").each do |entry|
  values = entry.fetch("values")
  if values.length == 1 && values.first !~ /\$\(/ && !values.first.end_with?("-dev")
    failures << "#{entry.fetch('file')}: URL scheme is hard-coded/shared (#{values.join(', ')})"
  end
end

if failures.empty?
  puts "PASS: two-bundle identity invariants hold for #{app_target}."
  exit 0
end

puts "FAIL: #{failures.length} identity invariant(s) need attention."
failures.each { |failure| puts "- #{failure}" }
exit 1
