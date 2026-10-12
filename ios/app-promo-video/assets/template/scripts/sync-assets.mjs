// Copies promo assets from the app repo into public/assets so Remotion can
// serve them. The app repo stays the source of truth; public/assets is
// gitignored. Paths in assets.json are relative to the app repo root (the
// folder that contains promo/).
import { copyFileSync, mkdirSync, readFileSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const promoRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = join(promoRoot, "..");
const outDir = join(promoRoot, "public", "assets");
const assets = JSON.parse(readFileSync(join(promoRoot, "assets.json"), "utf8"));

rmSync(outDir, { recursive: true, force: true });
mkdirSync(join(outDir, "wall"), { recursive: true });

const copy = (from, to) => copyFileSync(join(repoRoot, from), join(outDir, to));

copy(assets.icon, "icon.png");
for (const name of assets.wall) copy(join(assets.wallDir, name), join("wall", name));

console.log(`Synced ${1 + assets.wall.length} assets to public/assets`);
