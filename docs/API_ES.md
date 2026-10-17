# Developer API · Godot 4.7

[Inicio rápido](../README_ES.md) · [English](API.md)

La API genera **sprites PNG** y metadatos; no crea escenas jugables con IA, colisiones o animaciones diseñadas. Todas las generaciones son locales, sin servicios externos. Las opciones de calidad pueden **cambiar la semilla seleccionada**: guarda siempre `last_seed` o `selected_seed`.

## 1. Un monstruo desde una escena

Añade un nodo `PixelSpriteMonsterGenerator` y configura los parámetros antes de llamar `draw_sprite()`:

```gdscript
@onready var monster: PixelSpriteMonsterGenerator = $PixelSpriteMonsterGenerator

func _ready() -> void:
    monster.randomize_seed = false
    monster.manual_seed = 4200
    monster.creature_archetype = CreatureMorphology.Archetype.GOLEM
    monster.silhouette_mood = CreatureMood.Mood.EPIC
    monster.anatomy_integrity_enabled = true
    monster.color_theory_enabled = true
    monster.color_harmony = CreatureColorTheory.Harmony.AUTO
    monster.target_color_count = 8
    monster.color_count_mode = CreatureColorTheory.CountMode.MAXIMUM
    monster.quality_enabled = true
    monster.quality_max_attempts = 8
    monster.cell_animation = false
    monster.draw_sprite()
    var image: Image = monster.get_image()
    print(monster.last_seed, " · ", monster.last_quality_score)
    var error: Error = monster.export_png("user://monster.png")
    if error != OK:
        push_warning(error_string(error))
```

`draw_sprite()` regenera anatomía, paletas y el resultado. `get_image()` devuelve el PNG lógico sin escalar (con un píxel de margen transparente); `export_png(path)` escribe la imagen. `get_image()` funciona sin una ventana de renderizado; la generación no requiere shaders.

## 2. Encuentros RPG: 1 a 128 criaturas

`CreatureGenerationPreset` es un `Resource` reutilizable. `CreatureBatchGenerator` crea un trabajador temporal, sin sobrescribir un generador activo ni alterar el RNG global.

```gdscript
func create_encounter() -> void:
    var preset := CreatureGenerationPreset.new()
    preset.creature_archetype = CreatureMorphology.Archetype.INSECTOID
    preset.anatomy_profile = CreatureAnatomyProfile.new()
    preset.silhouette_mood = CreatureMood.Mood.HORROR
    preset.anatomy_integrity_enabled = true
    preset.color_theory_enabled = true
    preset.target_color_count = 6
    var result: Dictionary = await CreatureBatchGenerator.generate_encounter_async(
        preset, self, 24, 4200, CreatureBatchGenerator.DEFAULT_SEED_STEP, 1
    )
    if result["error"] != OK:
        push_warning(error_string(int(result["error"])))
        return
    var items: Array[Dictionary] = result["items"]
    for item in items:
        var texture := ImageTexture.create_from_image(item["image"])
        # Usa texture en tus Sprite2D o TextureRect.
        print(item["selected_seed"], item["structure"], item["integrity"])
    var error: Error = CreatureBatchGenerator.export_pngs(items, "user://encounter", "enemy")
    if error != OK:
        push_warning(error_string(error))
```

El método **síncrono** `generate_encounter(preset,parent,count,first_seed,seed_step=7919)` devuelve el mismo tipo de resultado. `generate(preset,parent,count,first_seed,seed_step=7919)` es una comodidad para **1–16** criaturas y devuelve directamente `Array[Dictionary]` (vacío si falla). `generate_encounter_async(...,chunk_size=4)` admite **1–128**; cede entre grupos, **no dentro de cada criatura**, por lo que las semillas complejas siguen consumiendo CPU durante un fotograma.

`parent` debe estar dentro del árbol de escena. Si necesitas generar hasta 128 en una sola llamada síncrona usa `generate_encounter()`.

## 3. Parámetros de autoría

| Grupo | Campos principales | Uso |
|---|---|---|
| Geometría | `sprite_size`, `symmetry`, `steps`, `organic_shape_strength` | Tamaño lógico, simetría, suavizado y silueta |
| Anatomía | `creature_archetype`, `anatomy_profile`, `anatomy_strength`, `structural_variants` | Familia y proporciones |
| Integridad | `anatomy_integrity_enabled`, `quality_enabled`, `quality_min_score`, `quality_max_attempts` | Limpieza y selección de semillas |
| Ambiente | `silhouette_mood`, `horror_profile`, `uncanny_strength` | Normal, Cozy, Horror, Epic; Uncanny admite Biped, Spirit y Golem |
| Colores | `color_theory_enabled`, `color_harmony`, `target_color_count`, `color_count_mode` | Armonía y límite del PNG final (1–64) |
| Detalles | `internal_details_enabled`, `internal_detail_strength` | Ornamentación de familias compatibles |
| Acabado | `visual_style`, `view_mode`, `shading_strength`, `dithering_strength` | Postproceso sin regenerar anatomía |

Valores enum: `CreatureMorphology.Archetype` (Original, Biped, Quadruped, Winged, Slime, Insectoid, Spirit, Golem y los restantes valores declarados en el código), `CreatureMood.Mood` (Normal, Cozy, Horror, Epic), `CreatureHorrorProfile.Profile` (Classic, Uncanny), `CreatureColorTheory.Harmony` (Auto, Monochromatic, Analogous, Complementary, Split Complementary, Triadic, Tetradic, Neutral Accent), `CreatureColorTheory.CountMode` (Maximum, Exact). Consulta los enums del código para valores concretos.

**Compatibilidad:** `PixelSpriteMonsterGenerator` sin preset tiene integridad, teoría del color y quality gate desactivados por defecto. Los `CreatureGenerationPreset` nuevos tienen integridad y quality gate activados. Una paleta personalizada se configura mediante `custom_color_palette`; el modo de teoría del color se aplica al PNG final.

## 4. Horror Uncanny

```gdscript
var p := CreatureGenerationPreset.new()
p.creature_archetype = CreatureMorphology.Archetype.SPIRIT
p.silhouette_mood = CreatureMood.Mood.HORROR
p.horror_profile = CreatureHorrorProfile.Profile.UNCANNY
p.uncanny_strength = 0.75
p.color_theory_enabled = true
p.color_harmony = CreatureColorTheory.Harmony.AUTO
p.color_count_mode = CreatureColorTheory.CountMode.EXACT
p.target_color_count = 6
```

El perfil aplica seis siluetas (Mask, Puppet, Hollow, Watcher, Lurker, Broken Saint) y una paleta fría tenue solo con armonía Auto. Su definición **no implica** gore ni efectos de gameplay.

## 5. Cambiar Shading sin regenerar

```gdscript
monster.draw_sprite()
var base: Image = monster.get_unfinished_image()
monster.shading_strength = 0.85
var brighter: Image = monster.finish_image(base)
```

`finish_image(source)` aplica detalles, estilo y teoría del color usando los metadatos de la **última** generación. Requiere que `source` corresponda al mismo generador y semilla. En un resultado por lotes se guarda `source_image` además de `image`, por lo que es posible recomponer desde la imagen base. Descarta las imágenes base cuando no sean necesarias para reducir memoria.

## 6. Campos devueltos y errores

`generate_encounter*` devuelve `{"error": Error, "items": Array[Dictionary], "requested_count": int, "generated_count": int, "elapsed_ms": float}`. Cada elemento contiene:

| Campo | Descripción |
|---|---|
| `image`, `source_image` | `Image` final y base |
| `requested_seed`, `selected_seed`, `seed_step` | Semilla solicitada y ganadora del quality gate |
| `quality_score`, `quality_accepted`, `quality_attempts` | Métricas y selección; `false` indica *best effort* |
| `anatomy`, `anatomy_metrics`, `integrity` | Proporciones, puntuación e integridad |
| `structure`, `traits` | Subtipo y detalles internos |
| `palette`, `palette_roles`, `harmony`, `color_count_mode` | Metadatos cromáticos |
| `archetype`, `elapsed_ms`, `index` | Familia, duración e índice |

`export_pngs(items,directory,prefix)` exporta PNG y `<prefix>_manifest.json`. Emplea `user://` para escritura en juegos publicados. `res://` suele ser de solo lectura en la exportación. Si la generación de un elemento falla, el encuentro devuelve un error y no un resultado parcial. El score es heurístico, no una garantía artística.

## 7. Validación

En un proyecto Godot 4.7.x con el addon instalado, ejecuta `python3 scripts/run_tests.py --godot /ruta/a/godot`; añade `--render` si dispones de entorno gráfico. No se requieren bibliotecas externas en runtime.

**[Historia y detalles técnicos](../docs/HISTORY.md)** · **[README principal](../README_ES.md)**
