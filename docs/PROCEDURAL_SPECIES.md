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

## Dedicated species lab

Open `res://demo/species_lab.tscn` directly, or select **Open Species Lab** from the original `demo/test.tscn` laboratory. The classic gallery remains the project's default starting scene; the laboratories can navigate back and forth without changing the generation API.

The Species Lab is organized into three areas:

- **Generation:** selected body plan (or balanced forms), elemental palette, fixed base seed, count (1–48), native resolution (24–128), and actions to explore new seeds or compare all 14 forms under one seed.
- **Gallery:** progressive batches yielding to the scene tree after every four generated sprites. Select images or click **Inspect**. The current card is visibly highlighted.
- **Genome inspector:** enlarged nearest-neighbor preview, metadata, JSON genome, pin a reference creature for comparison, copy JSON to clipboard, or export selected creature.

**Export gallery** saves each PNG plus its versioned genome JSON and a collection manifest in `user://species_lab/`. The exported PNGs are actual generated images, not preview screenshots. Generated images are held only for the current gallery and regenerated when a new batch starts. All image generation occurs synchronously per creature on the main thread; yielding only occurs between chunks. The pinned preview persists across gallery refreshes.

At 48×48 and 14 selected creatures, **Compare all 14 forms** uses the same base seed and palette element for every entry, useful for controlled visual QA. It intentionally ignores the form filter. **Generate gallery** changes the seed per entry and respects the selected form filter.

### Manual QA checklist

1. Open both lab scenes in Godot 4.7; navigate between them without errors or altered legacy results.
2. Generate all 14 forms repeatedly with the same seed and element. Confirm pixel-identical output and stable order.
3. Change element and confirm the morphology holds while the palette changes. Change resolution and verify transparent padding and nearest filtering.
4. Pin one creature; generate a new gallery and confirm the pinned visual reference remains.
5. Export one selected creature and a gallery, load PNG and JSON, and replay `CreatureSpeciesGenerator.render(genome, size)` at the exported size.
6. Start several galleries quickly (including 48 items); only the latest run should populate its gallery.
7. Verify UI at 1280×720 and 1920×1080. The three-column layout is intended for desktops, not mobile.

## Modular Species DNA and Trait Mixer (schema v2)

The original schema v1 render pipeline is unchanged for saved genomes. Enable **Modular anatomy** in Species Lab to create schema v2 creatures using head, limb, back and tail modules. The controls include a *Surprise me* option, six numeric mood influences (organic, epic, funny, creepy, cute, wild), mutation intensity, and per-trait mutation locks. Mood biases currently alter sampled proportions and anatomy (not just color); more expressive regional material painting remains follow-up work.

```gdscript
var options := {
    "form": CreatureSpeciesGenerator.Form.BIPED,
    "head": 1, # reptilian
    "limbs": 1, # claws
    "back": 2, # wings
    "tail": 3, # flame
    "moods": {"epic": 0.9, "creepy": 0.25, "funny": 0.7}
}
var genome := CreatureSpeciesDNA.sample(1234, options)
var result := CreatureSpeciesGenerator.render(genome)
var mutation := CreatureSpeciesDNA.mutate(genome, 4567, 0.65, {
    "form": true, "head": true
})
var mutated_image := CreatureSpeciesGenerator.render(mutation)
```

The mutation seed is saved in the mutated genome. Explicitly locked semantic traits survive rerolls, while unlocked traits are resampled with probability controlled by intensity. Save the full JSON genome, not merely a seed, after mutations or manual design changes.

### Run tests from the project without typing a Godot executable path

**Inside the editor:** open `res://tests/run_from_editor.gd`, then choose **File → Run** (EditorScript). It launches the project tests using the running editor's own executable, prints PASS/FAIL in the Output panel, and avoids Python completely.

**From a terminal:** run `python3 scripts/run_tests.py` (or `py scripts/run_tests.py` on Windows) without `--godot`; the script detects Godot in PATH and common Windows locations. Optionally set `GODOT_BIN` to override it.

**GitHub Actions:** the PR workflow also runs the strict test suite against the pinned Godot version. Headless automated tests validate API and scene behavior, not the aesthetic quality of sampled anatomy. Inspect silhouettes in the lab before merging.

## Visual finish and diversity QA

Schema v2 now supports `render_stage`: 0 raw mask, 1 flat palette, 2 silhouette-local volume shading, and 3 volume plus CPU finish. The old v1 shader/paint behavior is retained for compatibility. The former global Y>57% shadow boundary has been removed from v2. The lab provides a four-stage dropdown that rerenders the current batch and the selected preview. PNG export saves the **same CPU-finished pixels displayed in the gallery**, so no GPU readback is needed.

The optional shader `addons/pixel_sprite_monster_generator/shaders/species_finish.gdshader` provides an alpha-edge lighting preview for external sprites. It is not stacked over the lab's CPU finish to avoid applying highlights twice. Export is deterministic and does not require a viewport.

A silhouette-only 8×8 occupancy signature plus bounding dimensions and centroid helps reject near-identical sprites. Enable **Reject similar silhouettes** and adjust its threshold; generation retries up to six times, then accepts the best available result. This is a heuristic, not a promise of unique silhouettes.

Schema v2 anatomy adds torso, abdomen, stance and wing style choices with mutation locks. Recoloring is deliberately excluded from silhouette diversity metrics. Inspect mask vs flat vs volume to distinguish anatomical defects from palette/lighting artifacts.

**QA:** test each render stage, mutate while locking torso/head, export and reload PNG/JSON, and compare v1 snapshots. The CPU finish and shader use similar edge-light formulas but are not guaranteed bit-identical on every GPU. Visual quality still needs manual review in the editor.
