# Procedural species grammar (experimental)

This optional runtime API complements the existing cellular-automata generator. It does not mutate `PixelSpriteMonsterGenerator`, change its presets, or change legacy seed results.

```gdscript
var result := CreatureSpeciesGenerator.generate(
    12345, Vector2i(48, 48),
    CreatureSpeciesGenerator.Form.QUADRUPED,
    CreatureSpeciesGenerator.Element.PLANT
)
var sprite := Sprite2D.new()
sprite.texture = ImageTexture.create_from_image(result["image"])
sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
add_child(sprite)

# Persist the sampled genome (Dictionary) to recreate the same pixels.
var genome: Dictionary = result["genome"]
var restored: Dictionary = CreatureSpeciesGenerator.render(genome, Vector2i(48, 48))
```

Fourteen original silhouettes use the common creature-body-plan taxonomy: floating head, head with legs, fish, insect, quadruped, one/two wing pairs, colony, tentacled, rooted body, biped with/without tail, serpent, and head with arms. Traits are semantic, rather than independent pixel noise: eye count, eye style (reserved for the next detail pass), horns, head proportions, limbs, pattern, palette element and mouth are in a versioned genome.

All visual marks are procedurally generated and no copyrighted sprites or reference-site images are incorporated.

## Known limitations

- Initial implementation is a **separate API**, not yet a selectable mode on the existing scene node or encounter generator.
- Character view is front/illustrative; there is no rig, authored animation, back/front/side consistency, or real species evolution system yet.
- Small details may merge at 24px; eye styles, claws, teeth and high-quality organic pattern families are future milestones.
- The current quality metrics are tuned to legacy silhouettes. Species grammar should have independent topology and readability checks.
- Exported image is transparent RGBA8 with one pixel of padding. The generator is CPU-based and synchronous.

Validation: run `godot --headless --path . --script res://tests/species_regression.gd` under Godot 4.7.x after importing the project. Run the full `python3 scripts/run_tests.py --godot /path/to/godot` suite before merging.
