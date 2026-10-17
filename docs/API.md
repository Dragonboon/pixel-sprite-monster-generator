# Developer API (English navigation)

The complete method contracts and copyable GDScript examples are in [API_ES.md](API_ES.md), currently maintained in Spanish with code identifiers in English. For a shorter English overview, see [README.md](../README.md).

## Main entry points

| Method | Purpose |
|---|---|
| `PixelSpriteMonsterGenerator.draw_sprite()` | Reroll from the configured seed |
| `get_image()` / `export_png(path)` | Retrieve or save finished art |
| `get_unfinished_image()` + `finish_image(base)` | Restyle cached sprite |
| `CreatureGenerationPreset.apply_to(generator)` | Apply configured authoring resource |
| `CreatureBatchGenerator.generate(preset,parent,count,seed)` | Generate 1–16 items |
| `generate_encounter(preset,parent,count,seed)` | Synchronous 1–128 result |
| `generate_encounter_async(preset,parent,count,seed,seed_step,chunk_size)` | Frame-yielding 1–128 result |
| `export_pngs(items, directory, prefix)` | Save PNGs + JSON manifest |

`generate_encounter*` returns a dictionary with `error`, `items`, `requested_count`, `generated_count` and `elapsed_ms`. Items contain `image`, `source_image`, `requested_seed`, `selected_seed`, `quality_score`, `quality_accepted`, `quality_attempts`, `integrity`, `anatomy`, `anatomy_metrics`, `structure`, `traits`, `palette`, `palette_roles`, `harmony`, `color_count_mode`, `archetype`, `index`, `seed_step` and `elapsed_ms`.

Use a node inside the active scene tree as `parent`. Save `selected_seed` for exact replay after quality selection. Use `user://` in exported games. Async batches yield between chunks, not during a single monster. For a worked example see [README.md](../README.md) and [API_ES.md](API_ES.md).
