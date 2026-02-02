# How to Set Up Biome Tiles in Godot

## Step 1: Import Your Tileset Images

You have biome assets in `Assets/FreeDownloadedAssets/fantasy_ [version 2.0]/` with folders for:
- `cave_/`
- `desert_/`
- `fantasy_/` (grassland)
- `forest_/`
- `swamp_/`
- `taiga_/`
- `tundra_/`

1. In Godot's **FileSystem** panel, navigate to these folders
2. Click on a PNG file (e.g., a ground tile image)
3. In the **Import** tab (top of screen), make sure it's set to **Texture**
4. Click **Reimport** if needed

## Step 2: Find Your TileMap and TileSet

1. Open your **Main.tscn** scene
2. Select the **Ground** node (should be a TileMapLayer)
3. In the **Inspector** panel, find the **Tile Set** property
4. Click on it to edit the TileSet

## Step 3: Add Biome Tiles to Your TileSet

### Method A: Using the TileSet Editor (Recommended)

1. With your TileSet selected, at the bottom of the editor you'll see the **TileSet** panel
2. Click the **+** button or "Add Texture" 
3. Navigate to one of your biome folders (e.g., `Assets/FreeDownloadedAssets/fantasy_ [version 2.0]/desert_/`)
4. Select a ground tile image (look for files like "desert_ground.png" or similar)
5. Repeat for each biome:
   - Desert tiles from `desert_/`
   - Forest tiles from `forest_/`
   - Swamp tiles from `swamp_/`
   - Taiga tiles from `taiga_/`
   - Tundra tiles from `tundra_/`
   - Cave tiles from `cave_/`

### Method B: If You Already Have a TileSet

If you already have a tileset with multiple textures:
1. Open the **TileSet** editor (bottom panel when TileMapLayer is selected)
2. You should see your tileset atlas/texture
3. Each tile has an **Atlas Coordinate** (like a grid position)

## Step 4: Find Atlas Coordinates for Each Biome

This is the crucial step! You need to identify which tiles belong to which biome.

1. Open your **TileSet** in the editor
2. Look at the grid of tiles
3. Note the **X, Y coordinates** for tiles you want to use
   - The coordinates start at (0, 0) in the top-left
   - X increases going right
   - Y increases going down

**Example:**
```
(0,0)  (1,0)  (2,0)  (3,0)
(0,1)  (1,1)  (2,1)  (3,1)
(0,2)  (1,2)  (2,2)  (3,2)
```

4. For each biome, write down 4-8 tile coordinates that look appropriate:
   - **Grass/Plains**: Green grass tiles
   - **Desert**: Sandy/yellow tiles
   - **Forest**: Dark green/forest floor tiles
   - **Swamp**: Murky/brown/wet tiles
   - **Taiga**: Light forest/snowy grass tiles
   - **Tundra**: Snow/ice tiles
   - **Cave**: Dark/rocky tiles

## Step 5: Update the BiomeManager Script

Open `Scripts/biome_manager.gd` and update the `"ground_tiles"` arrays for each biome.

**Example - If your desert tiles are at coordinates (5,0), (6,0), (5,1), (6,1):**

```gdscript
BiomeType.DESERT: {
    "name": "Desert",
    "ground_tiles": [
        Vector2i(5, 0),  # Sandy tile 1
        Vector2i(6, 0),  # Sandy tile 2
        Vector2i(5, 1),  # Sandy tile 3
        Vector2i(6, 1)   # Sandy tile 4
    ],
    "tree_spawn_chance": 0.02,
    "min_tree_spacing": 80.0,
    "enemy_spawn_chance": 0.4,
    "enemies_per_camp": 3,
    "color_tint": Color(1.0, 0.95, 0.8, 1.0)
}
```

**Full Template:**

```gdscript
BiomeType.STARTER: {
    "name": "Starter Plains",
    "ground_tiles": [
        Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)  # Replace with your grass coordinates
    ],
    ...
},
BiomeType.FOREST: {
    "name": "Forest",
    "ground_tiles": [
        Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)  # Replace with forest coordinates
    ],
    ...
},
BiomeType.DESERT: {
    "name": "Desert",
    "ground_tiles": [
        Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)  # Replace with desert coordinates
    ],
    ...
},
BiomeType.SWAMP: {
    "name": "Swamp",
    "ground_tiles": [
        Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)  # Replace with swamp coordinates
    ],
    ...
},
BiomeType.TAIGA: {
    "name": "Taiga",
    "ground_tiles": [
        Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)  # Replace with taiga coordinates
    ],
    ...
},
BiomeType.TUNDRA: {
    "name": "Tundra",
    "ground_tiles": [
        Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5)  # Replace with tundra coordinates
    ],
    ...
},
BiomeType.CAVE: {
    "name": "Cave Entrance",
    "ground_tiles": [
        Vector2i(0, 6), Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)  # Replace with cave coordinates
    ],
    ...
}
```

## Step 6: Verify SOURCE_ID

In `Scripts/ground.gd`, make sure the `SOURCE_ID` constant matches your tileset:

```gdscript
const SOURCE_ID: int = 0  # Usually 0 for the first/main tileset source
```

If you have multiple texture sources in your TileSet, you might need to change this to 1, 2, etc.

## Quick Method: Use What You Have

If you only have grass tiles right now:

1. **Immediate Solution**: Keep using the same grass tiles for all biomes, but the system will still work with different spawn rates and enemy counts
2. **Future**: When you add new biome tilesets, just update the coordinates in `biome_manager.gd`

## Testing Your Tiles

1. Run your game
2. Walk around - you should see tiles changing based on distance
3. Watch the biome name in the top-left corner
4. If tiles look wrong:
   - Check your atlas coordinates
   - Verify SOURCE_ID matches
   - Make sure tiles exist at those coordinates

## Common Issues

**"I see the wrong tiles"**
- Your atlas coordinates are incorrect
- Solution: Open TileSet editor and double-check the X,Y positions

**"All biomes look the same"**
- You're using the same tile coordinates for all biomes
- Solution: Assign different coordinates to each biome type

**"Tiles are missing/blank"**
- The coordinates point to empty spaces in your atlas
- Solution: Use coordinates where tiles actually exist

**"SOURCE_ID error"**
- You have multiple texture sources in your TileSet
- Solution: Check which source ID your tiles are in (usually 0, 1, or 2)

## Advanced: Creating a Multi-Biome TileSet

For best results, create one large tileset image that contains ALL biome tiles:

1. Use an image editor to combine tiles from different biomes into one PNG
2. Import this as a single texture in your TileSet
3. Now all biomes are in one atlas with easy-to-reference coordinates

Example layout (16x16 pixel tiles):
```
Row 0: Grass tiles (0,0 to 7,0)
Row 1: Forest tiles (0,1 to 7,1)
Row 2: Desert tiles (0,2 to 7,2)
Row 3: Swamp tiles (0,3 to 7,3)
Row 4: Taiga tiles (0,4 to 7,4)
Row 5: Tundra tiles (0,5 to 7,5)
Row 6: Cave tiles (0,6 to 7,6)
```

This makes it much easier to manage coordinates!
