# Minit Games Godot SDK (prototype)

Lets [Godot](https://godotengine.org/) creators publish a game to the Minit
platform. A Godot game exported to **HTML5 (Web)** runs as a normal web page
inside the Minit host, so it talks to the host-injected `window.minit` runtime
**directly** — via Godot's built-in
[`JavaScriptBridge`](https://docs.godotengine.org/en/stable/classes/class_javascriptbridge.html)
singleton. No bundler, no npm dependency, no CDN fetch. This is the same design
decision the [Unity SDK](../minit-unity/), [Defold SDK](../minit-defold/), and
[PlayCanvas SDK](../minit-playcanvas/) made: the GDScript API surface maps 1:1 to
the `window.minit` contract, so host behaviour is identical across engines.

> **Prototype status.** This is a scaffold for review — a facade addon plus
> docs, no sample game. It is not yet published to the Godot Asset Library, not
> yet a git repo, and lives under the gitignored `external/` directory. The
> `window.minit` bridge snippets mirror the [Defold SDK](../minit-defold/), which
> was built and validated end-to-end against a mock host; the Godot bundle has
> **not** yet been exported/validated — see open questions.

> **Engine build.** Use the **standard (GDScript) Godot build**, not the .NET /
> C# build. The facade is plain GDScript and needs no .NET toolchain. (A C#
> facade is possible but would only serve the .NET-build minority and fragment
> distribution — GDScript-first matches every other Minit engine SDK.)

## Layout

| Path | What it is |
|---|---|
| `addons/minit/minit.gd` | **The SDK facade.** Registered as the `Minit` autoload; the only thing your game calls. |
| `addons/minit/plugin.gd` | Editor plugin — registers/removes the `Minit` autoload when you enable/disable the plugin. |
| `addons/minit/plugin.cfg` | Plugin manifest (name, version) — what the Godot Asset Library reads. |

## Install

1. Copy `addons/minit/` into your project's `addons/` folder (or install from the
   Godot Asset Library once published).
2. Enable it: **Project → Project Settings → Plugins → Minit Games SDK → Enable.**
   This registers the `Minit` autoload automatically.
3. Call the API from any script via the global `Minit`.

## API

The facade mirrors the Unity / Defold / PlayCanvas SDKs 1:1 (idiomatic GDScript
`snake_case`):

```gdscript
func _ready():
    # Signal the host the game is ready to be revealed (host hides it until this fires).
    Minit.loading_done()

    # Read a config value from URL query params. "userData" is a reserved key.
    var difficulty := Minit.get_config_value("difficulty", "normal")

    # Read this player's persisted userData slot (String | null).
    var saved = Minit.get_user_data()

func _on_game_over(final_score: int):
    # Submit the final result — call exactly once at game end. Higher score = better.
    Minit.report_result(final_score, {
        "flavor_text": "Cleared the last wave with 1 HP left",
        "user_data": "5",   # optional; omit to leave the stored slot unchanged. "" is a valid write.
    })
```

Outside the Minit host — the **editor**, a **desktop build**, or an HTML5 build
opened without the host injecting `window.minit` — every call degrades
gracefully: writes become a `print`, and reads fall back to URL query params
(`?difficulty=hard`, `?userData=5`), exactly like the Unity SDK falls back to
`Debug.Log`. Safe to call from anywhere.

### Contract details (identical to `@minit-games/sdk`)

- **`report_result`** wraps `user_data` into `{ value: "<string>" }` on the wire
  to match `UserDataPatchSchema` in `@minit/shared/zod`. Games pass a bare
  string; the wrapping is an SDK-internal detail.
- **`get_config_value`** returns `default` when the key is absent; the reserved
  key `"userData"` always returns `default` so it never bleeds into config.
  Declare the game's config keys in your build's `meta.json` `config` array —
  see [Declaring config values in meta.json](https://minit.studio/docs/declaring-config-values).
- **`get_user_data`** returns host-injected `window.minit.userData` when present,
  else the `?userData` URL param, else `null`. Returns `""` (empty string,
  distinct from `null`) if the stored value is the empty string.

## Building a Minit-ready HTML5 bundle

Install the **Web** export templates (Editor → Manage Export Templates), then add
a **Web** preset under **Project → Export** and click **Export Project**. Godot
emits `index.html`, `index.js`, `index.wasm`, `index.pck`, and asset sidecars.
Zip the *contents* of the export folder (so `index.html` is at the ZIP root) and
upload to the Minit creator console.

Two Godot-specific settings the Minit host requires:

- **Thread Support = OFF** (Web preset). A threaded Godot web build needs
  `SharedArrayBuffer`, which only works when the page is served with
  cross-origin-isolation headers (`COOP: same-origin` + `COEP: require-corp`).
  The Minit host iframe does not guarantee those, so ship the single-threaded
  build. This is the Godot analog of the Defold SDK pinning `--architectures
  wasm-web`. (Likewise leave **PWA** off — its service worker/manifest aren't
  wanted inside the host.)
- **Canvas fills the iframe.** Set the Web preset's **Canvas Resize Policy =
  Adaptive**, and Project Settings → Display → Window → Stretch to
  `mode = canvas_items`, `aspect = expand`, so the game fills the host's
  arbitrary-aspect frame instead of letterboxing. This is the Godot analog of
  Defold's `[html5] scale_mode = stretch` and Unity's viewport-filling canvas.

## Open questions for the real package

Mirrors the items the PlayCanvas and Defold prototypes flagged, plus Godot
specifics:

- **Export not yet validated.** Unlike the Defold prototype (built end-to-end
  with `bob`), no Godot Web bundle has been exported and run against a mock host
  yet. Do that before the real repo — confirm `JavaScriptBridge.eval` returns the
  expected primitives for each call and the bundle loads in the host iframe.
- **`JavaScriptBridge.eval` vs `get_interface`.** The facade uses eval-string +
  JSON (mirroring Defold's `html5.run`) because it's simple and robust for
  primitives. Godot also offers `JavaScriptBridge.get_interface("minit")` to hold
  a JS object reference and call methods directly — cleaner, but passing the
  nested `options` object needs `JavaScriptBridge.create_object`, which is
  fiddlier. Spike both before committing.
- **Minit-ready ZIP contract.** Confirm the host accepts Godot's Web export shape
  (`index.html` + `.js` + `.wasm` + `.pck` + asset sidecars) as-is, and whether a
  **Custom HTML Shell** (to strip Godot's boot splash/progress chrome and fill
  the viewport, like Defold's `minit.html`) is required. Compare against the Unity
  WebGL template's no-loader-chrome canvas requirements.
- **`SharedArrayBuffer` / cross-origin isolation.** Decide whether the host ever
  serves games with COOP/COEP headers. If yes, threaded (faster) builds become an
  option; if no, the single-threaded build above is required.
- **Distribution.** Primary channel is the **Godot Asset Library** (editor-native
  one-click install — requires the repo be public). Keep a raw `minit.gd` copy
  vendored in `minit-web` behind a `tool-godot` KB article as the no-editor
  fallback, re-synced to this repo. `Minit.VERSION` lets creators spot a stale
  pasted copy.
- **A "Build for Minit" helper.** The Unity SDK ships a one-click editor menu that
  bundles + repackages. Consider a Godot editor script or a headless-export
  wrapper (`godot --headless --export-release "Web" …`) that produces the
  upload-ready ZIP.
