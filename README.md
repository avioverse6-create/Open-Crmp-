# OPEN CITY

A small original 3D open-world mobile game prototype made with Godot 4.

## Current prototype

- Two small city districts separated by a river.
- A bridge connecting the districts.
- Original multi-floor buildings with 1024×1024 facade, brick, concrete, roof and asphalt albedo textures, plus separate normal/roughness maps for each surface family; framed windows and shop fronts.
- Imported CC0 GLB car, tree and street-light models.
- Third-person player controller with a more detailed assembled character, separate clothing/hair/shoes, walk/run cycle, body bob and jump input.
- Camera-relative movement: controls follow the direction the camera faces.
- Pedestrians with separate clothing, hair, trousers and shoes, varied outfits and a walk cycle with body motion. They remain procedural characters, not scanned human models.
- Traffic cars with collision shapes, simple steering, acceleration and braking.
- Basic enter/drive/exit interaction with a follow camera.
- Simple car details: wheels, windshield, headlights and rear lights.
- On-screen touch controls for movement, running, jumping and entering/exiting cars.
- Swipe the right side of the screen to rotate the third-person camera.

The project still retains CC0 GLB assets from the Low Poly City Kit by kayquer for the car, trees and street lights; these models have not yet been replaced by higher-detail models. Buildings now use original procedural geometry with custom SVG facade, brick, concrete, roof and asphalt textures in `assets/textures/`. The original CC0 license text is stored in `assets/licenses/CC0-1.0-City-Kit.txt`. No GTA assets are included.

## Open the project

1. Install **Godot 4.x** (use the Android editor on an Android device, or the desktop editor on a computer).
2. Download this repository as a ZIP, or clone it.
3. In Godot, choose **Import** and select the `project.godot` file.
4. Open `scenes/main.tscn` and press **Run Project**.

## Controls

- WASD / arrow keys or the on-screen arrows: move.
- Shift or **БЕЖАТЬ**: run.
- **МАШИНА**: enter the nearest car.
- While driving, use up/down to accelerate/brake and left/right to steer.
- **ВЫЙТИ**: leave the car.

## Next development milestones

1. Replace the temporary player and pedestrian shapes with licensed rigged GLB characters and proper animation clips.
2. Improve vehicle handling, traffic lanes and pedestrian navigation.
3. Add a minimap, camera smoothing and a polished mobile HUD.
4. Add missions, save data, sound and performance settings.
5. Test and optimize on real Android devices before publishing.

## Asset licensing

Only add assets whose licenses allow game use and redistribution. Keep each asset pack's license file beside the assets. Do not copy models, textures, maps, characters, logos or other protected content from Grand Theft Auto.
