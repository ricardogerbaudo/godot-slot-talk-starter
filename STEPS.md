# Step by step

Written for someone opening Godot for the first time. Shortcuts are written Mac / Windows.

Use the standard edition of Godot 4.7.2. The first time a node or option appears, the line after it explains what it does and why we use it; later steps only give the values. Values marked **[mouse]** are only looks: you can drag the node in the viewport (and use its corner handles for scale) instead of typing them. Everything else must be typed exactly.

**Lost?** After step 2 you can jump to the end of any step. In the FileSystem dock open `tools/catch_up`, double click `step_NN.gd` (for example `step_05.gd` for the end of step 5), then Script editor menu **File > Run** (Cmd+Shift+X / Ctrl+Shift+X). It rewrites the tutorial scenes and scripts to match that step, so anything you did in them is replaced. From step 4 on, if the Anubis frames do not exist yet it bakes them first and asks for the pack folder.

## 0. The editor in one minute

```
┌───────────────┬──────────────────────────────────┬──────────────┐
│ Scene dock    │  2D  3D  Script  Game  (top)     │ Inspector    │
│ (node tree)   │  toolbar                         │ Signals      │
│               │                                  │ (tabs)       │
├───────────────┤  Viewport (the screen you build) │              │
│ FileSystem    │                                  │              │
│ dock (files)  ├──────────────────────────────────┤              │
│               │ Bottom panel: Output, Animation  │              │
└───────────────┴──────────────────────────────────┴──────────────┘
```

- **Scene dock** (top left): the tree of nodes of the scene you are editing. Click a node to select it.
- **FileSystem dock** (bottom left): the project files. `res://` is the project folder.
- **Inspector** (right): the properties of the selected node. It is split into sections named after the node's classes, top to bottom from the most specific: for a TextureRect you see **TextureRect**, then **Control**, then **CanvasItem**, then **Node**. Click a gray heading (for example **Layout**) to open it.
- **Viewport** (center): the scene. Mouse wheel zooms; with the mouse over it, press **F** to frame the selected node.
- **2D / Script** (top center): switch between the viewport and the code editor.

Two words used everywhere:

- **Node**: one building block (a picture, a label, a button, an animation player). Each type does one job.
- **Scene**: a tree of nodes saved as a `.tscn` file. A scene can be placed inside another scene, where it shows up as a single node.

How to do the things every step repeats:

| To | Do |
| --- | --- |
| Add a child node | Select the parent in the Scene dock, click **+** at the top of the Scene dock (or Cmd+A / Ctrl+A), type the node type in Search, select it, **Create**. |
| Rename a node | Double click its name in the Scene dock, type, Enter. |
| Set a picture | Drag the `.png` from the FileSystem dock onto the field in the Inspector (it shows `<empty>`). |
| Type a number | Click the field, select its text, type, Enter. Fields with **x** and **y** have one box each. |
| Pick an option | Click the dropdown and choose. |
| Turn something on | Click the **On** checkbox. |
| Mark a node as unique | Right click it in the Scene dock > **Access as Unique Name**. A `%` appears next to it. Code can then find it as `%Name`, wherever it sits in the tree, so moving it later does not break the script. |
| Duplicate a node | Select it, Cmd+D / Ctrl+D. |
| Save the scene | Cmd+S / Ctrl+S. |

## 1. New project

1. Open Godot. The **Project Manager** opens.
2. Click **+ Create** (top left).
   - **Project Name**: `Kemet Slot`.
   - **Project Path**: pick an empty folder (Browse).
   - **Renderer**: **Compatibility**.
     The renderer is the part of Godot that draws on screen. Forward+ and Mobile have more 3D features but do not run in a browser; Compatibility runs everywhere, including the web export, and a 2D slot needs nothing more.
   - Click **Create**. The editor opens.
3. Menu **Project > Project Settings**. In the dialog, turn on **Advanced Settings** (switch at the top right).
   Without it Godot hides the less common settings, including the window overrides below.
4. In the list on the left, click **Display > Window**. On the right, in the **Size** group:
   - **Viewport Width** `1920`, **Viewport Height** `1080`.
     The size of the screen we design in. The pack's background is 1920 × 1080, and every position in these steps is in that space. Godot's default is 1152 × 648.
   - **Window Width Override** `1280`, **Window Height Override** `720`.
     Only the size of the window the game opens in, so it fits on a laptop. The design stays 1920 × 1080 and is scaled down to fit.
5. Scroll down to the **Stretch** group and check that **Mode** is `canvas_items` (new projects already have it).
   This is what scales the 1920 × 1080 design to the window or browser size. With `disabled` the game would draw at real pixels and a 1280 window would show only the top left corner.
6. Click **Close**.

Optional, full screen: in the same **Size** group set **Mode** to `Fullscreen`. The game then takes the whole monitor and the overrides no longer matter. When you run from the editor the game plays inside the Game tab, so full screen only shows in an exported build. In a browser, a page can only go full screen after the player clicks, so on the web this setting is ignored at startup.

## 2. Import the art

1. Download the pack from https://retrostylegames.itch.io/crowns-of-kemet-free and unzip it. It creates the folder `RSG-Slot-Asset-Pack-Crowns-of-Kemet-Free`, with `PNG`, `PSD` and `Spine` inside.
2. In Finder / File Explorer, drag that `PNG` folder onto `res://` in the FileSystem dock. Godot copies it into the project and imports every picture (a progress bar shows for a few seconds).
   Importing converts each PNG into a texture the engine can draw. Everything the game uses must be inside `res://`.
3. Click the arrow next to `PNG` to see its folders: `background`, `characters`, `logo`, `popups`, `reel`, `symbols`.
4. From this repository, drag the `tools` folder onto `res://` too. It holds the Anubis baker (step 4) and the catch-up scripts.

## 3. Main scene

The screen of the game: background, logo and reel frame. Anubis comes in step 4.

1. In the Scene dock, under **Create Root Node**, click **User Interface**. A node called `Control` appears.
   **Control** is the family of nodes for screens and interfaces: they are positioned by layout rules (stick to the edges, fill the parent, line up in rows) instead of a fixed point. The root of a scene is the node everything else hangs from.
2. Rename it to `Main`.
3. Save: Cmd+S / Ctrl+S, file name `main.tscn`, **Save**.

**Background**

4. With `Main` selected, add a child node **TextureRect**. Rename it to `Background`.
   A **TextureRect** is a Control that shows a picture inside a rectangle. You decide the rectangle; the options below decide how the picture fits in it.
5. In the Inspector, section **TextureRect** (at the top):
   - **Texture**: drag `PNG/background/background.png` from the FileSystem dock onto the field.
     The picture to show.
   - **Expand Mode**: `Ignore Size`.
     By default (`Keep Size`) the rectangle can never be smaller than the picture's own pixel size. `Ignore Size` drops that rule, so the rectangle can be any size and the picture adapts to it.
   - **Stretch Mode**: `Keep Aspect Covered`.
     How the picture fills the rectangle. `Scale` stretches it and deforms it; `Keep Aspect Centered` shows the whole picture and may leave empty bands; `Keep Aspect Covered` keeps its proportions and fills the whole rectangle, cutting what overflows. For a background, no empty bands is what matters.
6. In the Inspector, section **Control**, open **Layout**. Set **Layout Mode** to `Anchors`; a new field **Anchors Preset** appears below it. Set it to `Full Rect`. The background now fills the 1920 × 1080 screen.
   **Layout Mode** says how this Control gets its position and size: `Position` means fixed numbers you type; `Anchors` means it is attached to the edges of its parent. **Anchors Preset** is a shortcut for common attachments; `Full Rect` attaches all four edges to the parent's four edges, so the node always has the parent's exact size.

   This is not the same job as item 5. Layout decides the size and place of the rectangle on the screen; Expand Mode and Stretch Mode decide how the picture fills that rectangle. Without Full Rect the rectangle stays small in the top left corner, and the picture covers only that small rectangle.

   Shortcut for the same thing: with a Control selected, the viewport toolbar shows a button with a green anchor icon; its menu has **Full Rect** too.

**Logo and reel frame**

These are placed at a fixed point, so they are **Sprite2D** nodes. Godot creates one when you drag a picture into the viewport.
A **Sprite2D** belongs to the other family, **Node2D**: nodes placed at an x, y point, like objects in a game world. A Sprite2D draws its picture centered on that point. Use it when you know exactly where something goes and it never needs to adapt to a layout.

7. Select `Main` in the Scene dock (so the new nodes go under it).
8. Drag `PNG/logo/logo_long.png` from the FileSystem dock into the middle of the viewport. A node `LogoLong` appears.
9. In the Inspector, section **Node2D**, open **Transform** and type (**[mouse]**: drag it to the top center and scale it by a corner handle):
   - **Position** x `1166`, y `138`.
     Where the center of the picture goes, in pixels of the 1920 × 1080 screen, counted from the top left corner (y grows downward).
   - **Scale** x `0.34` (y follows, because the chain icon links them).
     A size multiplier: `1` is the picture's real size, `0.34` is 34% of it. The pack's art is drawn large, so it is scaled down.
10. Repeat 7 to 9 for the reel frame. Its position is **[mouse]**, but type the scale `0.55`: it sets the size of the window the reels fit into in step 7.

| Picture | Position | Scale |
| --- | --- | --- |
| `PNG/logo/logo_long.png` | 1166, 138 | 0.34 |
| `PNG/reel/reel_frame_filled.png` | 1170, 571 | 0.55 |

11. Save.

## 4. Animated Anubis

The pack's Anubis animation is in Spine format, a tool for animating characters. Godot cannot play it directly, so a script renders it once into a sequence of pictures. The Spine runtime used for that requires your own Spine Editor license; without one, use a Sprite2D with `PNG/characters/anubis_frame.png` at 243, 742, scale 0.5 instead, and leave out the Anubis lines in step 9.

**Bake the frames**

1. Double click `tools/bake_anubis.gd`. It opens in the Script editor.
2. Script editor menu **File > Run** (Cmd+Shift+X / Ctrl+Shift+X).
   Runs the script inside the editor, as a tool, instead of as part of the game.
3. A folder picker opens: choose the pack folder `RSG-Slot-Asset-Pack-Crowns-of-Kemet-Free` (the one that contains `Spine`), **Open**.
4. Your browser opens a page and renders the animation. After about 10 seconds the **Output** panel says `Done: 110 frames`. You can close the browser tab. The frames are in `res://art/anubis`.

**Place Anubis**

5. Click **2D**. Select `Main` and add a child **AnimatedSprite2D**. Rename it to `Anubis`. Right click > **Access as Unique Name**.
   An **AnimatedSprite2D** is a Sprite2D that plays a sequence of pictures, like a flip book. The unique name is for the script in step 9.
6. In the FileSystem dock open `art/anubis` and double click `anubis_frames.tres` once (this makes the editor load it).
7. Select `Anubis`. Inspector, section **AnimatedSprite2D**:
   - **Sprite Frames**: drag `art/anubis/anubis_frames.tres` onto it.
     A **SpriteFrames** resource holds named animations, each a list of pictures and a speed. The bake created two: `idle` (breathing, loops) and `action` (plays once).
   - **Animation**: `idle`.
     Which of those animations is shown.
8. Section **Node2D > Transform**: **Position** x `382`, y `580`; **Scale** `1.086` (**[mouse]**: left of the reel frame).
9. The **SpriteFrames** panel opens at the bottom. In its **Animations** list select `idle`, then click the **Autoplay on Load** button (the icon with an **A** and a play arrow, in that panel's toolbar).
    Without it the sprite shows the first frame frozen. With it, `idle` starts by itself when the scene loads.
10. Save.

## 5. Symbol scene

One symbol of the reel, with a small pulse animation for wins. It is its own scene so we can reuse it 45 times.

1. Click the **+** tab at the top of the viewport (next to `main`). A new empty scene opens.
2. In the Scene dock click **Other Node**, search **TextureRect**, **Create**. Rename it to `Symbol`.
3. Inspector, section **TextureRect**:
   - **Texture**: drag `PNG/symbols/high/high_ankh.png`.
     Only a placeholder so we can see something; the reel script swaps the picture at run time.
   - **Expand Mode**: `Ignore Size`.
   - **Stretch Mode**: `Keep Aspect Centered`.
     Here we want the whole symbol visible, never cut, so it fits inside the cell keeping its proportions (see step 3.5 for the other modes).
4. Inspector, section **Control > Layout**:
   - **Custom Minimum Size** x `152`, y `151`.
     The smallest size this Control may have. Containers (step 6) give each child at least this size, so this is what makes every cell of the reel 152 × 151.
   - Open **Transform** (inside Layout) and set **Pivot Offset** x `76`, y `75.5`.
     The pivot is the point the node scales and rotates around, measured from its top left corner. By default it is the corner, so a scale would grow toward the bottom right. Half of 152 × 151 puts it at the center, so the symbol pulses in place.
5. With `Symbol` selected, add a child **AnimationPlayer**.
   An **AnimationPlayer** stores animations and plays them. An animation here is a list of property changes over time, for example "Scale goes from 1 to 1.12 and back in 0.6 seconds". It can animate almost any property you see in the Inspector.
6. Save as `symbol.tscn`.

**The `win` animation**

7. Select `AnimationPlayer`. The **Animation** panel opens at the bottom.
8. In that panel click the **Animation** button > **New**. Name `win`, **OK**.
   The name is how code plays it later: `play("win")`.
9. At the right end of the panel's toolbar there is a time field next to a clock icon: the animation length. Set it to `0.6`.
   The total duration in seconds.
10. Select `Symbol` in the Scene dock (the Animation panel stays open).
11. Inspector, **Control > Layout > Transform**: next to **Scale** there is a small key icon. Click it. A dialog asks to create a new track: click **Create**. A diamond (keyframe) appears at time 0 with scale 1.
    A **keyframe** records "at this time, this property has this value". A **track** is the row that holds the keyframes of one property. Between two keyframes Godot fills in the values by itself, so three keys make a smooth pulse.
12. In the Animation panel, the field at the left of its toolbar is the playhead time. Type `0.3`, Enter.
    The playhead is the current time of the animation; the next key you click is recorded there.
13. Set **Scale** to `1.12` and click the key icon again.
14. Playhead `0.6`, **Scale** `1`, key icon.
15. Click the play button in the Animation panel: the symbol pulses. Save.

## 6. Reel scene

A reel is a column of 9 symbols behind a window that shows 3. The animations move the column.

1. **+** tab for a new scene. **Other Node** > **Control** > **Create**. Rename it to `Reel`.
   A plain **Control** draws nothing; it is a rectangle that holds and positions its children. Here it is the window of the reel.
2. Inspector, **Control > Layout**:
   - **Custom Minimum Size** x `152`, y `453` (3 symbols tall).
   - **Clip Contents**: **On**.
     Children are normally drawn even outside their parent's rectangle. With clipping on, anything outside it is hidden. This is what turns the long column into a 3-symbol window.
3. With `Reel` selected, add a child **VBoxContainer**. Rename it to `Strip`.
   A **VBoxContainer** stacks its children vertically, one under the other, and sizes them for you (using their Custom Minimum Size). You never position the symbols by hand. Its sibling **HBoxContainer** does the same side by side.
4. Inspector, section **Control**, open **Theme Overrides > Constants**. Turn on the checkbox of **Separation** and set it to `0`.
   The **theme** holds the default look of every Control (gaps, fonts, colors). A **Theme Override** changes one of those values for this node only. **Separation** is the gap between the stacked children; the default leaves a few pixels, and the symbols must touch.
5. Drag `symbol.tscn` from the FileSystem dock onto `Strip` in the Scene dock. A `Symbol` appears under `Strip`.
   This places the whole symbol scene, with its animation, as one node. Changing `symbol.tscn` later changes every copy.
6. Select that `Symbol` and press Cmd+D / Ctrl+D 8 times. You now have `Symbol` to `Symbol9`.
7. Select `Strip`. Inspector, **Control > Layout > Transform > Position** y `-906`.
   Position of the column relative to the window. 906 is 6 symbols of 151, so the column is pulled up until its last 3 symbols are the ones inside the window.

   The Position field is editable here, even inside a container, because `Strip`'s parent is a plain Control, not a container.
8. Select `Reel`, add a child **AnimationPlayer**. Save as `reel.tscn`.

**The `spin` animation**

9. Select `AnimationPlayer`. Animation panel > **Animation** > **New**: `spin`.
10. Length `0.45`. Click the loop button next to the length field (two arrows in a circle) so it is on.
    With loop on, the animation restarts by itself when it reaches the end, until code stops it. That is the endless spinning.
11. Select `Strip`. Inspector, **Layout > Transform**, key icon next to **Position** > **Create**. Key at 0 with y `-906`.
12. Playhead `0.45`. **Position** y `0`, key icon.
    The column slides down 6 symbols in 0.45 s and jumps back. The script makes the top 3 symbols equal to the bottom 3, so the jump is invisible and the loop looks endless.

**The `stop` animation**

13. Select `AnimationPlayer`. **Animation** > **New**: `stop`. Length `0.3` (loop off).
    Plays once and ends: the landing.
14. Select `Strip`. Playhead `0`, **Position** y `-836`, key icon > **Create**.
15. Playhead `0.15`, y `-926`, key icon.
16. Playhead `0.3`, y `-906`, key icon.
    The column comes in a little low, goes 20 pixels past its rest position, and settles at `-906`: a small bounce, like a real reel stopping.

**The script**

17. Select `Reel`. At the top of the Scene dock click the **Attach Script** icon (a scroll with a green +). Path `res://reel.gd`, **Create**. The Script editor opens.
    A script adds behavior to a node: here, picking random symbols and playing `spin` and `stop`.
18. Select all the text (Cmd+A / Ctrl+A), paste **snippets/01_reel.gd**, save (Cmd+S / Ctrl+S).
19. Click **2D** at the top. Select `Reel`. The Inspector now shows a **Symbols** field at the top. Click it, set **Size** to `5`, and drag one picture into each slot, in this order:
    The script declares this field with `@export`, which makes it show up in the Inspector. The code stays generic and you pick the pictures in the editor. **Size** is how many entries the list has.
   - 0: `PNG/symbols/high/high_ankh.png`
   - 1: `PNG/symbols/high/high_eye.png`
   - 2: `PNG/symbols/high/high_necklace.png`
   - 3: `PNG/symbols/high/high_scarab.png`
   - 4: `PNG/symbols/wild/wild.png`
20. Save.

## 7. Reels in the main scene

1. Click the `main` tab at the top of the viewport.
2. Select `Main`, add a child **HBoxContainer**. Rename it to `Reels`. Right click > **Access as Unique Name**.
   An **HBoxContainer** lines up its children side by side, left to right. It will hold the five reels.
   The unique name is because the main script (step 8) reaches the reels as `%Reels`. Without the `%` mark, the script would fail with "node not found" when you press SPIN.
3. Inspector, **Control > Layout > Transform**: **Size** x `762`, y `453`; **Position** x `796`, y `357`. It now sits over the window of the reel frame (**[mouse]**: drag it onto the window after item 5; the size comes from the five reels by itself).
   With Layout Mode `Position` (the default here), **Position** is the top left corner and **Size** the width and height, in screen pixels. 762 is 5 reels of 152 plus rounding.
4. **Control > Theme Overrides > Constants > Separation**: on, `0`.
5. Drag `reel.tscn` from the FileSystem dock onto `Reels` in the Scene dock. Select the new `Reel` and press Cmd+D / Ctrl+D 4 times. Five reels fill the window.
6. Save.

## 8. Spin button and first spin

1. Select `Main`, add a child **Button**. Rename it to `SpinButton`. Right click > **Access as Unique Name**.
   A **Button** is a clickable Control. When clicked it emits a signal (item 6).
2. Inspector, section **Button**: **Text** `SPIN`.
3. **Control > Layout > Transform**: **Size** x `220`, y `90`; **Position** x `850`, y `960` (**[mouse]**: under the reels). **Control > Theme Overrides > Font Sizes > Font Size**: on, `44`.
   A **Theme Override** changes one value of the default look for this node only; here, a bigger text.
4. Select `Main`. **Attach Script** > path `res://main.gd` > **Create**. Select all, paste **snippets/02_main.gd**, save.
5. Click **2D**. Select `SpinButton`. On the right, click the **Signals** tab (next to Inspector).
   A **signal** is a message a node sends when something happens to it: a button was pressed, an animation finished. Connecting a signal tells Godot which function to call when it happens, without the button knowing anything about the game.
6. Under **BaseButton**, double click **pressed()**. In the dialog, `Main` is selected and the method is `_on_spin_button_pressed`. Click **Connect**.
   `pressed()` is sent on every click. The function with that name already exists in the script you pasted.
7. Run: Cmd+B / F5. Godot asks for a main scene: click **Select Current**.
   The main scene is the one the game starts with.
8. Click **SPIN**: the reels spin and stop left to right. Close the game window.

## 9. Pay the lines

1. Click **Script**, open `main.gd`. Find `func pay() -> int:` and the `return 0` below it. Select those two lines and paste **snippets/03_pay.gd** over them. Save.
2. Click **2D**. Select `Main`. The Inspector now shows a **Wild** field: drag `PNG/symbols/wild/wild.png` onto it. Save.
   To check a line, the script compares the pictures on it: same picture, same symbol. The wild is the exception, it matches any symbol, so the script needs to know which picture is the wild. The pasted code declares `@export var wild: Texture2D`, an empty picture field that shows up in the Inspector, and here you fill it. The code never mentions a file name, so changing the wild art later needs no code change.
3. Select `Anubis`, tab **Signals**. Under **AnimatedSprite2D** double click **animation_finished()**. **Connect**.
   Sent when an animation that does not loop reaches its end. The pasted code plays `action` on every win; this connection calls `_on_anubis_animation_finished`, which puts Anubis back on `idle`.
4. Save and run. Each row is a line (the line bet is 10): 3, 4 or 5 equal symbols from the left pay 2×, 5× or 10× the line bet, and the wild counts as anything. The win is printed in the **Output** panel. On a win, the winning symbols pulse with the `win` animation from step 5 and Anubis plays its action.
