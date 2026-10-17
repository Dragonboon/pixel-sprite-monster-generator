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

Abre `demo/test.tscn` o pulsa **F5** para explorar la galería de 1 a 128 criaturas, sus arquetipos, semillas y exportación PNG + JSON.
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

La versión **1.5.0** está orientada a Godot 4.7. Instala el complemento en `addons/pixel_sprite_monster_generator/`; sus archivos de entrada son `plugin.cfg` y `plugin.gd`. Al actualizar una instalación existente, sustituye la carpeta anterior, actualiza las referencias a recursos en tus propias escenas y vuelve a activar el complemento. La reproducibilidad de las semillas requiere la misma implementación y ajustes del generador.

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

## Encuentros RPG: generar exactamente 1–N monstruos (1.5)

Para **una sola criatura** utiliza `CreatureBatchGenerator.generate_encounter(preset, parent, 1, semilla)`. Para varios enemigos, solicita una cantidad entre **1 y 128**. A diferencia del método anterior `generate()`, limitado a 16 resultados, la nueva API nunca reduce la cantidad silenciosamente. Devuelve `error`, `requested_count`, `generated_count`, `items` y `elapsed_ms`. Comprueba `error == OK` antes de utilizar el resultado. Las semillas individuales quedan registradas para repetir cada monstruo.

```gdscript
var preset: CreatureGenerationPreset = preload("res://demo/presets/dungeon_insectoid.tres")
var encuentro: Dictionary = await CreatureBatchGenerator.generate_encounter_async(
    preset, self, 8, 4200, 7919, 4
)
if encuentro["error"] == OK and encuentro["generated_count"] == 8:
    for criatura in encuentro["items"]:
        var sprite := Sprite2D.new()
        sprite.texture = ImageTexture.create_from_image(criatura["image"])
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        add_child(sprite)
```

`generate_encounter_async()` cede un fotograma entre tandas de 1–16 criaturas; cada tanda sigue calculándose de forma síncrona. La alternativa `generate_encounter()` es útil para herramientas. Ajusta el tamaño de la tanda según el dispositivo. El plugin no incorpora estadísticas, IA ni colocación de enemigos. `elapsed_ms` sirve como medición orientativa, no como benchmark universal.

La demo F5 incorpora **cantidad configurable de 1 a 128**, familias variadas o específicas (incluye Cuadrúpedo, Gólem y Espíritu), presets de ejemplo, favoritos, filtro de favoritos, puntuaciones, tiempos y exportación PNG+JSON. Al guardar correctamente muestra cuántas imágenes se han creado y su directorio completo; los errores se notifican visiblemente. Los favoritos duran solo durante la sesión. Con cantidades grandes puede aumentar el consumo de CPU/memoria. Las vistas proyectadas siguen siendo experimentales.

## Rendimiento y diagnóstico de variedad

La galería de la demo genera progresivamente, cede un fotograma cada cuatro criaturas, muestra el progreso y abandona resultados de una solicitud antigua si se cambian los parámetros. El botón **Benchmark 1 / 8 / 32 / 128** permite medir tiempos, bytes RGBA aproximados y variedad de siluetas con el preset/familia seleccionados.

`CreatureVariety.summarize(items)` añade `novelty` y `near_duplicate` a los resultados y resume imágenes exactas, siluetas aproximadamente distintas, duplicados cercanos y novedad media. Compara máscaras de transparencia normalizadas a 12×12, ignorando la paleta: cambiar solo el color no aumenta la variedad de silueta. Se trata de una **métrica orientativa**, no de una evaluación artística. No descarta criaturas ni modifica la cantidad solicitada.

La memoria indicada contabiliza únicamente los bytes RGBA de las imágenes, no los nodos, texturas, memoria total del proceso ni recolector de basura de Godot. Mide también en el hardware de destino y reduce calidad/intentos para generar enemigos durante el juego.

## Consolidación de calidad y rendimiento

Los encuentros ahora reutilizan un único generador temporal, evitando crear una instancia nueva cada 16 criaturas. El generador normal sigue creando su sprite en `_ready()`; solamente el trabajador interno aplaza su primera generación para utilizar la semilla solicitada exactamente una vez. Los encuentros síncronos y por tandas mantienen resultados equivalentes con un preset y semilla fijos. Se limpian los metadatos anatómicos entre generaciones, también al volver al arquetipo Original.

Con el filtro de calidad activado, la puntuación geométrica penaliza adicionalmente las islas desconectadas y las siluetas excesivamente vacías. Son heurísticas para reducir resultados poco legibles, no una garantía de atractivo visual. **Importante:** la recalibración puede escoger otro candidato con una semilla antigua *si está activada la selección por calidad*; el modo sin filtrado conserva su comportamiento anterior. Guarda el preset y la versión junto con las semillas exportadas.

## Calibración de morfología y comparación

Las familias **Insectoid, Quadruped, Golem y Spirit** construyen primero masas corporales conectadas cuando se activa **Refined Anatomy** (activado por defecto en criaturas configuradas nuevas). El insectoide diferencia cabeza, tórax, abdomen y seis patas articuladas; el cuadrúpedo tiene tronco, cuello, cabeza y cuatro patas; el gólem refuerza hombros, puños y pies; y el espíritu dispone de volúmenes flotantes con estelas. El ruido celular modula los contornos para conservar la aleatoriedad. Original, Biped, Slime y Winged mantienen sus rutas anteriores.

La opción **Compare legacy anatomy** de la galería permite comparar hasta doce criaturas con la versión antigua, ambas con la misma semilla seleccionada. La comparación consume generación adicional y está desactivada por defecto. **Refined Anatomy = false** recupera las reglas anteriores de estas cuatro familias. Si hay selección de calidad, la semilla elegida también puede variar al cambiar la puntuación. Para reproducir exactamente un PNG guarda semilla, preset y versión. Las mejoras se deben comprobar visualmente en Godot antes de considerar los recursos definitivos.

## Rasgos internos derivados de la semilla

Las familias Insectoid, Quadruped, Golem y Spirit incorporan ahora una segunda fase de **detallado interior** después del relleno de color y antes de los filtros pixel-art. Cada semilla seleccionada deriva su propio perfil `CreatureTraitProfile`, con patrón, distribución de ojos, ornamento, acento cromático y número/posición de marcas, sin alterar la silueta ni el RNG global. Los insectoides adquieren segmentos y placas; los cuadrúpedos, marcas de pelaje/lomo; los gólems, grietas, juntas y runas; y los espíritus, máscara y núcleo luminoso con estelas.

Los parámetros `internal_details_enabled` (activado por defecto) y `internal_detail_strength` (0–1) controlan el acabado. Desactívalo para recuperar el resultado anterior sin detalles en las cuatro familias. Los trazos se limitan a **píxeles interiores opacos**, respetando la resolución y la transparencia. `last_traits`, los resultados por lotes y el manifiesto JSON guardan la identidad procedural. La demo muestra un interruptor, un control de intensidad y el patrón/acento seleccionado en cada tarjeta.

```gdscript
monstruo.internal_details_enabled = true
monstruo.internal_detail_strength = 0.85
monstruo.manual_seed = 4200
monstruo.randomize_seed = false
monstruo.draw_sprite()
print(monstruo.last_traits)
var imagen: Image = monstruo.get_image()
```

**Compatibilidad:** el PNG de las cuatro familias refinadas cambia al incluir los detalles por defecto. Desactiva esta opción para repetir las exportaciones anteriores. El renderizador animado original sigue sin incorporar esta capa: para mostrarla dentro del juego utiliza la imagen obtenida con `get_image()` como textura con filtrado nearest-neighbor.

## Variedad estructural entre criaturas

`structural_variants` activa subtipos de silueta derivados de la semilla. Spirit pasa a tener seis formas: Wisp, Jelly, Wraith, Mask, Flame y Crowned, con masas, cabezas y estelas claramente diferenciadas. Insectoid, Quadruped, Golem, Biped, Slime y Winged reciben cuatro variantes estructurales cada uno. El mood modifica proporciones y longitudes. `last_structure`, los resultados de lotes y el manifiesto JSON registran el subtipo y sus parámetros. Desactiva `structural_variants` para recuperar las reglas anteriores. También se separa el salto de semillas de los reintentos del salto usado por la galería, evitando que tarjetas vecinas terminen accidentalmente en la misma semilla seleccionada. **Los resultados con selección de calidad pueden cambiar respecto a versiones anteriores**.

## Optimización del sombreado y de la galería

La demo ahora separa **generación de anatomía** y **acabado visual**. Cambiar Shading, estilo, proyección o intensidad de detalles reutiliza los RGBA originales mediante `CreaturePreviewComposer.compose()`; ya no vuelve a calcular autómatas, filtro de calidad, anatomía ni paleta. La API expone `get_unfinished_image()` y `finish_image(image)` para aprovechar el mismo flujo en juegos externos. Los resultados fijos por preset y semilla no deberían cambiar por esta refactorización.

La galería cede un fotograma después de cada criatura y muestra **12 tarjetas por página**, con selector para lotes grandes. Aunque así se limita el número de texturas visibles, las imágenes solicitadas siguen consumiendo memoria. La generación de cada criatura continúa siendo síncrona en CPU y una semilla costosa puede provocar esperas perceptibles. Es preferible esperar a que termine un lote grande antes de cambiar los parámetros, y después ajustar Shading sin regenerar las formas.

```gdscript
monstruo.draw_sprite()
var base: Image = monstruo.get_unfinished_image()
var final: Image = CreaturePreviewComposer.compose(
    base, monstruo.creature_archetype, monstruo.last_traits,
    monstruo.internal_details_enabled, monstruo.internal_detail_strength,
    CreaturePixelEffects.Style.JRPG, CreaturePixelEffects.View.FRONT,
    0.7, 0.15, 0.0, monstruo.last_seed
)
```

Los resultados por lotes añaden `source_image` y `archetype` para permitir cambios de estilo sin repetir generación; `image` sigue siendo la imagen terminada. El caché ocupa memoria adicional por criatura: elimina `source_image` cuando no necesites recalcular el acabado. `export_pngs()` guarda solo la imagen final. El renderizador animado Node2D sigue sin reflejar estos filtros de imagen.

## Teoría del color y cantidad de tonos

Activa `color_theory_enabled` para elegir armonías Monocromática, Análoga, Complementaria, Complementaria dividida, Triádica, Tetrádica o Neutros + acento (o Auto, según mood y familia). El tono principal varía determinísticamente entre semillas con un salto ligado a la proporción áurea, mientras los tonos internos siguen intervalos cromáticos coherentes. La paleta asigna papeles de sombra, cuerpo, color secundario, acento, contorno y luz. `target_color_count` admite de 1 a 64: `MAXIMUM` limita los colores RGB opacos visibles del PNG a **como máximo** N; `EXACT` intenta usar **exactamente** N incluso tras el sombreado y el dithering. Si hay menos de N píxeles opacos no es posible satisfacerlo. Se buscan posiciones interiores al insertar colores de papel poco utilizados. La proporción áurea se aplica a la distribución del tono principal entre semillas, no a las proporciones anatómicas.

Los controles de teoría del color de la demo recalculan la paleta a partir de imágenes base en caché, sin regenerar anatomía. Para verificar el número exacto de colores hay que examinar el PNG, no solo la longitud de la paleta. `last_palette`, `last_palette_roles` y `last_harmony` exponen información de la paleta; los lotes guardan metadatos. Con 5–8 colores suele conseguirse un acabado pixel-art clásico. Se conserva el modo anterior desactivando la teoría del color.

### Distribución de color más limpia

Las armonías usan **rampas tonales por función**, no una búsqueda independiente del tono más parecido para cada píxel. El cuerpo mantiene regiones más coherentes de luz y sombra; se protegen contornos y marcas interiores, reservando el acento para una parte pequeña del sprite. Una limpieza local elimina píxeles de color aislados sin borrar detalles importantes. `MAXIMUM` limita los colores RGB visibles del PNG, y `EXACT` completa los tonos no utilizados después de limpiar, cuando hay suficientes píxeles opacos. Los controles de color de la demo recomponen las imágenes en caché sin regenerar anatomía. Se mantiene `quantize()` como alternativa compatible con versiones anteriores.

## Horror Uncanny — terror psicológico y misterio

En la demo selecciona el ambiente **Horror** y después **Horror: Uncanny valley**. Esta opción crea seis siluetas deliberadamente inquietantes — **Mask, Puppet, Hollow, Watcher, Lurker y Broken Saint** — mediante una anatomía casi humana y proporciones de referencia basadas en el número áureo (φ ≈ 1,618). Las pequeñas desviaciones, simetrías ligeramente imperfectas, ojos vacíos y posturas rígidas buscan transmitir inquietud sin recurrir a gore ni a deformaciones aleatorias. El deslizador **Uncanny distortion strength** regula la intensidad.

Actualmente funciona en **Biped, Spirit y Golem**. Las demás familias siguen utilizando Horror normal. Está desactivado por defecto (**Classic Horror**) para conservar tus escenas anteriores. Con **Color Theory** activado y armonía **Auto**, se elige una paleta de tonos apagados (verde ceniza, azul frío, violeta o hueso), con un acento poco invasivo; las armonías seleccionadas manualmente se respetan. Puedes seguir eligiendo **Maximum / Exact** para limitar colores.

Para código, configura `silhouette_mood = CreatureMood.Mood.HORROR`, `horror_profile = CreatureHorrorProfile.Profile.UNCANNY` y opcionalmente `uncanny_strength = 0.75`. También está disponible en `CreatureGenerationPreset`. El subtipo se guarda en `last_structure` y en los lotes exportados. Las variaciones siguen siendo reproducibles por semilla y el sombreado se modifica desde caché.

## Integridad anatómica y limpieza de artefactos

Los presets nuevos de la galería activan **anatomy integrity** por defecto. Esta pasada determinista repara separaciones cortas entre extremidades, elimina pequeñas islas de píxeles desconectadas y rellena suavemente muescas de un píxel con tres vecinos. **No elimina ojos ni asimetrías deliberadas de Horror Uncanny**. Un evaluador adaptado a cada familia revisa conexiones, volumen central, extensión de la silueta y estructuras excesivamente finas. Si una generación falla, se intenta otra semilla en lugar de aceptar una puntuación engañosamente alta. Si se agotan los intentos, se devuelve la mejor alternativa con los campos `integrity.valid` y `quality_accepted` para indicar si cumple los criterios. Las comprobaciones pueden consumir algo más de CPU y cambiar la semilla finalmente elegida.

Para escenas existentes sigue siendo **opcional** (`anatomy_integrity_enabled = false`), conservando los resultados anteriores. `CreatureGenerationPreset` lo activa por defecto para nuevos presets; desactívalo si necesitas el comportamiento anterior. Puedes consultar `last_integrity`, el campo `integrity` de cada resultado y su manifiesto JSON. Las patas finas de Insectoid y las anomalías intencionadas de Uncanny utilizan límites de grosor más permisivos. Se recomienda revisar visualmente los PNG antes de incorporarlos al juego.
