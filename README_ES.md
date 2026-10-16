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
2. Copia `addons/ninetailsrabbit.pixel_sprite_monster_generator/` a `addons/` de tu juego, conservando el nombre de la carpeta.
3. Activa el complemento en **Proyecto → Ajustes del proyecto → Plugins**.
4. Añade un nodo `PixelSpriteMonsterGenerator` a tu escena y ejecútala.
5. Ajusta tamaño, colores, simetría y suavizado; llama a `draw_sprite()` para regenerar.

Abre `demo/test.tscn`, o pulsa **F5** en este repositorio, para probar la regeneración.
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

La versión **1.1.0** se orienta a Godot 4.7 y conserva las rutas de recursos y del
complemento. Los resultados de semillas anteriores pueden cambiar por las
correcciones de ruido, color y aleatoriedad. La repetibilidad corresponde a la
misma implementación y ajustes, no a cualquier actualización futura del motor.

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
Godot publicada originalmente por Ninetailsrabbit y mantenida aquí. Consulta
[LICENSE](LICENSE) y conserva las atribuciones aplicables al redistribuir.

[Comunica un problema](https://github.com/sempitern0/pixel-sprite-monster-generator/issues)
con semilla, ajustes, versión de Godot y plataforma.
