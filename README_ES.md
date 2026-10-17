# Pixel Sprite Monster Generator

Genera monstruos pixel art reproducibles en **Godot 4.7**, compáralos desde la galería y expórtalos como PNG. Sin dependencias externas en runtime.

**[English](README.md)** · **[API para desarrolladores](docs/API_ES.md)** · **[Historial técnico](docs/HISTORY_ES.md)**

## Primeros pasos

1. Copia `addons/pixel_sprite_monster_generator/` a la carpeta `addons/` de tu proyecto.
2. Activa el plugin en **Proyecto → Ajustes del proyecto → Plugins**.
3. Abre `demo/test.tscn` para probar familias, ambientes, paletas y Horror Uncanny.
4. Genera sprites desde un nodo `PixelSpriteMonsterGenerator` o un `CreatureGenerationPreset`.

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
    monster.export_png("user://monstruo.png")
```

La semilla permite repetir el resultado; con selección de calidad, **guarda `last_seed`**, porque puede ser distinta a la solicitada.

## ¿Qué puedo generar?

- **Morfologías:** Biped, Quadruped, Insectoid, Slime, Winged, Golem y Spirit, con variantes por semilla.
- **Ambientes:** Normal, Cozy, Horror, Epic y Horror Uncanny (para Biped, Golem y Spirit).
- **Color:** armonías cromáticas, luces, sombras, acentos y límites entre 1 y 64 colores.
- **Calidad:** reparación de siluetas y reintentos opcionales; identifica resultados imperfectos.
- **Lotes:** de 1 a 16 sprites mediante `generate()` y de 1 a 128 con `generate_encounter()` o `generate_encounter_async()`.
- **Archivos:** PNG y metadatos JSON de semillas, calidad, anatomía y paleta.

## Uso desde la galería

Selecciona una familia, ambiente y armonía, pulsa **Generate gallery** y compara resultados. Para juegos de misterio prueba **Horror → Uncanny valley**. Puedes alternar **Compare legacy anatomy** y exportar los PNG elegidos. La barra de progreso se actualiza durante los lotes; sombreado y paleta se pueden retocar sin regenerar las formas.

| Necesidad | Función |
|---|---|
| Crear un monstruo | `draw_sprite()`, `get_image()`, `export_png()` |
| Crear un encuentro | `CreatureBatchGenerator.generate_encounter_async(...)` |
| Exportar varios | `CreatureBatchGenerator.export_pngs(items, "user://monsters", "enemy")` |
| Cambiar el acabado | `get_unfinished_image()` + `finish_image(source)` |
| Consultar calidad | `last_seed`, `last_quality_score`, `last_integrity`, `last_structure` |

**[Referencia completa de la API con ejemplos](docs/API_ES.md)**

## Compatibilidad y límites

Necesitas **Godot 4.7.x**. Se generan imágenes; no IA, colisiones, personajes jugables ni animaciones diseñadas. La generación funciona en CPU; la versión asíncrona cede tiempo entre grupos, no durante cada criatura. Los intentos de calidad y el caché aumentan el coste de CPU y memoria. Para pixel art, utiliza filtrado nearest al crear texturas.

Ejecuta las pruebas locales con `python3 scripts/run_tests.py --godot /ruta/a/godot` y añade `--render` si dispones de entorno gráfico. Las pruebas no necesitan GitHub Actions.

## Licencia y créditos

MIT. Basado en el [generador pixel art de Deep-Fold](https://deep-fold.itch.io/pixel-sprite-generator). Consulta [LICENSE](LICENSE), [CONTRIBUTING.md](CONTRIBUTING.md) y el [historial](docs/HISTORY_ES.md).
