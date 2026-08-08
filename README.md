# agent-skills

Personal Agent Skills library for Swapnanil Dhol. Skills follow the portable
`SKILL.md` convention and can be installed in Codex, Cursor, and compatible agents.

Skills are grouped by platform so the same repo can hold iOS, Android, and web
workflows.

```text
agent-skills/
├── ios/                 # App Store Connect, Xcode, release workflows
│   ├── asc-morning-brief/
│   ├── generate-app-store-screenshots/
│   ├── premium-onboarding/
│   └── release-ios-app-locally/
├── android/             # reserved
├── web/                 # reserved
├── scripts/install.sh
└── README.md
```

## Skills

| Skill | Category | Invoke | Description |
|---|---|---|---|
| [`asc-morning-brief`](ios/asc-morning-brief/) | iOS | `/asc-morning-brief` | App Store Connect morning executive brief (acquisition, revenue, crashes, ratings, release health) |
| [`generate-app-store-screenshots`](ios/generate-app-store-screenshots/) | iOS | `/generate-app-store-screenshots` | Deterministic Simulator capture, widget staging, framing, review, validation, and App Store Connect upload |
| [`premium-onboarding`](ios/premium-onboarding/) | iOS | `/premium-onboarding` | Product narrative, adaptive iPhone/iPad layout, state architecture, motion, permissions, paywalls, accessibility, analytics, and QA for polished onboarding |
| [`release-ios-app-locally`](ios/release-ios-app-locally/) | iOS | `/release-ios-app-locally` | Reproducible local App Store archive, upload, validation, tagging, and cleanup workflow |

## Install

### Codex

Install an individual skill into `~/.codex/skills` with Codex's bundled skill
installer. For example:

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo SwapnanilDhol/agent-skills \
  --path ios/release-ios-app-locally
```

The skill is available to Codex on the next turn.

### Cursor option A — Install script

Symlinks every skill folder into your user skills directory so Cursor discovers
them globally:

```bash
git clone git@github.com:SwapnanilDhol/agent-skills.git ~/Desktop/iOS-Projects/agent-skills
cd ~/Desktop/iOS-Projects/agent-skills
./scripts/install.sh
```

What it does:

1. Creates `~/.cursor/skills/` if needed
2. For each `*/<skill-name>/SKILL.md`, symlinks `~/.cursor/skills/<skill-name>` → this repo
3. Skips or replaces existing links after confirmation (`--force` to replace)

Verify:

```bash
ls -la ~/.cursor/skills
./scripts/install.sh --list
```

Restart Cursor (or reopen the window) if a newly installed skill does not appear
under **Customize → Skills**.

### Cursor option B — Remote Rule (GitHub)

1. Open **Customize** in the Cursor sidebar
2. Go to **Rules** → **Add Rule**
3. Choose **Remote Rule (Github)**
4. Paste: `https://github.com/SwapnanilDhol/agent-skills`

Use this when you want Cursor to pull skills from GitHub without a local clone.
For day-to-day edits, Option A (local clone + symlink) is easier.

### Cursor option C — Manual copy

```bash
mkdir -p ~/.cursor/skills
cp -R ios/asc-morning-brief ~/.cursor/skills/
```

Prefer the install script so updates are a `git pull` away instead of re-copying.

## Update

```bash
cd ~/Desktop/iOS-Projects/agent-skills   # or your clone path
git pull
./scripts/install.sh --force             # refresh symlinks if skill folders were renamed
```

## Uninstall

```bash
./scripts/uninstall.sh                   # remove symlinks that point at this repo
# or remove one skill:
rm ~/.cursor/skills/asc-morning-brief
```

## Use a skill

In Codex, invoke a skill with `$<skill-name>`. In Cursor Agent chat, use
`/<skill-name>`:

```text
$release-ios-app-locally
/asc-morning-brief
```

Or ask naturally once the skill is installed, e.g. “run the ASC morning brief
for the latest numbers.”

`asc-morning-brief` is marked `disable-model-invocation: true`, so it only loads
when you invoke it (or explicitly ask the agent to use that skill).

### Per-app config (ASC morning brief)

In each iOS app repo, add `.asc/morning-brief.json`:

```json
{
  "appName": "MyApp",
  "appId": "1234567890",
  "platform": "IOS",
  "bundleId": "com.example.myapp",
  "collector": null,
  "artifactGlob": ".tmp/asc-morning/*"
}
```

See [`ios/asc-morning-brief/app-config.example.json`](ios/asc-morning-brief/app-config.example.json).
Neon/ColorPicker has built-in defaults if the file is missing.

## Add a new skill

1. Pick a category folder (`ios/`, `android/`, `web/`) or create one.
2. Create `category/my-skill-name/SKILL.md` with required frontmatter:

   ```markdown
   ---
   name: my-skill-name
   description: What it does and when to use it.
   ---

   # My Skill Name

   Instructions for the agent…
   ```

3. Keep the folder name identical to the `name` field (lowercase, hyphens).
4. Commit, push, then run `./scripts/install.sh` on each machine.

Optional supporting files next to `SKILL.md`:

- `scripts/` — helpers the agent can run
- `references/` — progressive-disclosure docs
- `assets/` — templates / examples

## Requirements for `asc-morning-brief`

- `asc` CLI authenticated (`asc doctor`)
- Cached App Store Connect web session when you want dashboard analytics:
  `asc web auth login --apple-id "you@example.com"`
- Optional project collector (`make morning-brief` in Neon)

## License

Private personal tooling. All rights reserved unless noted otherwise in a skill folder.
