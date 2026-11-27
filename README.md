# OPEN CITY

A small original 3D open-world mobile game prototype made with Godot 4.

## Current prototype

- Two small city districts separated by a river.
- A bridge connecting the districts.
- Original multi-floor buildings with tiled plaster/brick/concrete facade textures, framed reflective windows, shop fronts and roof tiles.
- Imported CC0 GLB car, tree and street-light models.
- Third-person player controller with a simple animated character model.
- Camera-relative movement: controls follow the direction the camera faces.
- Pedestrians with simple head, torso, arms and legs, randomized clothing colors and basic walk-cycle animation.
- Traffic cars with collision shapes, simple steering, acceleration and braking.
- Basic enter/drive/exit interaction with a follow camera.
- Simple car details: wheels, windshield, headlights and rear lights.
- On-screen touch controls for movement, running and entering/exiting cars.
- Swipe the right side of the screen to rotate the third-person camera.

The project retains CC0 GLB assets from the Low Poly City Kit by kayquer for the car, trees and street lights. Buildings now use original procedural geometry with custom SVG facade, brick, concrete, roof and asphalt textures in `assets/textures/`. The original CC0 license text is stored in `assets/licenses/CC0-1.0-City-Kit.txt`. No GTA assets are included.

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
