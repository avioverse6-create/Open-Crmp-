# OPEN CITY

Original small-scale 3D open-world mobile game prototype made with Godot 4.x.

## Current asset set

- **Buildings:** 21 separate Kenney City Kit Suburban GLB building models. The matching color atlas is included beside the models; buildings are selected randomly and rotated for variation.
- **Roads:** 10 modular Kenney City Kit Roads GLB pieces, including straight sections, bends, crossings, intersections, a roundabout and a bridge.
- **Street props:** imported traffic lights, highway signs, bridge pillars, construction barriers and cones. Matching road color atlas is included.
- **People:** four rigged Mixamo GLB characters are used for the player and pedestrians. The separate animation library currently supplies Idle and Run; Run is slowed to approximate a walk for pedestrians. The bundled library has Idle and Run but no dedicated Walk clip; the Run cycle is slowed for pedestrian walking.
- **Cars:** 11 imported Kenney Car Kit GLBs are used in traffic: sedan, SUV, taxi, police car, delivery van, box truck, fire truck, garbage truck, sports hatchback, sports sedan and ambulance. Each model appears once in the current traffic set, with vehicles moving in opposite directions on the two main roads. Their embedded textures are preserved, and separate wheel meshes rotate while the vehicles move.
- **Nature:** imported low-poly trees plus Quaternius CC0 bush, flowering-bush and grass GLBs scattered along the riverbanks.

## World and gameplay

- Two small city districts separated by a river, connected by a bridge.
- Main roads, side streets, sidewalks, lane markings and imported intersection pieces. Road, sidewalk and terrain surfaces use 512×512 AmbientCG color textures.
- Closer third-person camera with an independent orbit pivot and swipe rotation on the right side of the screen.
- Live top-right minimap showing the river, bridge, main roads, side streets, building blocks and player position.
- Camera-relative player movement using an independent camera yaw (prevents rotation feedback), running and jumping.
- 16 rigged Mixamo pedestrians, randomly selected from four character models, patrolling the sidewalks in both districts.
- Eleven distinct imported traffic vehicles with collision shapes, two-way movement and rotating wheel meshes.
- Enter/drive/exit interaction with a follow camera.
- On-screen virtual joystick, run, jump and vehicle buttons.

## Visual target and current limits

This is a mobile-friendly low-poly prototype, not a photorealistic GTA-quality build yet. The imported building and road meshes use their original Kenney color atlases. The old procedural SVG surface maps remain in `assets/textures/` for legacy materials; the current road, sidewalk and grass surfaces use 512×512 AmbientCG color maps. These are albedo/color maps only, not a complete scanned PBR set. The imported city kit is stylized, while the player and pedestrian models are rigged Mixamo characters.

No GTA code, maps, characters, logos or extracted game assets are included.

## Open the project

1. Install **Godot 4.x**. On Android, use the Godot Android Editor; on a computer, use the desktop editor.
2. Download this repository as a ZIP or clone it.
3. In Godot, choose **Import** and select `project.godot`.
4. Open `scenes/main.tscn` and press **Run Project**.

## Controls

- WASD / arrow keys or on-screen virtual joystick: move.
- Shift or **БЕЖАТЬ**: run.
- Space or **ПРЫЖОК**: jump.
- **МАШИНА**: enter the nearest car.
- While driving, use up/down to accelerate/brake and left/right to steer.
- **ВЫЙТИ**: leave the car.

## Next milestones

1. Improve vehicle handling, steering and traffic lane changes.
2. Improve pedestrian navigation and collisions.
3. Improve camera smoothing, add missions, save data, sound and graphics settings.
4. Replace procedural detail maps with true PBR normal/roughness maps where mobile performance allows.
5. Import and test on an Android device, then optimize based on real frame-time measurements.

## Asset licensing

- City buildings, road pieces and roadside props: Kenney assets, CC0 1.0. See `assets/models/city/CREDITS.md`.
- The 11-model vehicle fleet: Kenney Car Kit, CC0 1.0. See `assets/models/vehicles/CREDITS.md` and `CC0-1.0.txt`.
- AmbientCG color textures: CC0 1.0; see `assets/textures/AMBIENTCG-CREDITS.md`.
- Player and pedestrian characters and their animation library: Mixamo assets bundled by vinish.dev. See `assets/models/people/CREDITS.md`; review Adobe's current terms before publishing.
- Original city-kit tree and street-light assets: see `assets/licenses/CC0-1.0-City-Kit.txt`.
- Bush, flowering-bush and grass models: Quaternius Stylized Nature MegaKit, CC0; see `assets/models/nature/CREDITS.md`.

Keep the asset credit and license files with the project. The project has not yet been verified in the Godot editor on a real Android device.


### Ground texture set

The mobile scene uses CC0 AmbientCG color/albedo maps for Asphalt021 (roads), Concrete012 (sidewalks, curbs and bridge), and Grass004 (terrain). Materials use triplanar mapping to reduce visible stretching on box-shaped surfaces. These committed AmbientCG maps are the color/albedo layer. Lightweight procedural normal and roughness detail maps are wired separately; they are not scanned AmbientCG maps. Imported Kenney city buildings keep their original atlas textures.


### Surface detail maps

Roads, sidewalks, bridge surfaces and terrain now have normal and roughness texture slots wired into their Godot materials. The asphalt and concrete detail maps currently use the project's lightweight procedural SVG maps; grass has matching procedural detail maps. They are not scanned AmbientCG normal/roughness maps, so their bump detail is intentionally subtle. The AmbientCG color maps remain the source of the surface color.

## Recorded audio sources
- Vehicle engine loop: Generic V8 Engine Sound by DerMeehdrescher / Meehdrescher Studios, CC BY-SA 4.0.
- Engine start: Car engine Start Up 02 by looneybits, CC0.
- Street traffic ambience and distant pedestrian chatter: field recordings from Gregor Quendel's Free General Ambience Sounds collection, CC BY-SA 4.0.
- The Android CI workflow downloads these files before Godot import; audio is spatialized for vehicles and city districts. Keep the credits and licenses with the project.
- Player and NPC footsteps: six short, real field-recorded subway/concrete step samples by GboxMikeFozzy, CC0, from OpenGameArt.org.
- Main menu music: "Urban Theme" by MintoDog, loopable MP3, CC0, from OpenGameArt.org.
- Pedestrian chatter uses the existing real field recording from Gregor Quendel's crowd ambience collection; the sound is placed on selected NPCs with 3D distance falloff.
