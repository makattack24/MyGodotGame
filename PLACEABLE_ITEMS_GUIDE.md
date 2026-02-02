# How to Add Wall as a Placeable Item

## Step 1: Create the Wall Scene

1. In Godot, create a new scene: **Scene → New Scene**
2. Add **StaticBody2D** as root (name it "Wall")
3. Add child nodes:
   - **Sprite2D**
   - **CollisionShape2D**

4. **Configure Sprite2D**:
   - Click on Sprite2D node
   - In Inspector, set **Texture** to your fence/wall sprite sheet PNG
   - Check the **Region** checkbox (Region → Enabled)
   - Click **Edit Region** button
   - In the region editor, select the wall tile from your sprite sheet by clicking and dragging
   - The Region Rect will show the pixel coordinates (e.g., Rect2(0, 0, 16, 16))

5. **Configure CollisionShape2D**:
   - Select CollisionShape2D
   - Set **Shape** to RectangleShape2D
   - Adjust size to match your wall sprite

6. **Save** as `Scenes/wall.tscn`

## Step 2: Link Wall Scene in Player Script

Open `Scripts/player.gd` and find this line (around line 58):

```gdscript
var placeable_scenes: Dictionary = {
    "saw_mill": preload("res://Scenes/saw_mill_machine.tscn"),
    "wall": null,  # Change this line
    "fence": null
}
```

Change to:
```gdscript
var placeable_scenes: Dictionary = {
    "saw_mill": preload("res://Scenes/saw_mill_machine.tscn"),
    "wall": preload("res://Scenes/wall.tscn"),  # Add your scene here
    "fence": null
}
```

## Step 3: Add Wall Icon to Inventory

You have two options:

### Option A: Use a separate wall icon PNG
If you have a separate icon image, just make sure it's at `Assets/WallItem.png` (already configured in inventory.gd)

### Option B: Use region from sprite sheet
Open `Scripts/inventory.gd` and in the `_ready()` function, add:

```gdscript
func _ready() -> void:
    add_to_group("persist")
    
    # Add wall texture from sprite sheet
    # Replace coordinates with your wall tile position
    item_textures["wall"] = create_atlas_texture(
        "res://Assets/your_fence_wall_sheet.png",
        Rect2(0, 0, 16, 16)  # x, y, width, height of wall tile
    )
```

## Step 4: Test It!

1. Run the game
2. Select "wall" from your inventory (scroll with mouse wheel)
3. Press **B** to enter build mode
4. Left-click to place walls
5. Right-click to cancel build mode

## Adding More Placeable Items (Fence, etc.)

Just repeat these steps for each item:
1. Create the scene (fence.tscn)
2. Add to `placeable_scenes` dictionary in player.gd
3. Add texture to inventory.gd (either preload or atlas texture)
4. Make sure the item is in the `inventory` dictionary with a starting count

That's it!
