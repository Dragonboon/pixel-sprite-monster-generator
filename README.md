<p align="center"><img src="icon.svg" width="112" alt="Pixel sprite monster generator"></p>
<h1 align="center">Pixel Sprite Monster Generator</h1>
<p align="center">Generate varied pixel monsters in Godot 4.7, then reuse them as PNG sprites.</p>

**English** · [Español](README_ES.md) · [Validation](https://github.com/sempitern0/pixel-sprite-monster-generator/actions)

Build monster silhouettes, colors and optional animated cell groups without drawing
each creature by hand. This is a Godot port of
[Deep-Fold's pixel sprite generator](https://deep-fold.itch.io/pixel-sprite-generator).
Generation creates artwork, not gameplay logic, collision shapes or authored animations.

## Start in minutes

1. Use **Godot 4.7.x**; automated checks pin **4.7.2 stable**.
2. Copy `addons/pixel_sprite_monster_generator/` into your project's `addons/` directory, preserving the folder name.
3. Enable the plugin in **Project → Project Settings → Plugins**.
4. Add a `PixelSpriteMonsterGenerator` Node2D to a scene and run it.
5. Adjust the size, palette, symmetry and cellular automata settings, then call `draw_sprite()` to regenerate.

Open `demo/test.tscn`, or press **F5**, for the interactive 1–128 creature laboratory, with multiple archetypes, seed control and PNG + JSON export.
Monster preview is runtime-only; the editor does not generate a preview automatically.

## Reproducible variations

```gdscript
@onready var monster: PixelSpriteMonsterGenerator = $PixelSpriteMonsterGenerator

func _ready() -> void:
    monster.randomize_seed = false
    monster.manual_seed = 42
    monster.cell_animation = false
    monster.draw_sprite()
    var error := monster.export_png("user://monster_42.png")
    if error != OK:
        push_warning(error_string(error))
```

For random generation, leave **Randomize Seed** enabled and save `last_seed` with
all generation settings. Disable randomization and assign that seed to replay the
result. Regeneration preserves game-owned child nodes, uses local randomness and
does not modify noise resources shared with other instances.

| Setting | Effect |
| --- | --- |
| Sprite Size | Logical pixel grid; each dimension is normalized to 4–256 |
| Sprite Draw Size | Display scale; does not change the exported pixel grid |
| Pixel Perfect | Draws each cell as one pixel, ignoring display scaling |
| Symmetry | 100 gives a mirrored silhouette; lower values introduce variation |
| Organic Shape Strength | Optional irregular elliptical trimming (0 preserves the original result) |
| Keep Largest Body | Optional removal of detached fragments after cellular smoothing |
| Creature Archetype | Original, Biped, Insectoid, Slime or Winged silhouette rules |
| Anatomy Strength | Controls the extension size; zero disables anatomy generation |
| Facial Eyes | Creates a pair of enclosed eye pockets when the body has room |
| Steps / Birth Limit / Death Limit | Cellular automata smoothing; steps are limited to 0–20 |
| Number of Colors | Generated palette size, normalized to 1–64 |
| Custom Color Palette | `PixelSpriteMonsterGeneratorColorPalette`; nonempty palettes override generated body/eye palettes |
| Eye Color Saturation / Value | Independent eye palette controls in HSV mode |
| Main / Secondary Noise | Body/eye color patterns; copied internally, with defaults if omitted |
| Cell Animation | Optional movement of groups; disable for a static sprite |

Different seeds are not guaranteed to produce equally readable monsters. Generate a
small selection and keep the silhouettes that fit your game. Larger grids cost more;
benchmark generation on your target device rather than generating many creatures
in a single gameplay frame.

## Export and reuse

`get_image()` returns a transparent RGBA image in a **neutral, unanimated pose**.
Its size is `Sprite Size + 2` on each axis: one pixel of padding accommodates outlines.
`export_png(path)` saves that same image and returns a Godot `Error`. The parent
directory must exist. `user://` is appropriate for exported games.

```gdscript
var image := monster.get_image()
if image != null:
    $Sprite2D.texture = ImageTexture.create_from_image(image)
```

CPU image export also works under `--headless`. It does not capture the screen,
other nodes, display scaling, group animation or a sprite sheet. Use nearest-neighbor
texture filtering when importing PNGs for pixel-art games. `clear()` removes only
the generated drawing; after clearing, `get_image()` returns `null` until regeneration.

## Compatibility and validation

Version **1.5.0** targets Godot 4.7. Install the addon in `addons/pixel_sprite_monster_generator/`; its entry files are `plugin.cfg` and `plugin.gd`. When updating an existing installation, replace the previous addon folder, update any resource references in your own scenes, and enable the plugin again. Seed reproducibility requires the same generator implementation and settings.

```sh
python3 scripts/run_tests.py --godot /path/to/godot
# Optional real-renderer pass, with a desktop display:
python3 scripts/run_tests.py --godot /path/to/godot --render
```

Checks cover optional shape cleanup/replay, script loading, repeated regeneration, authored child preservation,
random-stream isolation, fixed/random seed replay, scale, odd-sized symmetry,
one-color palettes, independent eye colors, invalid sizes and PNG round trips.
Linux automated tests do not certify Windows, macOS or mobile hardware behavior.

## Examples and credits

![Animated monster examples](images/animated_showcase.gif)

Original visual algorithms by [Deep-Fold](https://github.com/Deep-Fold).
Godot port maintained by [sempitern0](https://github.com/sempitern0).
See [LICENSE](LICENSE) and preserve applicable attribution when redistributing.

[Report a problem](https://github.com/sempitern0/pixel-sprite-monster-generator/issues)
with your seed, settings, Godot version and platform.

## Anatomy families

The new **Creature Anatomy** inspector group provides four explicit families in addition to **Original**. **Biped** introduces separate legs and arms, **Insectoid** adds paired antennae and limbs, **Slime** uses a rounded crown and wider base, and **Winged** extends paired wings from the torso. These are procedural silhouette guides rather than rigged characters, and individual seeds can still need curation.

```gdscript
monster.randomize_seed = false
monster.manual_seed = 1042
monster.creature_archetype = CreatureMorphology.Archetype.INSECTOID
monster.anatomy_strength = 0.9
monster.organic_shape_strength = 0.25
monster.keep_largest_body = true
monster.facial_eyes = true
monster.cell_animation = false
monster.draw_sprite()
var result := monster.export_png("user://insectoid.png")
```

The morphology pass operates after cellular smoothing and before coloring. It never modifies global randomness and preserves mirrored additions; setting **Original** bypasses it entirely. Eye pockets are opportunistic and are not guaranteed for fragmented or narrow silhouettes. Keep original seeds/settings for legacy output: generated artwork changes only when the new parameters are enabled.

### Demo workflow

Run **F5** to inspect Original, Biped, Insectoid, Slime, Winged and an asymmetrical Biped side by side. Use **Base seed** to replay, **New seed** to explore and **Export six PNGs** to save neutral poses to `user://`. This gallery is outside the addon folder; installing the plugin does not copy demo controls into your game.

### Procedural quality limits

This creates fast, editable **sprite silhouettes**, not handcrafted anatomy, skeletal animation or semantic meshes. Small grids may clip antennae and wings; increasing sprite size and filtering candidate seeds improves readability. The generated body still uses the existing noise-based palette and optional cell-group animation.

## Quality selection and artistic finish (1.4)

Enable **Quality Enabled** in the Inspector for a bounded deterministic search over procedural candidates. **Quality Min Score** (0–100) sets the desired heuristic threshold; **Quality Max Attempts** (1–32) limits work per call. The generator keeps the best candidate found and reports `last_quality_score`, `last_quality_attempts`, `quality_accepted`, and `last_seed`. A score is a geometric heuristic, not an objective assessment of artistic quality. If the threshold cannot be met, the best candidate is retained and `quality_accepted` is false. A fixed manual seed always recreates the same search, and the game-wide random generator is not modified. Quality selection defaults to off for backwards compatibility. Save the original `manual_seed`, plus all settings, to replay an entire search; `last_seed` identifies the selected candidate, rather than the search's starting point.

**Silhouette Mood** changes contour direction independently of the anatomy family: **Normal** preserves the original map, **Cozy** smooths isolated protrusions, **Horror** introduces thin jagged growth, and **Epic** emphasizes paired crown and shoulder extensions.

The **Pixel Art Finish** section supports Classic, Handheld, JRPG, Dungeon, Cozy and Arcade colors, plus CPU-based directional pixel shading, checker dithering, optional seeded glitch and **Three Quarter** experimental shearing. All effects operate at native pixel resolution without interpolation. They do not generate genuine 3D volume or true isometric anatomy. The preview UI uses nearest-neighbor filtering, and PNG export preserves the native grid. Animated cell groups still draw with the original live renderer; use `get_image()` or a `Sprite2D` made from `get_image()` to show the styled result in-game.

```gdscript
monster.randomize_seed = false
monster.manual_seed = 4433
monster.quality_enabled = true
monster.quality_min_score = 72.0
monster.quality_max_attempts = 12
monster.silhouette_mood = CreatureMood.Mood.COZY
monster.creature_archetype = CreatureMorphology.Archetype.SLIME
monster.visual_style = CreaturePixelEffects.Style.JRPG
monster.shading_strength = 0.7
monster.dithering_strength = 0.2
monster.cell_animation = false
monster.draw_sprite()
var image := monster.get_image()
var texture := ImageTexture.create_from_image(image)
$Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
$Sprite2D.texture = texture
```

The F5 laboratory now exposes mood, style, quality threshold, shading and a front/3/4 comparison. Each gallery card reports the selected seed and measured score. **Export six PNGs** saves precisely the displayed pixel images under `user://`. Quality filtering is intended for batch authoring; keep its attempt budget low for runtime generation on mobile devices.

## Anatomical proportion profiles

Assign a **CreatureAnatomyProfile** resource to `anatomy_profile` to opt into connected procedural body construction. The inspector exposes bounded minimum/maximum ratios for body width, height, head and appendage length. The ranges are sampled with a private seeded RNG, and silhouette mood biases the sampled proportions: Cozy favors wider, rounder forms with shorter limbs; Horror favors a narrow body and longer limbs; Epic increases mass and reach.

```gdscript
var proportions := CreatureAnatomyProfile.new()
proportions.body_width_min = 0.38
proportions.body_width_max = 0.52
proportions.appendage_min = 0.18
proportions.appendage_max = 0.30
monster.anatomy_profile = proportions
monster.creature_archetype = CreatureMorphology.Archetype.BIPED
monster.silhouette_mood = CreatureMood.Mood.COZY
monster.randomize_seed = false
monster.manual_seed = 4433
monster.draw_sprite()
print(monster.last_anatomy) # The sampled ratios of the latest candidate
```

A null profile retains the pre-1.5 anatomy path. This is an initial connected-shape system, not pose estimation or anatomical validation; limbs may still need visual curation. Profile-enabled output is not pixel-identical to the pre-profile generator. The new changes also create a much greater luminance separation between Cozy (warm mid/high values) and Dungeon (cool, dark shadow masses).

## Additional views and anatomy-aware selection

The laboratory has Front, left/right 3/4, left/right Profile, Back (mirrored), and experimental Isometric 2D views. These are deterministic **image-space projections**, not distinct true 3D viewpoints or regenerated body anatomy. Existing front/3/4 scene values are retained. Use **Compare with Front** in the F5 gallery to view the selected projection beside its front-facing baseline at the same seed, mood, palette and silhouette. PNG export saves the selected view, not the comparison pair.

With an optional `anatomy_profile`, quality selection now blends basic shape metrics (65%) with a heuristic anatomy score (35%). `last_anatomy_metrics` contains `score`, `body_coverage`, `appendage_balance`, and `base_support`. Metrics use the bounded sampled proportions and simple pixel counts, not true limb recognition. If no profile is supplied, the original quality metric remains unchanged. The gallery exposes an **Anatomy profile** checkbox and displays Q and A values to help compare candidates. A/B view comparison never rerolls the candidate seed.

## Reusable presets and bounded batches

Create a `CreatureGenerationPreset` resource with Godot's Inspector (or use the examples in `demo/presets/`). The preset stores geometry, anatomy, mood, palette, finish, quality and selection options, independently from any random seed.

```gdscript
var preset: CreatureGenerationPreset = load("res://demo/presets/cozy_slime.tres")
var results: Array[Dictionary] = CreatureBatchGenerator.generate(preset, self, 6, 4200)
var error := CreatureBatchGenerator.export_pngs(results, "user://creatures", "cozy")
```

`generate()` uses a disposable generator and leaves the existing scene unchanged; it requires a parent already in the scene tree and produces **up to 16 sprites per call**. Each result contains an Image, requested and selected seeds, quality score/acceptance/attempts and sampled anatomical data. Fixed seeds, settings and generator version reproduce the same images. The batch exporter creates its destination folder, writes native-resolution PNGs and a JSON manifest. Output paths must begin with `user://` or `res://`; existing matching filenames are overwritten. Store the preset resource alongside the manifest if exact future replay matters. The manifest does not serialize resource references or the full generator version.

The optional projections remain experimental. Batch generation is synchronous and should run outside time-sensitive gameplay frames, particularly with high resolution or many quality attempts.

## RPG encounters: generate exactly 1–N creatures (1.5)

For a **single creature**, use `CreatureBatchGenerator.generate_encounter(preset, parent, 1, seed)`. For multiple enemies, set `count` between **1 and 128**. Unlike the legacy small `generate()` helper (limited to 16, and now rejecting larger requests), this API never truncates your count: its returned dictionary includes `error`, `requested_count`, `generated_count`, `items`, and `elapsed_ms`. Check `error == OK` before using the results. All creatures have their own repeatable requested and selected seeds.

```gdscript
var preset: CreatureGenerationPreset = preload("res://demo/presets/dungeon_insectoid.tres")
var encounter: Dictionary = await CreatureBatchGenerator.generate_encounter_async(
    preset, self, 8, 4200, 7919, 4
)
if encounter["error"] == OK and encounter["generated_count"] == 8:
    for creature in encounter["items"]:
        var sprite := Sprite2D.new()
        sprite.texture = ImageTexture.create_from_image(creature["image"])
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        add_child(sprite)
```

`generate_encounter_async()` yields between chunks (1–16 items per chunk), making it preferable for RPG encounters; processing *inside* a chunk is still synchronous. The synchronous `generate_encounter()` can be useful for tools. Validate count and use smaller chunk sizes on low-power hardware. Generation does not supply AI, stats or enemy placement. `elapsed_ms` measures generation wall-clock time and is not an authoritative cross-device benchmark.

The F5 laboratory now offers a **1–128 creature counter**, mixed or selected anatomy families (adding Quadruped, Golem, Spirit), sample .tres presets, favorite toggles, favorite-only view, quality/anatomy scores, elapsed time and PNG+JSON export. A successful export reports the number of images and full destination directory; invalid or empty selections report a visible error. Favorites are session-only, not saved between runs. Large counts can still take time and memory; avoid running 128 expensive generations in a critical gameplay frame. The older projection views remain experimental.

## Performance and silhouette diversity diagnostics

The demo now generates galleries incrementally in groups of four, exposes a progress bar, and abandons an outdated gallery request when new settings trigger a replacement. Press **Benchmark 1 / 8 / 32 / 128** to measure generation wall time, approximate raw RGBA image bytes, and the number of visually distinct silhouette signatures. The benchmark uses the current family/preset and deterministic seeds.

`CreatureVariety.summarize(items)` annotates generated items with `novelty` and `near_duplicate` and returns counts of exact images, approximately unique **silhouettes**, near-duplicates, and average novelty. Its 12×12 normalized alpha-mask metric deliberately ignores color: recolors of the same shape count as the same silhouette. This is a diagnostic, not an artistic quality guarantee; the threshold can miss fine features. It **does not** reroll or reject sprites, so requested encounter counts remain exact.

The benchmark estimates only retained image RGBA bytes, not Godot nodes, textures, the garbage collector or total process RSS. Wall-clock results depend on hardware and quality attempts, so compare on the target machine rather than assuming stable frame times. For critical gameplay use the chunked encounter API and moderate quality settings.

## Quality and pipeline consolidation

An encounter now reuses a single temporary generator rather than allocating one per 16-creature chunk. The normal in-scene generator still builds its image on `_ready()`; the private batch worker defers its first generation so the requested first seed is used exactly once. Synchronous and chunked asynchronous encounters continue to produce matching images with a fixed preset and seed. Unused anatomy metadata is cleared before generation, including when switching to the Original archetype.

When quality filtering is enabled, geometric scoring now additionally penalizes silhouettes with multiple disconnected components or extremely sparse occupancy. These heuristics help reject accidental artifacts but cannot guarantee an attractive creature. **Note:** this recalibration may select a different candidate for existing seeds *when quality selection is enabled*; the original unfiltered mode still uses the historical path. Save your preset and version alongside exported seeds.

## Focused morphology calibration (opt-in families)

**Insectoid, Quadruped, Golem, and Spirit** now have connected anatomy-first silhouettes when **Refined Anatomy** is enabled (the default for newly configured creatures). Instead of decorating an unrestricted noisy mass, these families first build recognizable linked volumes: insect thorax/abdomen with six articulated legs, quadruped body/neck/head and four legs, heavy golem shoulders/feet, or a floating spirit with trailing wisps. Existing cellular noise still perturbs the outlines, so sprites remain seed-based rather than hand-authored clones. The Original, Biped, Slime and Winged paths are unaffected by this refiner.

The **Compare legacy anatomy** gallery checkbox displays up to twelve selected sprites with the historical anatomy underneath for the same selected seed. Comparison is opt-in because it doubles image generation costs. **Refined Anatomy = false** restores the previous silhouettes for all four refined families; with the quality gate enabled the seed selected by the search may still change because the new shape has a different score. Keep the full preset/settings with saved seed data for pixel-exact replay. This iteration makes no claims about genuine 3D anatomy or artist-approved quality; check the visible contours in Godot before exporting final assets.

## Seed-derived internal traits

Insectoid, Quadruped, Golem and Spirit now have a lightweight second stage of **internal pixel detailing** that runs after palette fill and before pixel-art effects. Each selected seed derives an independent `CreatureTraitProfile` dictionary (pattern, eye layout, ornament, accent, mark count and placement); this changes visible markings without rerolling the silhouette or changing game-wide RNG. Insectoids gain carapace segmentation, plates and eyes; quadrupeds have flank patterns and dorsal details; golems acquire cracks, seams and runes; spirits have luminous masks, inner cores and drifting markings.

The optional settings `internal_details_enabled` (default: true) and `internal_detail_strength` (0–1) control the finish; `false` restores the immediately preceding silhouette-only result for the four refined families. Details are clipped to opaque **interior** cells, preserving both native pixel resolution and alpha. `last_traits` and batch result `traits` metadata record the generated identity, and JSON manifests include it for reproducibility. The demo exposes a details checkbox/strength slider and reports the selected pattern/accent on each card. Other archetypes and legacy anatomy paths are unaffected.

```gdscript
monster.internal_details_enabled = true
monster.internal_detail_strength = 0.85
monster.manual_seed = 4200
monster.randomize_seed = false
monster.draw_sprite()
print(monster.last_traits)
var image: Image = monster.get_image()
```

**Compatibility:** For these four refined archetypes, default PNG pixels now include the new markings. To reproduce earlier PNG exports, disable internal details. In-game node animation is still rendered by the original live group drawer; internal markings apply to `get_image()` and PNG exports, so display the generated image as a nearest-filtered texture when using the finish.

## Structural diversity across creature families

`structural_variants` activates deterministic shape variants selected from the chosen seed. Spirit now has six genuine silhouettes: Wisp, Jelly, Wraith, Mask, Flame and Crowned, with different bodies, head forms, trailing appendages and seeded proportions. Insectoid, Quadruped and Golem receive four different morphological ornaments/body plans; Biped, Slime and Winged gain four silhouette variants each. Existing creature families and visual finishes remain supported. Mood affects proportions and trail lengths. `last_structure` and batch `structure` record the selected variant and its sampled parameters; manifests include those fields. Turn off structural variants to recover the previous anatomy path. The selection quality reroll stride is now different from the gallery's per-creature seed stride, preventing the deterministic overlap previously observed between adjacent cards. **Old quality-filtered seed results may change**; preserve presets/version for exact reproduction.

## Preview performance and shading controls

The laboratory separates **generation** from **visual finishing**. Changing Shading, style, projection or internal-detail intensity now recomposites already generated RGBA images through `CreaturePreviewComposer.compose()`, instead of rerunning cellular automata, quality search, anatomy or palette generation. The generator exposes `get_unfinished_image()` and `finish_image(image)` for projects that wish to reuse that two-stage pipeline. Fixed preset/seed rendering is unchanged by this refactoring.

Gallery generations yield the next frame after each sprite; the gallery only instantiates **12 preview cards per page**, with a page selector for larger encounters. This bounds the number of TextureRects rendered at once, although all requested images still occupy memory. When selecting high quality and 128 monsters, a *single* candidate can still take perceptible time: this remains synchronous CPU computation and isn't a worker-thread solution. Avoid dragging Shading while a large batch is in progress; wait for completion, then change appearance without rerolling.

```gdscript
monster.draw_sprite()
var raw: Image = monster.get_unfinished_image()
var result: Image = CreaturePreviewComposer.compose(
    raw, monster.creature_archetype, monster.last_traits,
    monster.internal_details_enabled, monster.internal_detail_strength,
    CreaturePixelEffects.Style.JRPG, CreaturePixelEffects.View.FRONT,
    0.7, 0.15, 0.0, monster.last_seed
)
```

The batch API now returns an extra `source_image` and `archetype` for restyling; `image` is still the final version. `source_image` increases retained memory per creature, trading memory for fast preview changes. `export_pngs()` exports `image` only, not these cached intermediates. For runtime encounter memory efficiency, release `source_image` if restyling is unnecessary. The animated Node2D cell renderer does not show image-only finishing.

## Theory-guided color and palette limits

Enable `color_theory_enabled` to use one of eight coherent harmonies (Auto, Monochromatic, Analogous, Complementary, Split Complementary, Triadic, Tetradic, Neutral + Accent). The base hue varies reproducibly across seeds using a golden-ratio step; related hues within one monster respect the selected harmony. The role palette reserves positions for shadow, body, secondary, accent, outline and highlights. `target_color_count` is 1–64; `MAXIMUM` uses **at most** N distinct opaque RGB colors in the finished PNG, while `EXACT` attempts **exactly** N, including after style filters and dithering. Exact N is impossible if the image has fewer than N opaque pixels; the algorithm prioritizes filled interior pixels for missing roles. These are color counts, not an application of the golden ratio to anatomical proportions. Existing coloring remains available by disabling color theory; this is an opt-in change on existing scenes.

The demo's Color Theory controls reapply harmonies and limits to cached native images without rerunning morphology. Exact count should be checked on the resulting PNG rather than the palette length. Generated palettes and roles are exposed through `last_palette`, `last_palette_roles` and `last_harmony`; batch results include palette metadata. Small N strongly constrains outlines/highlights; try 5–8 for classic pixel art.

### Cleaner color distribution

Harmonious palettes now use **role-aware tonal ramps**, not independent nearest-color matching on each pixel. Neighboring body pixels share coherent light/shadow regions; outlines and generated markings can be protected as accent areas, with the accent limited to a small portion of the body. A conservative local cleanup removes isolated color noise without erasing meaningful marks. `MAXIMUM` limits final opaque RGB colors, while `EXACT` fills unused palette roles after cleanup when enough opaque pixels exist. The demo recalculates harmony and tonal finish using cached sprites: color controls no longer reroll anatomy. The original `quantize()` remains available for compatibility.
