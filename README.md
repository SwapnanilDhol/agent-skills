# cursor-skills

Personal [Cursor Agent Skills](https://cursor.com/docs/skills) library for Swapnanil Dhol.

Skills are grouped by platform so the same repo can hold iOS, Android, and web
workflows. Install them once into `~/.cursor/skills/` and they are available in
every Cursor project.

```text
cursor-skills/
├── ios/                 # App Store Connect, Xcode, release workflows
│   └── asc-morning-brief/
├── android/             # reserved
├── web/                 # reserved
├── scripts/install.sh
└── README.md
```

## Skills

| Skill | Category | Invoke | Description |
|---|---|---|---|
| [`asc-morning-brief`](ios/asc-morning-brief/) | iOS | `/asc-morning-brief` | App Store Connect morning executive brief (acquisition, revenue, crashes, ratings, release health) |

## Install

### Option A — Install script (recommended)

Symlinks every skill folder into your user skills directory so Cursor discovers
them globally:

```bash
git clone git@github.com:SwapnanilDhol/cursor-skills.git ~/Desktop/iOS-Projects/cursor-skills
cd ~/Desktop/iOS-Projects/cursor-skills
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

### Option B — Cursor Remote Rule (GitHub)

1. Open **Customize** in the Cursor sidebar
2. Go to **Rules** → **Add Rule**
3. Choose **Remote Rule (Github)**
4. Paste: `https://github.com/SwapnanilDhol/cursor-skills`

Use this when you want Cursor to pull skills from GitHub without a local clone.
For day-to-day edits, Option A (local clone + symlink) is easier.

### Option C — Manual copy

```bash
mkdir -p ~/.cursor/skills
cp -R ios/asc-morning-brief ~/.cursor/skills/
```

Prefer the install script so updates are a `git pull` away instead of re-copying.

## Update

```bash
cd ~/Desktop/iOS-Projects/cursor-skills   # or your clone path
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

In Agent chat:

```text
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
   disable-model-invocation: true
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
