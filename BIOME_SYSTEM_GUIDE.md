# Biome System Guide

## Overview
Your game now has a comprehensive biome system that creates different areas as the player moves away from their spawn point. Each biome has unique characteristics including:
- Different ground tiles
- Varied tree density
- Different enemy spawn rates and difficulty
- Unique visual tinting

## How It Works

### Distance-Based Biome Rings
Biomes are organized in concentric rings based on distance from the spawn point:

1. **Starter Plains (0-300 units)**
   - Safe starting area
   - Low enemy spawn rate (2 enemies per camp)
   - Moderate tree density (30%)
   - Bright, welcoming appearance

2. **Forest Zone (300-600 units)**
   - Light forest mixing with plains
   - Moderate enemy presence (3 enemies per camp)
   - Higher tree density (60%)
   - Slight green tint

3. **Mixed Wilderness (600-1000 units)**
   - Forest, Dense Forest, and Taiga biomes
   - Increased danger (3-4 enemies per camp)
   - Varied tree coverage (50-80%)

4. **Challenging Regions (1000-1500 units)**
   - Dense Forest, Swamp, Taiga, and Desert
   - Higher enemy spawns (3-4 enemies per camp)
   - Biome-specific characteristics

5. **Dangerous Frontier (1500-2500 units)**
   - Swamp, Desert, Tundra, and Cave entrances
   - High enemy presence (4-6 enemies per camp)
   - Harsh environments

6. **End-Game Areas (2500+ units)**
   - Cave, Tundra, and Desert biomes
   - Maximum difficulty (6 enemies per camp)
   - Sparse resources, high danger

### Biome Types

#### Starter Plains
- **Purpose**: Safe starting zone
- **Trees**: 30% spawn chance
- **Enemies**: 10% spawn chance, 2 per camp
- **Visual**: Standard grassland tiles

#### Forest
- **Purpose**: First expansion area
- **Trees**: 60% spawn chance, closer spacing
- **Enemies**: 30% spawn chance, 3 per camp
- **Visual**: Green tint

#### Dense Forest
- **Purpose**: Resource-rich but dangerous
- **Trees**: 80% spawn chance, very dense
- **Enemies**: 40% spawn chance, 4 per camp
- **Visual**: Deeper green tint

#### Swamp
- **Purpose**: Murky, challenging terrain
- **Trees**: 40% spawn chance
- **Enemies**: 50% spawn chance, 4 per camp
- **Visual**: Murky green-brown tint

#### Taiga
- **Purpose**: Cool forest transition
- **Trees**: 50% spawn chance
- **Enemies**: 30% spawn chance, 3 per camp
- **Visual**: Cool blue-white tint

#### Desert
- **Purpose**: Sparse, open danger
- **Trees**: 10% spawn chance, wide spacing
- **Enemies**: 40% spawn chance, 3 per camp
- **Visual**: Sandy yellow tint

#### Tundra
- **Purpose**: Cold, hostile environment
- **Trees**: 20% spawn chance
- **Enemies**: 60% spawn chance, 5 per camp
- **Visual**: Cold blue tint

#### Cave
- **Purpose**: End-game challenge
- **Trees**: 5% spawn chance
- **Enemies**: 70% spawn chance, 6 per camp
- **Visual**: Dark, rocky tint

## Customization

### Modifying Biome Properties

Edit `Scripts/biome_manager.gd` to customize biome behavior:

```gdscript
var biome_data: Dictionary = {
    BiomeType.FOREST: {
        "name": "Forest",
        "ground_tiles": [...],          # Atlas coordinates for tiles
        "tree_spawn_chance": 0.6,       # 0.0 to 1.0
        "min_tree_spacing": 45.0,       # Pixels between trees
        "enemy_spawn_chance": 0.3,      # 0.0 to 1.0 (currently unused)
        "enemies_per_camp": 3,          # Number of enemies
        "color_tint": Color(...)        # Visual tint
    }
}
```

### Changing Distance Rings

Modify the `biome_rings` array to change when biomes appear:

```gdscript
var biome_rings: Array[Dictionary] = [
    {"min_distance": 0,    "max_distance": 300,  "biomes": [BiomeType.STARTER]},
    {"min_distance": 300,  "max_distance": 600,  "biomes": [BiomeType.FOREST]},
    # Add or modify rings as needed
]
```

### Adding New Biome Types

1. Add new biome to the `BiomeType` enum:
```gdscript
enum BiomeType {
    STARTER,
    FOREST,
    MY_NEW_BIOME  # Add here
}
```

2. Add configuration to `biome_data`:
```gdscript
BiomeType.MY_NEW_BIOME: {
    "name": "My Biome",
    "ground_tiles": [Vector2i(x, y)],
    # ... other properties
}
```

3. Add to appropriate distance ring:
```gdscript
{"min_distance": 1000, "max_distance": 1500, 
 "biomes": [BiomeType.MY_NEW_BIOME, BiomeType.FOREST]}
```

## Using Different Tilesets

The biome system uses atlas coordinates from your tileset. To use tiles from the different biome folders in `Assets/FreeDownloadedAssets/fantasy_ [version 2.0]/`:

1. Import the biome tilesets into Godot
2. Note the atlas coordinates for the tiles you want
3. Update the `ground_tiles` array in `biome_data` for each biome type

Example:
```gdscript
"ground_tiles": [
    Vector2i(0, 0),  # First tile
    Vector2i(1, 0),  # Second tile
    Vector2i(0, 1),  # Third tile
]
```

## Features

### Automatic Biome Detection
The system automatically:
- Detects which biome the player is in
- Updates ground tiles based on location
- Adjusts tree spawning density and spacing
- Modifies enemy spawn rates
- Shows current biome name in the HUD (top-left corner)

### Smooth Transitions
- Biomes blend using noise-based selection when multiple biomes are available in a ring
- No harsh borders between biome types
- Natural-feeling world generation

### Performance Optimized
- Biome checks only happen when needed
- Tile generation is chunked and cached
- Object spawning uses the same optimization as before

## Troubleshooting

### Biomes Not Changing
- Check that BiomeManager is properly added in Main.tscn
- Verify spawn point is set correctly
- Ensure distance rings don't overlap incorrectly

### Wrong Tiles Appearing
- Verify atlas coordinates match your tileset
- Check that SOURCE_ID in ground.gd matches your tileset

### HUD Not Showing Biome
- Ensure HUD scene has the script attached
- Check that Main.gd can find the HUD node
- Verify `update_biome_display` method exists in hud.gd

## Future Enhancements

Consider adding:
- Biome-specific enemies (different slime colors per biome)
- Biome-specific resources (different tree types, rocks, plants)
- Weather effects per biome
- Biome-specific music
- Transition zones between biomes
- Special structures or landmarks in each biome
