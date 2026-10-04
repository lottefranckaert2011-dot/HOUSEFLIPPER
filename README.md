# HouseFlipper

A first-person house-flipping game built with [Godot 4](https://godotengine.org/).

## Getting started

1. Install **Godot 4.7 or newer** (standard build, not .NET): https://godotengine.org/download
2. Open Godot, click **Import**, and select `project.godot` in this folder.
3. Press **F5** to run the main scene.

## Controls

| Action          | Key               |
| --------------- | ----------------- |
| Move            | W A S D           |
| Look            | Mouse             |
| Jump            | Space             |
| Sprint          | Shift             |
| Interact        | E / Left click    |
| Release mouse   | Esc               |

## Project layout

```
project.godot     Engine settings and input map
scenes/           Scene files (.tscn); main.tscn is the entry point
scripts/          GDScript files
assets/           Models, textures, audio, fonts
```

## Interacting with objects

The player casts a short ray from the camera. Pressing **Interact** calls
`interact(player)` on whatever physics body is under the crosshair, if it has
that method. To make something interactable, attach a script to its
`StaticBody3D` / `RigidBody3D` / `Area3D`:

```gdscript
extends StaticBody3D

func interact(player: Player) -> void:
	print("Cleaned!")
```

## Linting

GDScript is checked with [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit):

```sh
pip install "gdtoolkit==4.*"
gdlint scripts/
gdformat --check scripts/
```
