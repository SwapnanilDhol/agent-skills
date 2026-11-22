#!/usr/bin/env ruby
# frozen_string_literal: true

# Verifies that the app-local runbook and the app repository agree on the
# Xcode Cloud setup for the two-bundle-ID workflow. The runbook is the single
# registry: workflow IDs, App Store Connect products, the development bundle ID
# and whether hosted Preview is enabled all live there.

require "open3"
require "optparse"
require "pathname"

options = { runbook: "docs/build/two-bundle-id.md" }
OptionParser.new do |parser|
  parser.banner = "Usage: verify-preview-handoff.sh APP_ROOT [--runbook RELATIVE_PATH]"
  parser.on("--runbook RELATIVE_PATH") { |value| options[:runbook] = value }
end.parse!

app_root = Pathname.new(ARGV.fetch(0) { abort "APP_ROOT is required" }).realpath
runbook_path = app_root.join(options[:runbook])
abort "runbook not found: #{runbook_path} (create it with bootstrap-app-runbook.sh)" unless runbook_path.file?
runbook = runbook_path.read

failures = []
uuid = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

def run(*command)
  stdout, stderr, status = Open3.capture3(*command)
  [stdout.strip, stderr.strip, status.success?]
end

# Reads "- Label: `value`" from the runbook. Labels are matched from the start of
# the bullet, so "Development bundle ID" does not match "Development Xcode Cloud".
def field(runbook, label)
  match = runbook.match(/^- #{Regexp.escape(label)}[^:\n]*:\s*`([^`]*)`/)
  match && match[1].strip
end

def filled?(value)
  value && !value.empty? && !value.start_with?("TODO") && !value.include?("{{")
end

production_bundle_id = field(runbook, "Production bundle ID")
development_bundle_id = field(runbook, "Development bundle ID")
production_product = field(runbook, "Production Xcode Cloud app/product ID")
pr_workflow = field(runbook, "PR verification workflow ID")
release_workflow = field(runbook, "Release workflow ID")
development_product = field(runbook, "Development Xcode Cloud app/product ID")
preview_workflow = field(runbook, "Preview workflow ID")
preview_scheme = field(runbook, "Preview scheme")

failures << "runbook: production bundle ID is not filled in" unless filled?(production_bundle_id)
if filled?(development_bundle_id)
  failures << "runbook: development bundle ID must end in .dev" unless development_bundle_id.end_with?(".dev")
  failures << "runbook: development bundle ID equals production" if development_bundle_id == production_bundle_id
else
  failures << "runbook: development bundle ID is not filled in"
end

failures << "runbook: production Xcode Cloud app/product ID is not filled in" unless filled?(production_product)
failures << "runbook: PR verification workflow ID is missing/invalid" unless pr_workflow.to_s.match?(uuid)
failures << "runbook: Release workflow ID is missing/invalid" unless release_workflow.to_s.match?(uuid)

preview_enabled = preview_workflow.to_s.match?(uuid)
if preview_enabled
  unless filled?(development_product) && development_product != "not approved"
    failures << "runbook: Preview workflow is set but the development App Store Connect product is not approved"
  end
  if filled?(preview_scheme)
    scheme_path = app_root.glob("**/xcshareddata/xcschemes/#{preview_scheme}.xcscheme").first
    if scheme_path.nil?
      failures << "app: shared scheme #{preview_scheme} is missing"
    elsif !scheme_path.read.match?(/<ArchiveAction\b[^>]*buildConfiguration\s*=\s*"Preview"/m)
      failures << "app: shared scheme #{preview_scheme} does not archive the Preview configuration"
    end
  else
    failures << "runbook: Preview scheme is not filled in"
  end
elsif preview_workflow != "disabled"
  failures << "runbook: Preview workflow ID must be a workflow UUID or `disabled`"
end

branch, = run("git", "-C", app_root.to_s, "branch", "--show-current")
head, = run("git", "-C", app_root.to_s, "rev-parse", "HEAD")
origin_main, _stderr, has_origin_main = run("git", "-C", app_root.to_s, "rev-parse", "origin/main")
if branch == "main" && has_origin_main && head != origin_main
  failures << "source: local main differs from origin/main; audit a clean remote-main worktree"
end

if failures.empty?
  status = preview_enabled ? "enabled (workflow #{preview_workflow})" : "disabled until its development Xcode Cloud product is approved"
  puts "PASS: runbook and repository agree on the Xcode Cloud setup; hosted Preview is #{status}."
  exit 0
end

puts "FAIL: #{failures.length} Xcode Cloud handoff invariant(s) need attention."
failures.each { |failure| puts "- #{failure}" }
exit 1
