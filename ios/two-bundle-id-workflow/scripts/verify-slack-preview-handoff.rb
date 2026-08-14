#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "optparse"
require "pathname"

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
uuid = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

def run(*command)
  stdout, stderr, status = Open3.capture3(*command)
  [stdout.strip, stderr.strip, status.success?]
end

registry_path = indie_ops.join("config/apps.json")
registry = registry_path.file? ? JSON.parse(registry_path.read) : { "apps" => [] }
app = Array(registry["apps"]).find { |entry| entry["slug"] == slug }
unless app
  failures << "indie-ops: app registry entry is missing for #{slug}"
  app = {}
end

preview_enabled = app["devicePreviewEnabled"] == true
preview_bundle_id = app["devicePreviewBundleId"].to_s

failures << "indie-ops: app is not enabled" unless app["enabled"] == true
failures << "indie-ops: repository is missing" unless app["repository"].to_s.match?(/\A[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\z/)
failures << "indie-ops: xcodeCloudTeamId is missing/invalid" unless app["xcodeCloudTeamId"].to_s.match?(uuid)
failures << "indie-ops: xcodeCloudWorkflowId is missing/invalid" unless app["xcodeCloudWorkflowId"].to_s.match?(uuid)
failures << "indie-ops: xcodeCloudReleaseWorkflowId is missing/invalid" unless app["xcodeCloudReleaseWorkflowId"].to_s.match?(uuid)
failures << "indie-ops: legacy codemagicAppId must be removed" if app.key?("codemagicAppId")

if preview_enabled
  failures << "indie-ops: devicePreviewBundleId must end in .dev" unless preview_bundle_id.end_with?(".dev")
  failures << "indie-ops: Preview bundle ID equals production" if preview_bundle_id == app["bundleId"].to_s
  failures << "indie-ops: xcodeCloudPreviewWorkflowId is missing/invalid" unless app["xcodeCloudPreviewWorkflowId"].to_s.match?(uuid)

  preview_scheme = app_root.glob("**/xcshareddata/xcschemes/*.xcscheme").find do |path|
    path.read.match?(/<ArchiveAction\b[^>]*buildConfiguration\s*=\s*"Preview"/m)
  end
  failures << "app: no shared scheme archives the Preview configuration" unless preview_scheme
else
  failures << "indie-ops: disabled Preview still has devicePreviewBundleId" if app.key?("devicePreviewBundleId")
  failures << "indie-ops: disabled Preview still has xcodeCloudPreviewWorkflowId" if app.key?("xcodeCloudPreviewWorkflowId")
end

route_pattern = /\(\s*['"]#{Regexp.escape(slug)}['"]\s*,\s*['"]releases['"]\s*,\s*['"][CG][A-Z0-9]+['"]/
route_found = indie_ops.glob("migrations/*.sql").any? { |path| path.read.match?(route_pattern) }
failures << "indie-ops: Slack releases route is missing for #{slug}" unless route_found

wrangler_path = indie_ops.join("wrangler.jsonc")
if wrangler_path.file?
  wrangler = JSON.parse(wrangler_path.read)
  production = wrangler.dig("env", "production") || {}
  failures << "indie-ops: production D1 binding is missing" if Array(production["d1_databases"]).empty?
  if preview_enabled
    preview_binding = Array(production["r2_buckets"]).find { |entry| entry["binding"] == "DEVICE_PREVIEWS" }
    failures << "indie-ops: production DEVICE_PREVIEWS R2 binding is missing" unless preview_binding
  end
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
  status = preview_enabled ? "enabled" : "disabled until its development Xcode Cloud product is approved"
  puts "PASS: Xcode Cloud handoff agrees for #{slug}; hosted Preview is #{status}."
  exit 0
end

puts "FAIL: #{failures.length} Xcode Cloud handoff invariant(s) need attention."
failures.each { |failure| puts "- #{failure}" }
exit 1
