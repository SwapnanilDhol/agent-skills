#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "optparse"
require "pathname"
require "yaml"

options = { indie_ops: nil, app_slug: nil }
OptionParser.new do |parser|
  parser.banner = "Usage: verify-slack-preview-handoff.sh APP_ROOT --indie-ops PATH --app-slug SLUG"
  parser.on("--indie-ops PATH") { |value| options[:indie_ops] = value }
  parser.on("--app-slug SLUG") { |value| options[:app_slug] = value }
end.parse!

app_root = Pathname.new(ARGV.fetch(0) { abort "APP_ROOT is required" }).realpath
indie_ops = Pathname.new(options[:indie_ops] || abort("--indie-ops is required")).realpath
slug = options[:app_slug].to_s
abort "--app-slug is required" unless slug.match?(/\A[a-z0-9-]+\z/)

failures = []

def tracked?(root, relative_path)
  _stdout, _stderr, status = Open3.capture3(
    "git", "-C", root.to_s, "ls-files", "--error-unmatch", relative_path
  )
  status.success?
end

def run(*command)
  stdout, stderr, status = Open3.capture3(*command)
  [stdout.strip, stderr.strip, status.success?]
end

codemagic_path = app_root.join("codemagic.yaml")
script_path = app_root.join(".ci/device-preview.sh")
unless codemagic_path.file?
  failures << "app: codemagic.yaml is missing"
end
unless script_path.file?
  failures << "app: .ci/device-preview.sh is missing"
end

codemagic = codemagic_path.file? ? YAML.safe_load(codemagic_path.read, aliases: true) : {}
workflow = codemagic.dig("workflows", "device-preview")
unless workflow.is_a?(Hash)
  failures << "app: codemagic workflow device-preview is missing"
  workflow = {}
end

variables = workflow.dig("environment", "vars") || {}
groups = Array(workflow.dig("environment", "groups"))
preview_bundle_id = variables["APP_BUNDLE_ID"].to_s
preview_scheme = variables["XCODE_SCHEME"].to_s
xcode_project = variables["XCODE_PROJECT"].to_s

failures << "app: device-preview APP_BUNDLE_ID must end in .dev" unless preview_bundle_id.end_with?(".dev")
failures << "app: device-preview XCODE_SCHEME is missing" if preview_scheme.empty?
failures << "app: device-preview XCODE_PROJECT is missing" if xcode_project.empty?
failures << "app: indie_ops_ci group is missing" unless groups.include?("indie_ops_ci")
failures << "app: indie_ops_release group is missing" unless groups.include?("indie_ops_release")
if Array(workflow.dig("triggering", "events")).any?
  failures << "app: device-preview must be API/manual-only, not automatically triggered"
end

unless xcode_project.empty? || app_root.join(xcode_project).directory?
  failures << "app: configured XCODE_PROJECT does not exist (#{xcode_project})"
end

unless preview_scheme.empty?
  scheme_paths = app_root.glob("**/xcshareddata/xcschemes/#{preview_scheme}.xcscheme")
  if scheme_paths.empty?
    failures << "app: shared Preview scheme is missing (#{preview_scheme})"
  elsif scheme_paths.none? { |path| path.read.match?(/<ArchiveAction\b[^>]*buildConfiguration\s*=\s*"Preview"/m) }
    failures << "app: #{preview_scheme} Archive action does not use Preview"
  end
end

if script_path.file?
  _stdout, stderr, valid = run("bash", "-n", script_path.to_s)
  failures << "app: device-preview.sh syntax failed (#{stderr})" unless valid
  script = script_path.read
  {
    "reserved SHA check" => "DEVICE_PREVIEW_SOURCE_SHA",
    "ad hoc profiles" => "IOS_APP_ADHOC",
    "stale profile regeneration" => "--delete-stale-profiles",
    "source callback header" => "X-Source-Commit",
    "bundle callback header" => "X-Bundle-ID",
    "Indie Ops artifact endpoint" => "/v1/device-previews/",
  }.each do |label, marker|
    failures << "app: device-preview.sh lacks #{label}" unless script.include?(marker)
  end
end

failures << "app: codemagic.yaml is not tracked" if codemagic_path.file? && !tracked?(app_root, "codemagic.yaml")
failures << "app: .ci/device-preview.sh is not tracked" if script_path.file? && !tracked?(app_root, ".ci/device-preview.sh")

registry_path = indie_ops.join("config/apps.json")
registry = registry_path.file? ? JSON.parse(registry_path.read) : { "apps" => [] }
app = Array(registry["apps"]).find { |entry| entry["slug"] == slug }
unless app
  failures << "indie-ops: app registry entry is missing for #{slug}"
  app = {}
end

failures << "indie-ops: app is not enabled" unless app["enabled"] == true
failures << "indie-ops: repository is missing" unless app["repository"].to_s.match?(/\A[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\z/)
failures << "indie-ops: codemagicAppId is missing/invalid" unless app["codemagicAppId"].to_s.match?(/\A[a-f0-9]{24}\z/)
failures << "indie-ops: devicePreviewEnabled is not true" unless app["devicePreviewEnabled"] == true
if app["devicePreviewBundleId"].to_s != preview_bundle_id
  failures << "handoff: registry devicePreviewBundleId differs from Codemagic APP_BUNDLE_ID"
end
if app["bundleId"].to_s == preview_bundle_id
  failures << "handoff: preview bundle ID equals the production bundle ID"
end

route_pattern = /\(\s*['"]#{Regexp.escape(slug)}['"]\s*,\s*['"]releases['"]\s*,\s*['"][CG][A-Z0-9]+['"]/
route_found = indie_ops.glob("migrations/*.sql").any? { |path| path.read.match?(route_pattern) }
failures << "indie-ops: Slack releases route is missing for #{slug}" unless route_found

wrangler_path = indie_ops.join("wrangler.jsonc")
if wrangler_path.file?
  wrangler = JSON.parse(wrangler_path.read)
  production = wrangler.dig("env", "production") || {}
  failures << "indie-ops: production D1 binding is missing" if Array(production["d1_databases"]).empty?
  preview_binding = Array(production["r2_buckets"]).find { |entry| entry["binding"] == "DEVICE_PREVIEWS" }
  failures << "indie-ops: production DEVICE_PREVIEWS R2 binding is missing" unless preview_binding
else
  failures << "indie-ops: wrangler.jsonc is missing"
end

branch, = run("git", "-C", app_root.to_s, "branch", "--show-current")
head, = run("git", "-C", app_root.to_s, "rev-parse", "HEAD")
origin_main, _stderr, has_origin_main = run("git", "-C", app_root.to_s, "rev-parse", "origin/main")
if branch == "main" && has_origin_main && head != origin_main
  failures << "source: local main differs from origin/main; audit a clean remote-main worktree"
end

if failures.empty?
  puts "PASS: Slack preview handoff agrees for #{slug} (#{preview_bundle_id}, #{preview_scheme})."
  exit 0
end

puts "FAIL: #{failures.length} Slack preview handoff invariant(s) need attention."
failures.each { |failure| puts "- #{failure}" }
exit 1
