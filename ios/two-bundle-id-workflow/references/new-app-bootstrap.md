# New-app bootstrap

Start with isolation before product features:

1. Choose the production reverse-DNS bundle ID and development `.dev` suffix.
2. Run `bootstrap-identity-files.sh` into an empty temporary output directory.
3. Add the generated configs, entitlements, and identity type to the project.
4. Add matching app/extension/widget App IDs and groups in Apple Developer.
5. Add Debug/Preview/Release schemes or map one shared scheme to the configs.
6. Generate the development app icon from the production icon using the shared
   blue-grid wireframe treatment in `development-app-icon.md`; then add distinct
   names, URL schemes and backend environment markers.
7. Record third-party service decisions in the identity manifest.
8. Configure Xcode Cloud for production verification and Release. Enable hosted
   Preview only after the development bundle has an explicitly approved App
   Store Connect app record/product; otherwise record Preview as disabled.
9. Run discovery, verification, builds, product inspection and side-by-side
   installation before merging the first feature.

The bootstrap script is a template generator, not an Xcode project mutator. A
human or agent must wire targets and capabilities deliberately.
