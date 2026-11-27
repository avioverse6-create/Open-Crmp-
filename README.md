# OPEN CITY

Original small-scale 3D open-world mobile game prototype made with Godot 4.x.

## Current asset set

- **Buildings:** 21 separate Kenney City Kit Suburban GLB building models. The matching color atlas is included beside the models; buildings are selected randomly and rotated for variation.
- **Roads:** 10 modular Kenney City Kit Roads GLB pieces, including straight sections, bends, crossings, intersections, a roundabout and a bridge.
- **Street props:** imported traffic lights, highway signs, bridge pillars, construction barriers and cones. Matching road color atlas is included.
- **People:** four rigged Mixamo GLB characters are used for the player and pedestrians. The separate animation library currently supplies Idle and Run; Run is slowed to approximate a walk for pedestrians. There is not yet a dedicated Walk clip.
- **Cars:** traffic now randomly uses eight separate imported Kenney Car Kit GLBs: sedan, SUV, taxi, police car, delivery van, truck, fire truck and garbage truck. Their original atlas colors are preserved. Wheel animation and traffic variety by district are still future work.
- **Nature:** imported low-poly tree models from the original CC0 City Kit.

## World and gameplay

- Two small city districts separated by a river, connected by a bridge.
- Main roads, side streets, sidewalks, lane markings and imported intersection pieces.
- Third-person camera with swipe rotation on the right side of the screen.
- Camera-relative player movement, running and jumping.
- Pedestrian movement with rigged character animation.
- Traffic cars with collision shapes and basic movement.
- Enter/drive/exit interaction with a follow camera.
- On-screen mobile movement, run, jump and vehicle buttons.

## Visual target and current limits

This is a mobile-friendly low-poly prototype, not a photorealistic GTA-quality build yet. The imported building and road meshes use their original Kenney color atlases. The old procedural SVG surface maps remain in `assets/textures/` for the legacy geometry and future material work; they are not scanned photogrammetry textures. The imported city kit is stylized, while the player and pedestrian models are rigged Mixamo characters.

No GTA code, maps, characters, logos or extracted game assets are included.

## Open the project

1. Install **Godot 4.x**. On Android, use the Godot Android Editor; on a computer, use the desktop editor.
2. Download this repository as a ZIP or clone it.
3. In Godot, choose **Import** and select `project.godot`.
4. Open `scenes/main.tscn` and press **Run Project**.

## Controls

- WASD / arrow keys or on-screen arrows: move.
- Shift or **БЕЖАТЬ**: run.
- Space or **ПРЫЖОК**: jump.
- **МАШИНА**: enter the nearest car.
- While driving, use up/down to accelerate/brake and left/right to steer.
- **ВЫЙТИ**: leave the car.

## Next milestones

1. Add separate civilian vehicle models (sedan, SUV, van and bus) and wheel rotation.
2. Replace the single car model used by traffic with a varied fleet.
3. Improve pedestrian navigation, traffic lane logic and collisions.
4. Add minimap, camera smoothing, missions, save data, sound and graphics settings.
5. Import and test on an Android device, then optimize based on real frame-time measurements.

## Asset licensing

- City buildings, road pieces, roadside props and the eight-vehicle Car Kit fleet: Kenney assets, CC0 1.0. See `assets/models/city/CREDITS.md` and `assets/models/vehicles/CREDITS.md`.
- Player and pedestrian characters and their animation library: Mixamo assets bundled by vinish.dev. See `assets/models/people/CREDITS.md`; review Adobe's current terms before publishing.
- Original city-kit car, tree and street-light assets: see `assets/licenses/CC0-1.0-City-Kit.txt`.

Keep the asset credit and license files with the project. The project has not yet been verified in the Godot editor on a real Android device.
