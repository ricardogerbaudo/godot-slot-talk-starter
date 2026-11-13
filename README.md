# Build your first slot game with Godot

Starter files for the tech talk. The project itself is created from scratch in the Godot editor.

## Before the talk

1. Install [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) (standard edition, not .NET).
2. Download the free art pack [Crowns of Kemet Lite](https://retrostylegames.itch.io/crowns-of-kemet-free) and unzip it.
3. Download this repository.

The art pack license does not allow redistributing its files, so they are not in this repository.

## Contents

- `STEPS.md`: the step by step.
- `snippets/`: the code pasted during the talk, in order.
- `tools/`: copy it into your project in step 2. `bake_anubis.gd` generates the animated Anubis (step 4), and `catch_up/step_NN.gd` rebuilds the project at the end of step NN. Open the script and use File > Run. The baker uses the Spine runtime, which requires your own Spine Editor license.
