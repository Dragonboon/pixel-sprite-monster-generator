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
2. Copy `addons/ninetailsrabbit.pixel_sprite_monster_generator/` into your project's `addons/` directory, preserving the folder name.
3. Enable the plugin in **Project → Project Settings → Plugins**.
4. Add a `PixelSpriteMonsterGenerator` Node2D to a scene and run it.
5. Adjust the size, palette, symmetry and cellular automata settings, then call `draw_sprite()` to regenerate.

Open `demo/test.tscn`, or press **F5** in this repository, for a regeneration example.
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

Version **1.1.0** targets Godot 4.7. Existing addon and resource paths are retained.
Seed output can differ from older versions because noise/color handling and RNG
isolation were corrected. Repeatability applies to the same generator implementation
and settings, not indefinitely across engine or algorithm upgrades.

```sh
python3 scripts/run_tests.py --godot /path/to/godot
# Optional real-renderer pass, with a desktop display:
python3 scripts/run_tests.py --godot /path/to/godot --render
```

Checks cover script loading, repeated regeneration, authored child preservation,
random-stream isolation, fixed/random seed replay, scale, odd-sized symmetry,
one-color palettes, independent eye colors, invalid sizes and PNG round trips.
Linux automated tests do not certify Windows, macOS or mobile hardware behavior.

## Examples and credits

![Animated monster examples](images/animated_showcase.gif)

Original visual algorithms by [Deep-Fold](https://github.com/Deep-Fold).
Godot port originally published by Ninetailsrabbit, maintained in this repository.
See [LICENSE](LICENSE) and preserve applicable attribution when redistributing.

[Report a problem](https://github.com/sempitern0/pixel-sprite-monster-generator/issues)
with your seed, settings, Godot version and platform.
