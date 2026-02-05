# Player Script Refactoring Guide

## Overview
Your player script has been refactored from **959 lines** to a component-based architecture with **~250 lines** in the main script.

## File Structure

```
Scripts/
├── player.gd (original - 959 lines)
├── player_refactored.gd (new - ~250 lines)
└── PlayerComponents/
    ├── player_combat.gd (~180 lines)
    ├── player_building.gd (~280 lines)
    └── player_vfx.gd (~160 lines)
```

## Components Breakdown

### 1. **PlayerCombat** (`player_combat.gd`)
**Responsibility:** All attack and weapon logic
- Attack animations and hitbox management
- Weapon sprite positioning
- Hit detection for enemies, trees, bushes
- Equipment checking (axe requirement)

### 2. **PlayerBuilding** (`player_building.gd`)
**Responsibility:** Placement/building system
- Build mode toggle and preview
- Grid snapping and validation
- Object placement and pickup
- Build UI management

### 3. **PlayerVFX** (`player_vfx.gd`)
**Responsibility:** Visual effects
- Screen shake
- Screen flashes (red, orange, death)
- Floating damage text
- Heal/damage sprite effects
- Shadow creation

### 4. **Player** (`player_refactored.gd`)
**Responsibility:** Core player logic
- Movement and input
- Health management
- Component coordination
- Save/load

## Lambda Functions Used

### 1. **Signal Connections**
```gdscript
# Old way
anim_sprite.animation_finished.connect(_on_animation_finished)

# New way with lambda
anim_sprite.animation_finished.connect(func(): _on_animation_finished())
```

### 2. **Tween Callbacks**
```gdscript
# Old way - separate function needed
tween.finished.connect(_on_tween_finished)

# New way with lambda
tween.finished.connect(func(): damage_label.queue_free())
```

### 3. **Array Filtering**
```gdscript
# Old way - manual loop
var valid_objects = []
for obj in placed_objects:
    if obj.has_method("pickup_machine") and obj.is_placed:
        valid_objects.append(obj)

# New way with lambda
var valid_objects = placed_objects.filter(func(obj): 
    return obj.has_method("pickup_machine") and obj.is_placed
)
```

### 4. **Array Operations**
```gdscript
# Old way - manual loop
for action in input_actions:
    setup_action(action)

# New way with lambda
input_actions.map(func(action): setup_action(action))
```

### 5. **Conditional Logic Encapsulation**
```gdscript
# Old way - inline conditions
var color
if not within_range:
    color = Color(1, 1, 0.5, 0.7)
elif _is_position_valid(snapped_pos):
    color = Color(0.5, 1, 0.5, 0.7)
else:
    color = Color(1, 0.5, 0.5, 0.7)
placement_preview.modulate = color

# New way with lambda
var get_preview_color = func():
    if not within_range:
        return Color(1, 1, 0.5, 0.7)
    elif _is_position_valid(snapped_pos):
        return Color(0.5, 1, 0.5, 0.7)
    else:
        return Color(1, 0.5, 0.5, 0.7)

placement_preview.modulate = get_preview_color.call()
```

### 6. **Complex Sequences**
```gdscript
# Old way - awkward await chains
if death_sound:
    death_sound.play()
    await death_sound.finished
else:
    await get_tree().create_timer(0.5).timeout
# ... more code

# New way with lambda
var handle_death_sequence = func():
    if death_sound and death_sound.stream:
        death_sound.play()
        await death_sound.finished
    else:
        await get_tree().create_timer(0.5).timeout
    
    await get_tree().create_timer(3.0).timeout
    # ... more sequence logic

handle_death_sequence.call()
```

## Migration Steps

### Step 1: Test the Refactored Version
1. In Godot, open [Scenes/player.tscn](Scenes/player.tscn)
2. Change the script from `player.gd` to `player_refactored.gd`
3. Test all functionality:
   - Movement
   - Combat
   - Building mode
   - Taking damage
   - Healing
   - Death

### Step 2: Backup Original
```powershell
# In your project folder
cp Scripts/player.gd Scripts/player_backup.gd
```

### Step 3: Replace Original
Once testing is complete:
1. Delete `Scripts/player.gd`
2. Rename `Scripts/player_refactored.gd` to `Scripts/player.gd`
3. Update scene reference if needed

## Benefits of This Architecture

### 1. **Separation of Concerns**
Each component has a single, clear responsibility

### 2. **Easier Testing**
Components can be tested independently

### 3. **Better Maintainability**
- Finding code is easier
- Changes are isolated
- Less merge conflicts

### 4. **Reusability**
Components can be reused on other characters:
```gdscript
# Create an NPC with combat but no building
var npc_combat = PlayerCombat.new()
npc.add_child(npc_combat)
npc_combat.initialize(npc, npc.anim_sprite, npc.attack_area)
```

### 5. **Cleaner Code with Lambdas**
- Less function clutter
- Callbacks inline with their usage
- More functional programming style

## Advanced Tips

### 1. **Add More Components**
You could further break down:
- **PlayerInventory** - Inventory management
- **PlayerAudio** - Sound effect management
- **PlayerAnimation** - Animation state machine

### 2. **Use Signals Between Components**
```gdscript
# In PlayerCombat
signal attack_landed(target)

# In Player
combat.attack_landed.connect(func(target): 
    vfx.show_damage_text(1, target.global_position)
)
```

### 3. **Component Configuration**
Add export variables to components:
```gdscript
# In PlayerCombat
@export var attack_damage: int = 1
@export var attack_speed_multiplier: float = 2.0
```

## Lambda Best Practices

### ✅ DO Use Lambdas For:
- One-time callbacks
- Signal connections
- Simple array operations
- Encapsulating small logic blocks

### ❌ DON'T Use Lambdas For:
- Complex logic (>5 lines)
- Reusable functions
- Performance-critical loops
- When you need to disconnect signals

## Performance Notes

Lambda functions in Godot 4.6 are:
- **Lightweight** - No significant overhead
- **Captured variables** - Be careful with references
- **Not serializable** - Can't be saved/loaded

## Next Steps

1. Test the refactored version thoroughly
2. Consider adding unit tests for components
3. Document component APIs
4. Refactor other large scripts using this pattern

## Questions?

Common questions:

**Q: Will this break my saves?**
A: No, the save/load methods are unchanged.

**Q: Can I add more components later?**
A: Yes! Just create the component and add it in `_initialize_components()`

**Q: What about performance?**
A: Component overhead is negligible. The benefits far outweigh any cost.

**Q: Can I mix old and new code?**
A: Yes during migration, but aim for consistency.
