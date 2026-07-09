# CLAUDE.md — minit-godot

Minit Games SDK for the Godot engine (prototype, not yet a git repo; intended public repo once promoted: `Minit-Games/minit-godot`), letting Godot creators publish a game to the Minit platform. Full maintainer reference — the `window.minit` contract, shared engine-facade pattern, distribution/release philosophy, and per-engine gotchas — lives in the consolidated SDK-maintenance doc: https://github.com/Minit-Games/minit-root/blob/develop/docs/sdk-maintenance.md

## Release process (once a real repo)

Godot addons are consumed as **source** via the Asset Library — no build/publish
pipeline (unlike `minit-sdk`'s npm publish). A release is a tag + Asset Library
version bump:

1. From `develop`, bump `version` in `addons/minit/plugin.cfg` and `Minit.VERSION`
   in `minit.gd`, commit.
2. Fast-forward `develop` → `master` (`git merge --ff-only develop`).
3. Tag `v<x.y.z>` on `master`, push the tag, cut a GitHub Release.
4. Update the Asset Library entry to point at the new commit/tag.
5. Re-sync the `minit-web` vendored `minit.gd` fallback copy.
