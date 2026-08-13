#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "open3"
require "pathname"

options = { output: nil, project: nil, scheme: nil }
OptionParser.new do |parser|
  parser.banner = "Usage: discover-identities.sh APP_ROOT [options]"
  parser.on("--output PATH") { |value| options[:output] = value }
  parser.on("--project PATH") { |value| options[:project] = value }
  parser.on("--scheme NAME") { |value| options[:scheme] = value }
end.parse!

root = Pathname.new(ARGV.fetch(0) { abort "APP_ROOT is required" }).realpath
project = options[:project] ? Pathname.new(options[:project]).expand_path : root.glob("*.xcodeproj").first
abort "No .xcodeproj found; pass --project" unless project && project.directory?

def run_json(*command)
  stdout, stderr, status = Open3.capture3(*command)
  return [JSON.parse(stdout), nil] if status.success?

  [nil, stderr.lines.last(5).join.strip]
rescue JSON::ParserError => error
  [nil, "invalid JSON: #{error.message}"]
end

list, list_error = run_json("xcodebuild", "-project", project.to_s, "-list", "-json")
targets = Array(list && list["project"] && list["project"]["targets"]).sort
schemes = Array(list && list["project"] && list["project"]["schemes"]).sort
scheme = options[:scheme] || schemes.first

pbxproj = project.join("project.pbxproj").read
config_names = pbxproj.scan(/\bname = ([A-Za-z0-9_.-]+);/).flatten
config_names = (config_names & %w[Debug Preview Release Testing]).uniq
config_names = %w[Debug Preview Release] if config_names.empty?

settings = {}
config_errors = {}
relevant_settings = %w[
  PRODUCT_BUNDLE_IDENTIFIER CODE_SIGN_ENTITLEMENTS INFOPLIST_FILE
  INFOPLIST_KEY_CFBundleDisplayName INFOPLIST_KEY_CFBundleName PRODUCT_NAME
  ASSETCATALOG_COMPILER_APPICON_NAME SWIFT_ACTIVE_COMPILATION_CONDITIONS
  DEVELOPMENT_TEAM TARGETED_DEVICE_FAMILY APPLICATION_EXTENSION_API_ONLY
  WRAPPER_EXTENSION PRODUCT_MODULE_NAME
]
targets.each do |target|
  settings[target] = {}
  config_names.each do |configuration|
    command = ["xcodebuild", "-project", project.to_s, "-target", target,
               "-configuration", configuration, "-showBuildSettings", "-json"]
    parsed, error = run_json(*command)
    entry = Array(parsed).find { |item| item["target"] == target } || Array(parsed).first
    raw_settings = entry && entry["buildSettings"] || {}
    settings[target][configuration] = raw_settings.slice(*relevant_settings)
    config_errors["#{target}:#{configuration}"] = error unless entry
  end
end

def file_values(root, glob, pattern)
  root.glob(glob).sort.each_with_object([]) do |path, values|
    text = path.read
    matches = text.scan(pattern).flatten.uniq.sort
    values << { "file" => path.relative_path_from(root).to_s, "values" => matches } unless matches.empty?
  rescue Errno::ENOENT
    next
  end
end

def setting_values(settings, key)
  settings.values.each_with_object([]) do |target_settings, result|
    target_settings.values.each do |configuration_settings|
      value = configuration_settings[key]
      result << value unless value.nil? || value.empty?
    end
  end.uniq.sort
end

report = {
  "schemaVersion" => 1,
  "root" => root.to_s,
  "project" => project.relative_path_from(root).to_s,
  "scheme" => scheme,
  "schemes" => schemes,
  "targets" => targets,
  "configurations" => config_names,
  "settings" => settings,
  "settingsErrors" => config_errors,
  "listError" => list_error,
  "appGroups" => file_values(root, "**/*.entitlements", /group\.[A-Za-z0-9_.-]+/),
  "urlSchemes" => file_values(root, "**/*.plist", /<key>CFBundleURLSchemes<\/key>[\s\S]{0,300}?<string>([^<]+)<\/string>/),
  "bundleLiterals" => file_values(root, "**/*.{pbxproj,xcconfig,plist,swift}", /(?:com\.[A-Za-z0-9_-]+\.[A-Za-z0-9_.-]+)/),
  "bundleIdentifiers" => setting_values(settings, "PRODUCT_BUNDLE_IDENTIFIER"),
}

json = JSON.pretty_generate(report) + "\n"
if options[:output]
  File.write(options[:output], json)
  puts options[:output]
else
  puts json
end

warn "Discovery completed with #{config_errors.length} unavailable target/configuration pairs." unless config_errors.empty?
