# Pixel Sprite Monster Generator

Generate deterministic pixel monsters in **Godot 4.7**, preview them in the laboratory, and export PNG sprites. No external runtime dependencies.

![Plugin icon](../icon.svg)

**[Español](README_ES.md)** · **[Developer API](docs/API.md)** · **[Historical feature notes](docs/HISTORY.md)**

## Quick start

1. Copy `addons/pixel_sprite_monster_generator/` to your project's `addons/`.
2. Enable the plugin in **Project → Project Settings → Plugins**.
3. Open `demo/test.tscn` to compare families, moods, palettes and Uncanny Horror variations.
4. Generate artwork using a `PixelSpriteMonsterGenerator` node or a `CreatureGenerationPreset`.

```gdscript
@onready var monster: PixelSpriteMonsterGenerator = $PixelSpriteMonsterGenerator

func _ready() -> void:
    monster.randomize_seed = false
    monster.manual_seed = 4200
    monster.creature_archetype = CreatureMorphology.Archetype.GOLEM
    monster.color_theory_enabled = true
    monster.target_color_count = 8
    monster.cell_animation = false
    monster.draw_sprite()
    monster.export_png("user://monster.png")
```

A saved seed reproduces the selected result. If quality filtering is enabled, **save `last_seed`**, not only the seed you requested.

## What can I generate?

- **Families and anatomy:** biped, quadruped, insectoid, slime, winged, golem, spirit, with seeded structural variants and proportional anatomy.
- **Appearance:** moods (Normal, Cozy, Horror, Epic), classic or uncanny horror, pixel art styles and viewing projections.
- **Color:** harmonious schemes, shadow/body/accent roles, exact or maximum palette sizes (1–64 colors).
- **Quality:** optional silhouette repair and seeded quality rerolls; imperfect results are marked, not silently hidden.
- **Batch assets:** 1–16 sprites via `generate()`, or 1–128 with `generate_encounter()` and `generate_encounter_async()`.
- **Output:** PNG plus reproducible seed/quality/anatomy/palette metadata in a JSON manifest.

## Everyday workflow

Use **Generate gallery** to explore seeds. Choose a family, mood and harmony. For mystery games choose **Horror → Uncanny valley** with Biped, Golem or Spirit. Use **Compare legacy anatomy** for before/after previews, then export chosen PNGs. Gallery progress updates per creature; changing shading or palette reuses already generated base images.

| Goal | Main API |
|---|---|
| One monster | `PixelSpriteMonsterGenerator.draw_sprite()`, `get_image()`, `export_png()` |
| An encounter | `CreatureBatchGenerator.generate_encounter_async(preset, parent, count, seed)` |
| Save a collection | `CreatureBatchGenerator.export_pngs(items, "user://monsters", "enemy")` |
| Adjust a render | `get_unfinished_image()` + `finish_image(source)` |
| Inspect results | `last_seed`, `last_quality_score`, `last_integrity`, `last_structure` |

**[Full API reference with code samples](docs/API.md)**

## Requirements and limitations

Requires **Godot 4.7.x**. Sprites are graphics, not game entities, collisions, AI or authored animations. Image generation is CPU-based; async batching yields between chunks, not during an individual monster. Larger sprite sizes, repeated quality attempts and retaining base images increase time and memory. PNGs are pixel-space images; Godot textures should use nearest filtering.

Use `python3 scripts/run_tests.py --godot /path/to/godot` to validate locally, with `--render` for tests that require a graphical backend. No GitHub Actions run is required for local validation.

## License and credits

MIT license. Based on [Deep-Fold's pixel sprite generator](https://deep-fold.itch.io/pixel-sprite-generator). See [LICENSE](LICENSE), [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/HISTORY.md](docs/HISTORY.md).
