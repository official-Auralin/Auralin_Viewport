# Releasing Auralin_Viewport (CurseForge / WoW Packager)

This repo uses WoW packager preprocessing directives (for example `@alpha@`, `@non-alpha@`) and tag-based build channels.

## Channel Mapping

CurseForge/packager build channels are determined by the git tag name:

- `alpha`: tag contains `alpha` (example: `v2.0.1-alpha.1`)
- `beta`: tag contains `beta` (example: `v2.0.1-beta.1`)
- `release`: tag does not contain `alpha` or `beta` (example: `v2.0.1`)

Notes:

- Use annotated tags.
- Do not move or reuse pushed tags. Increment the suffix instead (`alpha.2`, `beta.2`, etc.).

## Recommended Branch Usage

- `alpha` branch: active development and in-game testing builds
- `main` branch: stable release branch

## Typical Flow

1. Commit work on `alpha`.
2. Run local Lua syntax checks:
   - `powershell -ExecutionPolicy Bypass -File .\tools\check-lua.ps1`
3. Create an alpha test tag:
   - `git tag -a vX.Y.Z-alpha.N -m "vX.Y.Z-alpha.N"`
4. Push branch + tag:
   - `git push origin alpha --follow-tags`
5. After testing, create beta tag on the candidate commit:
   - `git tag -a vX.Y.Z-beta.N -m "vX.Y.Z-beta.N"`
   - `git push origin alpha --follow-tags`
6. Promote to release on `main` and tag:
   - `git tag -a vX.Y.Z -m "vX.Y.Z"`
   - `git push origin main --follow-tags`

## Packaging Notes

- `.pkgmeta` is used for packager metadata (package name, license output, etc.).
- `Auralin_Viewport.toc` uses `## Version: @project-version@` so packaged builds inherit the git tag version automatically.
- `@alpha@` and `@non-alpha@` blocks are processed by the packager; keep both paths valid when changing shared files.

## GitHub Workflow Configuration

The workflow in `.github/workflows/release.yml` runs on pushed tags (`v*`) and uses `BigWigsMods/packager@v2`.

Required repository configuration:

- GitHub secret: `CF_API_KEY`
- GitHub variable: `CF_PROJECT_ID` (CurseForge numeric project id)

Optional repository configuration:

- GitHub secret: `WOWI_API_TOKEN`
- GitHub secret: `WAGO_API_TOKEN`

## CurseForge Setting Caveat

If the CurseForge project has **Package All Commits** enabled, untagged pushes can still produce alpha builds. Disable that setting if you want tag-only packaging.
