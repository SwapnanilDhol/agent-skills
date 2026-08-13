#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "optparse"
require "pathname"

options = {
  app_root: nil,
  app_name: nil,
  app_slug: nil,
  repository: nil,
  production_bundle_id: nil,
  development_bundle_id: nil,
  output: "docs/build/two-bundle-id.md"
}

OptionParser.new do |parser|
  parser.banner = "Usage: bootstrap-app-runbook.sh --app-root PATH --app-name NAME --app-slug SLUG --repository OWNER/REPO --production-bundle-id ID [--development-bundle-id ID] [--output RELATIVE_PATH]"
  parser.on("--app-root PATH") { |value| options[:app_root] = value }
  parser.on("--app-name NAME") { |value| options[:app_name] = value }
  parser.on("--app-slug SLUG") { |value| options[:app_slug] = value }
  parser.on("--repository OWNER/REPO") { |value| options[:repository] = value }
  parser.on("--production-bundle-id ID") { |value| options[:production_bundle_id] = value }
  parser.on("--development-bundle-id ID") { |value| options[:development_bundle_id] = value }
  parser.on("--output RELATIVE_PATH") { |value| options[:output] = value }
end.parse!

required = %i[app_root app_name app_slug repository production_bundle_id]
required.each { |key| abort "--#{key.to_s.tr('_', '-')} is required" if options[key].to_s.empty? }
abort "invalid --app-slug" unless options[:app_slug].match?(/\A[a-z0-9-]+\z/)
abort "invalid --repository" unless options[:repository].match?(/\A[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\z/)
bundle_pattern = /\A[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+\z/
abort "invalid --production-bundle-id" unless options[:production_bundle_id].match?(bundle_pattern)
options[:development_bundle_id] ||= "#{options[:production_bundle_id]}.dev"
abort "invalid --development-bundle-id" unless options[:development_bundle_id].match?(bundle_pattern)
abort "development and production bundle IDs must differ" if options[:development_bundle_id] == options[:production_bundle_id]

app_root = Pathname.new(options[:app_root]).realpath
relative_output = Pathname.new(options[:output])
abort "--output must be relative to the app root" if relative_output.absolute? || relative_output.each_filename.include?("..")
output = app_root.join(relative_output)
abort "refusing to overwrite existing runbook: #{output}" if output.exist?

template = Pathname.new(__dir__).join("../assets/app-runbook-template.md").realpath.read
replacements = {
  "{{APP_NAME}}" => options[:app_name],
  "{{APP_SLUG}}" => options[:app_slug],
  "{{REPOSITORY}}" => options[:repository],
  "{{PRODUCTION_BUNDLE_ID}}" => options[:production_bundle_id],
  "{{DEVELOPMENT_BUNDLE_ID}}" => options[:development_bundle_id]
}
replacements.each { |placeholder, value| template = template.gsub(placeholder, value) }

FileUtils.mkdir_p(output.dirname)
output.write(template)
puts output
