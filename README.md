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

Open `demo/test.tscn`, or press **F5**, for an interactive six-monster gallery with three silhouette archetypes, reseeding and PNG batch export.
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

Version **1.4.0** targets Godot 4.7. Install the addon in `addons/pixel_sprite_monster_generator/`; its entry files are `plugin.cfg` and `plugin.gd`. When updating an existing installation, replace the previous addon folder, update any resource references in your own scenes, and enable the plugin again. Seed reproducibility requires the same generator implementation and settings.

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
