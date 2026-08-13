#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "digest"
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

def app_icon_png(root, target_name, catalog_name, failures, label)
  if catalog_name.to_s.empty?
    failures << "#{label} app icon catalog name is missing"
    return nil
  end

  catalogs = root.glob("**/#{catalog_name}.appiconset")
  target_catalogs = catalogs.select do |path|
    path.relative_path_from(root).each_filename.any? { |component| component.casecmp?(target_name) }
  end
  catalogs = target_catalogs unless target_catalogs.empty?
  if catalogs.empty?
    failures << "#{label} app icon catalog is missing (#{catalog_name}.appiconset)"
    return nil
  end
  if catalogs.length > 1
    failures << "#{label} app icon catalog is ambiguous (#{catalogs.length} matches for #{catalog_name})"
    return nil
  end

  catalog = catalogs.first
  contents_path = catalog.join("Contents.json")
  unless contents_path.file?
    failures << "#{label} app icon Contents.json is missing (#{catalog})"
    return nil
  end

  contents = JSON.parse(contents_path.read)
  slot = Array(contents["images"]).find do |image|
    image["idiom"] == "universal" && image["platform"] == "ios" && image["size"] == "1024x1024"
  end
  unless slot
    failures << "#{label} app icon lacks a universal iOS 1024x1024 slot"
    return nil
  end

  filename = slot["filename"].to_s
  if filename.empty?
    failures << "#{label} app icon slot has no filename"
    return nil
  end
  image_path = catalog.join(filename)
  unless image_path.file?
    failures << "#{label} app icon PNG is missing (#{image_path})"
    return nil
  end

  header = image_path.binread(26)
  unless header.byteslice(0, 8) == "\x89PNG\r\n\x1A\n".b && header.byteslice(12, 4) == "IHDR"
    failures << "#{label} app icon must be a PNG (#{image_path})"
    return nil
  end

  width, height = header.byteslice(16, 8).unpack("NN")
  color_type = header.getbyte(25)
  failures << "#{label} app icon must be 1024x1024 (found #{width}x#{height})" unless width == 1024 && height == 1024
  if label == "development" && [4, 6].include?(color_type)
    failures << "development app icon must be opaque (PNG color type #{color_type} has alpha)"
  end
  image_path
rescue JSON::ParserError => error
  failures << "#{label} app icon Contents.json is invalid (#{error.message})"
  nil
end

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
  development_icon = app_icon_png(root, app_target, debug["ASSETCATALOG_COMPILER_APPICON_NAME"], failures, "development")
  production_icon = app_icon_png(root, app_target, release["ASSETCATALOG_COMPILER_APPICON_NAME"], failures, "production")
  if development_icon && production_icon && Digest::SHA256.file(development_icon) == Digest::SHA256.file(production_icon)
    failures << "development and production app icon PNGs are identical"
  end
  debug_group = debug["APP_GROUP_IDENTIFIER"].to_s
  release_group = release["APP_GROUP_IDENTIFIER"].to_s
  if !debug_group.empty? || !release_group.empty?
    failures << "Debug app group is missing" if debug_group.empty?
    failures << "Release app group is missing" if release_group.empty?
    failures << "Debug and Release app groups are not split" if !debug_group.empty? && debug_group == release_group
  end
  debug_scheme = debug["URL_SCHEME"].to_s
  release_scheme = release["URL_SCHEME"].to_s
  if !debug_scheme.empty? || !release_scheme.empty?
    failures << "Debug URL scheme is missing" if debug_scheme.empty?
    failures << "Release URL scheme is missing" if release_scheme.empty?
    failures << "Debug and Release URL schemes are not split" if !debug_scheme.empty? && debug_scheme == release_scheme
  end
  failures << "Preview must define PREVIEW or DEVELOPMENT" unless preview["SWIFT_ACTIVE_COMPILATION_CONDITIONS"].to_s.match?(/(?:PREVIEW|DEVELOPMENT)/)
end

targets.each do |target|
  target_settings = report.fetch("settings").fetch(target, {})
  next unless target_settings.key?("Debug") && target_settings.key?("Preview") && target_settings.key?("Release")

  development = target_settings.dig("Debug", "PRODUCT_BUNDLE_IDENTIFIER")
  production = target_settings.dig("Release", "PRODUCT_BUNDLE_IDENTIFIER")
  failures << "#{target}: development and production bundle IDs are equal" if development == production
  failures << "#{target}: Preview does not equal Debug bundle ID" unless target_settings.dig("Preview", "PRODUCT_BUNDLE_IDENTIFIER") == development

  development_entitlements = target_settings.dig("Debug", "CODE_SIGN_ENTITLEMENTS").to_s
  production_entitlements = target_settings.dig("Release", "CODE_SIGN_ENTITLEMENTS").to_s
  if !development_entitlements.empty? || !production_entitlements.empty?
    failures << "#{target}: development entitlements are missing" if development_entitlements.empty?
    failures << "#{target}: production entitlements are missing" if production_entitlements.empty?
    if !development_entitlements.empty? && development_entitlements == production_entitlements
      failures << "#{target}: development and production entitlements are not split"
    end
  end

  development_group = target_settings.dig("Debug", "APP_GROUP_IDENTIFIER").to_s
  production_group = target_settings.dig("Release", "APP_GROUP_IDENTIFIER").to_s
  if !development_group.empty? || !production_group.empty?
    failures << "#{target}: development app group is missing" if development_group.empty?
    failures << "#{target}: production app group is missing" if production_group.empty?
    if !development_group.empty? && development_group == production_group
      failures << "#{target}: development and production app groups are not split"
    end
  end
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
