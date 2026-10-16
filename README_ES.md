<p align="center"><img src="icon.svg" width="112" alt="Generador de monstruos pixel art"></p>
<h1 align="center">Pixel Sprite Monster Generator</h1>
<p align="center">Monstruos procedurales para Godot 4.7, reutilizables como sprites PNG.</p>

[English](README.md) · **Español** · [Validación](https://github.com/sempitern0/pixel-sprite-monster-generator/actions)

Genera siluetas, colores y movimiento opcional por grupos de píxeles sin dibujar
cada criatura. Es una adaptación a Godot del
[generador de sprites de Deep-Fold](https://deep-fold.itch.io/pixel-sprite-generator).
Produce imágenes: no añade lógica de juego, colisiones ni animaciones diseñadas a mano.

## Primeros pasos

1. Utiliza **Godot 4.7.x**. Las pruebas automáticas usan **4.7.2 estable**.
2. Copia `addons/pixel_sprite_monster_generator/` a `addons/` de tu juego, conservando el nombre de la carpeta.
3. Activa el complemento en **Proyecto → Ajustes del proyecto → Plugins**.
4. Añade un nodo `PixelSpriteMonsterGenerator` a tu escena y ejecútala.
5. Ajusta tamaño, colores, simetría y suavizado; llama a `draw_sprite()` para regenerar.

Abre `demo/test.tscn` o pulsa **F5** para explorar seis monstruos, tres tipos de silueta, nuevas semillas y exportación PNG por lotes.
La vista del monstruo se genera al ejecutar; no hay previsualización automática en el editor.

## Variaciones reproducibles

```gdscript
@onready var monstruo: PixelSpriteMonsterGenerator = $PixelSpriteMonsterGenerator

func _ready() -> void:
    monstruo.randomize_seed = false
    monstruo.manual_seed = 42
    monstruo.cell_animation = false
    monstruo.draw_sprite()
    var error := monstruo.export_png("user://monstruo_42.png")
    if error != OK:
        push_warning(error_string(error))
```

Para obtener variaciones aleatorias, activa **Randomize Seed**. Guarda `last_seed`
y los ajustes cuando encuentres una que te guste. Para repetirla, desactiva la
aleatoriedad y asigna esa semilla a **Manual Seed**. Regenerar respeta los nodos
hijos de tu juego y no altera su aleatoriedad ni los recursos de ruido compartidos.

| Ajuste | Función |
| --- | --- |
| Sprite Size | Cuadrícula lógica; se normaliza a 4–256 píxeles por eje |
| Sprite Draw Size | Escala de visualización; no modifica la resolución del PNG |
| Pixel Perfect | Dibuja cada celda como un píxel, ignorando la escala de visualización |
| Symmetry | 100 crea una silueta reflejada; valores menores introducen variación |
| Organic Shape Strength | Recorta el contorno de forma irregular; 0 conserva el resultado original |
| Keep Largest Body | Elimina fragmentos desconectados después del autómata celular |
| Creature Archetype | Original, bípedo, insectoide, gelatinoso o alado |
| Anatomy Strength | Intensidad de las extremidades y rasgos; 0 desactiva la morfología |
| Facial Eyes | Abre dos cavidades para ojos si hay suficiente espacio en la silueta |
| Steps / Birth Limit / Death Limit | Suavizado mediante autómata celular; entre 0 y 20 pasos |
| Number of Colors | Paleta generada de 1–64 colores |
| Custom Color Palette | Recurso `PixelSpriteMonsterGeneratorColorPalette`; una paleta no vacía sustituye los colores generados de cuerpo y ojos |
| Eye Color Saturation / Value | Controles independientes de los ojos en modo HSV |
| Main / Secondary Noise | Patrones de color; se copian internamente y pueden omitirse para usar valores predeterminados |
| Cell Animation | Movimiento opcional de los grupos de píxeles |

No todas las semillas producen criaturas igual de legibles. Genera una selección
y conserva las siluetas que encajen con tu juego. Las cuadrículas grandes cuestan
más: mide el tiempo en tu dispositivo antes de generar muchos monstruos en un
solo fotograma.

## Exportar y reutilizar

`get_image()` devuelve una imagen RGBA transparente en **pose neutra, sin animación**.
Mide `Sprite Size + 2` por eje: un píxel de margen permite incluir el contorno.
`export_png(ruta)` guarda esa imagen y devuelve un código `Error`. La carpeta de
destino debe existir; utiliza `user://` en juegos exportados.

```gdscript
var imagen := monstruo.get_image()
if imagen != null:
    $Sprite2D.texture = ImageTexture.create_from_image(imagen)
```

La exportación se calcula en CPU y funciona también con `--headless`. No captura
la pantalla, otros nodos, la escala de visualización, la animación ni una hoja de
sprites. Importa los PNG con filtrado por vecino más cercano para conservar el
pixel art. `clear()` elimina solo el dibujo generado; `get_image()` devuelve `null`
hasta la siguiente generación.

## Compatibilidad y pruebas

La versión **1.4.0** está orientada a Godot 4.7. Instala el complemento en `addons/pixel_sprite_monster_generator/`; sus archivos de entrada son `plugin.cfg` y `plugin.gd`. Al actualizar una instalación existente, sustituye la carpeta anterior, actualiza las referencias a recursos en tus propias escenas y vuelve a activar el complemento. La reproducibilidad de las semillas requiere la misma implementación y ajustes del generador.

```sh
python3 scripts/run_tests.py --godot /ruta/a/godot
# Comprobación adicional con renderizador real y pantalla disponible:
python3 scripts/run_tests.py --godot /ruta/a/godot --render
```

Las pruebas cubren scripts, regeneración repetida, conservación de hijos,
aleatoriedad local, semillas, escala, simetría con tamaños impares, paletas de un
color, controles de ojos, tamaños inválidos y guardado/carga de PNG. Las pruebas
en Linux no certifican el comportamiento de hardware Windows, macOS o móvil.

## Ejemplos y créditos

![Ejemplos de monstruos animados](images/animated_showcase.gif)

Algoritmos originales de [Deep-Fold](https://github.com/Deep-Fold). Adaptación a
Godot mantenida por [sempitern0](https://github.com/sempitern0). Consulta
[LICENSE](LICENSE) y conserva las atribuciones aplicables al redistribuir.

[Comunica un problema](https://github.com/sempitern0/pixel-sprite-monster-generator/issues)
con semilla, ajustes, versión de Godot y plataforma.

## Familias anatómicas

El grupo **Creature Anatomy** del Inspector ofrece cuatro familias y el modo **Original**. **Biped** separa piernas y añade brazos; **Insectoid** incorpora antenas y patas pareadas; **Slime** genera una cúpula redondeada con base más amplia; **Winged** extiende alas a ambos lados del cuerpo. Son guías procedurales de silueta, no personajes articulados, por lo que conviene seleccionar semillas legibles.

```gdscript
monstruo.randomize_seed = false
monstruo.manual_seed = 1042
monstruo.creature_archetype = CreatureMorphology.Archetype.INSECTOID
monstruo.anatomy_strength = 0.9
monstruo.organic_shape_strength = 0.25
monstruo.keep_largest_body = true
monstruo.facial_eyes = true
monstruo.cell_animation = false
monstruo.draw_sprite()
var resultado := monstruo.export_png("user://insectoide.png")
```

La morfología se aplica después del suavizado celular y antes del color. No modifica el generador aleatorio global; **Original** evita por completo esta etapa. Las cavidades para los ojos dependen de disponer de una región sólida apropiada. Los resultados anteriores se conservan si se mantienen desactivados los nuevos parámetros.

### Demo y límites

Pulsa **F5** para ver seis variantes, cambiar la semilla y exportar PNG a `user://`. La galería queda fuera de `addons/`. No produce esqueletos, animaciones diseñadas a mano ni mallas semánticas; en cuadrículas pequeñas pueden recortarse antenas o alas.

## Selección de calidad y acabado artístico (1.4)

Activa **Quality Enabled** para explorar hasta **Quality Max Attempts** (1–32) variantes deterministas, conservando la mejor. **Quality Min Score** (0–100) establece el objetivo. Consulta `last_quality_score`, `last_quality_attempts`, `quality_accepted` y `last_seed`. La puntuación mide rasgos geométricos (tamaño, ocupación y conectividad), **no garantiza calidad estética**. Si ninguna variante alcanza el umbral, se conserva la mejor con `quality_accepted = false`. Por defecto está desactivado. Para repetir la búsqueda, guarda `manual_seed` y la configuración completa; `last_seed` identifica la variante finalmente elegida.

**Silhouette Mood** funciona independientemente del arquetipo: **Normal** conserva la forma; **Cozy** reduce salientes; **Horror** añade irregularidades puntiagudas; **Epic** enfatiza corona y hombros.

**Pixel Art Finish** permite estilos Classic, Handheld, JRPG, Dungeon, Cozy y Arcade. Añade sombreado por píxel, dithering en damero, glitch determinista opcional y una vista **Three Quarter** experimental por desplazamiento de filas. No genera geometría isométrica real. Los efectos operan en resolución nativa, sin interpolación. El PNG mantiene la cuadrícula. La animación original por grupos sigue dibujando con el renderizador antiguo; si necesitas mostrar el nuevo acabado en tu juego, utiliza una textura obtenida con `get_image()` y filtrado nearest-neighbor.

```gdscript
monstruo.randomize_seed = false
monstruo.manual_seed = 4433
monstruo.quality_enabled = true
monstruo.quality_min_score = 72.0
monstruo.quality_max_attempts = 12
monstruo.silhouette_mood = CreatureMood.Mood.COZY
monstruo.creature_archetype = CreatureMorphology.Archetype.SLIME
monstruo.visual_style = CreaturePixelEffects.Style.JRPG
monstruo.shading_strength = 0.7
monstruo.dithering_strength = 0.2
monstruo.cell_animation = false
monstruo.draw_sprite()
var imagen := monstruo.get_image()
$Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
$Sprite2D.texture = ImageTexture.create_from_image(imagen)
```

La demo F5 permite ajustar mood, estilo, umbral, sombreado y vista. Cada tarjeta muestra semilla y puntuación. **Export six PNGs** guarda las seis imágenes de la galería en `user://`. Conviene limitar los reintentos cuando la generación se ejecuta en dispositivos móviles.

## Perfiles de proporciones anatómicas

Asigna un recurso **CreatureAnatomyProfile** a `anatomy_profile` para activar la construcción procedural de masas conectadas. En el Inspector podrás editar intervalos mínimos y máximos relativos al tamaño del sprite para anchura, altura, cabeza y longitud de apéndices. Se muestrean mediante un RNG local reproducible. Cozy favorece cuerpos anchos con extremidades cortas; Horror estrecha la masa y alarga las extremidades; Epic aumenta volumen y alcance.

```gdscript
var proporciones := CreatureAnatomyProfile.new()
proporciones.body_width_min = 0.38
proporciones.body_width_max = 0.52
proporciones.appendage_min = 0.18
proporciones.appendage_max = 0.30
monstruo.anatomy_profile = proporciones
monstruo.creature_archetype = CreatureMorphology.Archetype.BIPED
monstruo.silhouette_mood = CreatureMood.Mood.COZY
monstruo.randomize_seed = false
monstruo.manual_seed = 4433
monstruo.draw_sprite()
print(monstruo.last_anatomy) # Proporciones muestreadas
```

El perfil nulo conserva el funcionamiento anterior. Este sistema inicial construye formas conectadas, pero todavía requiere selección visual de semillas; no garantiza una anatomía exacta. La nueva opción cambia los píxeles respecto al generador previo. Cozy y Dungeon también cuentan ahora con separación más marcada entre luminosidades cálidas y sombras frías.

## Vistas adicionales y puntuación anatómica

La demo incorpora vistas Front, 3/4 a izquierda y derecha, perfiles laterales, Back (reflejo) e Isometric 2D experimental. Son **proyecciones de imagen**, no rotaciones reales de una criatura 3D ni una reconstrucción de su anatomía. Se mantienen los valores guardados de Front y 3/4. Activa **Compare with Front** para comparar en paralelo la vista seleccionada con su frontal, usando idéntica semilla, silueta, mood y paleta. La exportación guarda únicamente la vista seleccionada.

Cuando existe `anatomy_profile`, la puntuación de calidad combina geometría general (65 %) y anatomía heurística (35 %). Consulta `last_anatomy_metrics`: `score`, `body_coverage`, `appendage_balance` y `base_support`. Son aproximaciones basadas en píxeles, no un reconocimiento semántico de extremidades. Sin perfil, se mantiene la métrica anterior. La galería dispone del interruptor **Anatomy profile** y muestra los valores Q y A. La comparación A/B no cambia la semilla generada.

## Presets reutilizables y generación por lotes

Crea un recurso `CreatureGenerationPreset` desde el Inspector (o utiliza los ejemplos de `demo/presets/`). Incluye geometría, anatomía, mood, paleta, acabado y calidad, sin guardar una semilla aleatoria concreta.

```gdscript
var preset: CreatureGenerationPreset = load("res://demo/presets/cozy_slime.tres")
var resultados: Array[Dictionary] = CreatureBatchGenerator.generate(preset, self, 6, 4200)
var error := CreatureBatchGenerator.export_pngs(resultados, "user://criaturas", "cozy")
```

La generación utiliza un nodo temporal y **no modifica la criatura que ya se muestra**. El nodo padre debe pertenecer al árbol de escenas. Cada llamada produce hasta **16 sprites** y devuelve imágenes, semillas iniciales y elegidas, puntuaciones, número de intentos y metadatos anatómicos. La exportación crea la carpeta de destino, archivos PNG en resolución nativa y un manifiesto JSON. Admite rutas `user://` y `res://`; los nombres existentes se sobrescriben. Conserva también el recurso del preset y la versión del plugin para reproducir exactamente el lote: el manifiesto no incluye todas las referencias de recursos.

Las vistas proyectadas siguen siendo experimentales. La generación es síncrona; evita ejecutar lotes grandes en fotogramas críticos de juegos o móviles.
