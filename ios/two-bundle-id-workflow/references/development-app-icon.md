# Development app icon

Give every development identity an immediately recognizable icon. Derive it
from the production artwork so the app remains identifiable, while using a
consistent TestFlight-inspired blueprint treatment across products.

## Required visual language

- Use a full-bleed cobalt-to-azure blue background.
- Add a subtle, low-contrast technical grid.
- Render the production icon's defining silhouette and internal structure as
  crisp white/cyan wireframe linework.
- Preserve the production icon's composition and safe-area balance.
- Do not add `DEV`, environment text, a corner ribbon, the TestFlight propeller,
  or an unrelated generic developer symbol.
- Do not bake in rounded corners; iOS supplies the icon mask.

## Generation procedure

1. Locate and inspect the production 1024-pixel app-icon source.
2. Use that image as the edit/reference target with an image-generation tool.
3. Request a square, full-bleed blueprint transformation. Explicitly preserve
   the recognizable product geometry and replace readable text with structural
   linework if the model cannot reproduce it reliably.
4. Reject outputs that invent a different logo, lose the production
   silhouette, contain malformed text, or resemble a screenshot/mockup.
5. Export the accepted artwork as a 1024×1024 opaque PNG in
   `AppIcon-Dev.appiconset`; update `Contents.json` to reference it.
6. Inspect the icon at full size and at approximately 60 points. It must remain
   recognizable and clearly distinct from production.
7. Run `scripts/verify-identities.sh`; it validates the distinct catalog,
   universal iOS slot, PNG dimensions, opacity, and differing file hash.

Use this prompt as the stable baseline, substituting the app-specific identity:

```text
Create a professional TestFlight-inspired development variant of the attached
production app icon. Use a rich Apple-blue full-bleed background with a subtle
technical blueprint grid. Preserve the production icon's defining composition
and render its recognizable silhouette and internal structure as precise
luminous white/cyan wireframe linework. Keep important lines inside the icon
safe area. No rounded-corner mask, DEV label, environment text, red band,
TestFlight propeller, new logo, phone frame, mockup, watermark, or malformed
text. Output one opaque square app-icon artwork.
```

Image generation is nondeterministic; integration is not. Record the chosen
source and final asset paths in the app runbook, and accept the asset only after
the visual rubric and deterministic verifier both pass.
