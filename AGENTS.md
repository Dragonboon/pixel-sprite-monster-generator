# Pixel Sprite Monster Generator: agent entry point

Scope: entire repository. This is a self-contained **Godot 4.7** pixel-art
generation addon, not an entity/AI/collision or authored-animation framework.
CI pins **4.7.2-stable**. Install only `addons/pixel_sprite_monster_generator/`.

## Inspect only the relevant owner

Check the authorized branch, HEAD, user changes, addon version and
`.github/workflows/godot-ci.yml`. Read `README.md` and the applicable
[API section](docs/API.md); [Spanish API](docs/API_ES.md) must describe the same
public behavior. History documents are historical, not current API evidence.

| Task | Start under `addons/pixel_sprite_monster_generator/` | Proof |
| --- | --- | --- |
| Public generation/image/export API | `src/sprite_generator.gd` | `tests/regression.gd`; exported PNG |
| Silhouette, structure, anatomy | `src/components/creature_morphology.gd`, `creature_structural_variants.gd`, anatomy/integrity helpers | Same-seed family comparisons and topology assertions |
| Colors, shading, moods, horror | `src/components/` color/detail/mood/horror helpers | Palette bounds and real nearest-filtered image inspection |
| Presets, batches and metadata | `src/components/creature_generation_preset.gd`, `creature_batch_generator.gd` | Count/seed/manifest consistency and failure handling |
| Inspector/preview/lab | `src/sprite_generator_visualizer.gd`, repository `demo/test.tscn` | Interactive gallery, progress, reuse and export |

Component filenames without a directory prefix in the table are siblings in
`src/components/`. Read actual signatures/callers and targeted regressions before
editing. Do not infer APIs from prose or an earlier chat.

## Feature contract and invariants

Record acceptance, one state owner, existing reusable mechanism, minimal missing
behavior, public/save compatibility and focused proof before coding. Use native
Godot/existing helpers first. A shared abstraction needs two independent use cases;
do not add global managers or host-game policy to the generator.

- Same seed is reproducible with the same configuration, palette and algorithm.
  Preserve local RNG and intentional call ordering. Quality rerolls can change
  the actual result seed: persist `last_seed`, not only the requested seed.
- Keep classic defaults and opt-in anatomy, effects, horror and quality settings.
  Preserve exported fields, enum numbers, Resource schemas, IDs and Godot UIDs.
  Document version/migration and consumer impact for incompatible changes.
- Share no writable per-generation state across generator instances or palette/
  preset Resources. Distinguish base-image generation from presentation/shading:
  recoloring the gallery should not silently reroll its silhouettes.
- Preserve `draw_sprite()`, `get_image()`, `get_unfinished_image()`,
  `finish_image()` and `export_png()` contracts. Validate image availability,
  dimensions, palette bounds and writable destinations before effects.
- Current batch APIs distinguish 1–16 generation from encounters up to 128.
  Async batching yields between work chunks/creatures; individual CPU monster
  generation is not incremental or automatically threaded. Preserve progress,
  bounded attempts and valid parent lifetimes; do not promise interruption inside
  one monster or GPU acceleration.
- PNG and JSON metadata must identify the actual seed, settings, quality/anatomy
  and palette. Keep incomplete/low-quality outcomes explicit. Exact versus maximum
  palette sizes (1–64) must retain their documented distinction.
- Artwork stays pixel-space and nearest-filtered. Visual quality needs inspection
  across supported families/moods and small sizes, not only a nonempty Image.
  Do not replace user assets or remove Deep-Fold provenance/licenses.
- Addon-only use cannot depend on root demo, test or documentation resources.
  Keep editor enable/disable cleanup symmetric; preserve the host project.

## Progressive proof

Run from the repository root with the supported binary:

```sh
godot --version
python3 scripts/run_tests.py --godot godot
python3 scripts/run_tests.py --godot godot --render
```

The second run requires a display/real rendering backend; use the checked-in CI
workflow for its virtual-display setup. Inspect `scripts/run_tests.py`,
`tests/load_scripts.gd` and `tests/regression.gd` for the actual suite rather than
inventing another runner. Run the relevant layer first and broaden for shared
generation/export changes. Docs-only work needs path/link review.

For graphics/lab changes, run `demo/test.tscn`: same-seed comparisons, palette
changes without structural rerolls, progress and actual PNG/manifest outputs.
Test invalid input, repeated calls and parent teardown where affected. A clean
headless result does not prove rendered quality or responsiveness. Package changes
also require a fresh host with only the addon.

Trace real instances, callbacks and cleanup; symbol references are not wiring
proof. Compare before/after using the same seeds/settings and report exact checks,
unverified visual/device paths and performance conditions. Keep English/Spanish
README/API facts aligned when public behavior changes. Publish only within user
authorization, checking current HEAD without overwriting concurrent edits or
force-pushing. Never invent measured improvement or engine execution.
