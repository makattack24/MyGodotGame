# NPC Shop System Setup Guide

## Overview
I've created a complete NPC shop system for your Godot game, similar to Terraria's NPC mechanics. Here's what was added:

## New Files Created

### Scripts:
- `Scripts/npc.gd` - NPC behavior with wandering AI and shop interaction
- `Scripts/shop_ui.gd` - Shop interface for buying items with coins
- `Scripts/npc_spawner.gd` - Spawns NPCs at random positions around the player

### Scenes:
- `Scenes/npc.tscn` - NPC character scene
- `Scenes/shop_ui.tscn` - Shop UI overlay
- `Scenes/npc_spawner.tscn` - Spawner node

## Setup Instructions

### 1. Add NPC Spawner to Main Scene
Open `Scenes/Main.tscn` in Godot and:
1. Add the `npc_spawner.tscn` as a child node to your Main scene
2. The spawner will automatically create 3 NPCs around the player

### 2. Configure NPC Sprites (Important!)
The NPC scene needs animations to work properly:

**Option A: Use Player Sprites (Quick Test)**
1. Open `Scenes/npc.tscn`
2. Select the `AnimatedSprite2D` node
3. In the Inspector, set the `Sprite Frames` property to the same SpriteFrames used by your player
4. NPCs will use the same animations as your player

**Option B: Create Custom NPC Sprites**
1. Create new sprite frames for NPCs in the Godot editor
2. Add animations: `idle_down`, `idle_up`, `idle_left`, `idle_right`, `run_down`, `run_up`, `run_left`, `run_right`
3. Assign to the NPC's AnimatedSprite2D

### 3. How It Works

**NPC Behavior:**
- NPCs spawn at random positions 200-400 pixels from the player
- They wander around their spawn point with idle/walking states
- When the player gets close (within 50 pixels), a yellow "Press E to talk" prompt appears
- NPCs have different names and sell different items at different prices

**Shop System:**
- Press **E** when near an NPC to open their shop
- The shop shows:
  - NPC's name
  - Your current coin count
  - Available items with icons and prices
  - Buy buttons for each item
- Click "Buy" to purchase items (if you have enough coins)
- The shop pauses the game while open
- Press **ESC** or click "Close" to exit the shop

**Default NPC Types:**
1. **Merchant Tom** - Sells: wood (5 coins), axe (50 coins), saw_mill (100 coins)
2. **Trader Sarah** - Sells: wood (3 coins), coin (1 coin), axe (45 coins)
3. **Vendor Mike** - Sells: saw_mill (120 coins), wood (7 coins), axe (60 coins)

### 4. Customization

**To add more items to shops:**
Edit `Scripts/npc_spawner.gd` and modify the `npc_types` array:
```gdscript
var npc_types = [
    {
        "name": "Your NPC Name",
        "items": {
            "item_name": price_in_coins,
            "another_item": price
        }
    }
]
```

**To change spawn settings:**
Open `Scripts/npc_spawner.gd` and adjust:
- `max_npcs` - Maximum number of NPCs (default: 3)
- `spawn_radius_min/max` - Distance from player (default: 200-400 pixels)
- `spawn_check_interval` - How often to check for respawning (default: 5 seconds)

**To customize individual NPCs:**
Open `Scenes/npc.tscn` and modify:
- `npc_name` - The NPC's display name
- `shop_items` - Dictionary of items and prices
- `move_speed` - How fast the NPC walks (default: 30)
- `wander_radius` - How far from spawn point they wander (default: 100)

### 5. Testing
1. Run your game
2. Wait a moment for NPCs to spawn around you
3. Walk near an NPC (you'll see "Press E to talk")
4. Press **E** to open the shop
5. Collect coins (from coin pickups in your game)
6. Return to the shop and buy items!

## Features Included

✅ Multiple NPC types with different inventories  
✅ Random spawning around player  
✅ NPC wandering AI  
✅ Interaction prompts  
✅ Full shop UI with item icons  
✅ Coin-based transactions  
✅ Purchase feedback (success/failure)  
✅ Pause game during shopping  
✅ Automatic NPC respawning  

## Notes

- NPCs use the existing Inventory singleton to handle transactions
- The shop uses your existing item textures defined in `Scripts/inventory.gd`
- Make sure items you want to sell are added to the `item_textures` dictionary in Inventory
- The system integrates with your existing coin pickup system

## Troubleshooting

**NPCs don't appear:**
- Check that `npc_spawner.tscn` is added to your Main scene
- Make sure the player is in the "Player" group

**Shop doesn't open:**
- Verify the NPC has sprite animations configured
- Check console for errors

**NPCs appear as white squares:**
- The AnimatedSprite2D needs sprite frames assigned
- Follow the "Configure NPC Sprites" section above

**Items don't show in shop:**
- Ensure items are defined in `Inventory.item_textures` dictionary
- Check that item names match exactly (case-sensitive)
