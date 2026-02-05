# Enemy System Refactoring Guide

## Overview
Your enemy script has been refactored from **487 lines** into a flexible component-based system that makes it easy to create new enemy types.

## New Architecture

### File Structure
```
Scripts/Enemies/
├── base_enemy.gd              # Base class all enemies extend
├── slime_enemy.gd             # Slime implementation (26 lines!)
├── bat_enemy.gd               # Example second enemy type
├── enemy_data.gd              # Data resource definition
└── Components/
    ├── enemy_health.gd        # Health, damage, loot
    ├── enemy_movement.gd      # Base movement AI
    ├── slime_hop_movement.gd  # Slime hopping behavior
    └── chase_movement.gd      # Simple chase behavior

Resources/EnemyData/
├── green_slime_data.tres      # Slime configuration
└── bat_data.tres              # Bat configuration
```

## How It Works

### 1. **EnemyData Resource**
Configure enemy stats without touching code:

```gdscript
@export var enemy_name: String = "Enemy"
@export var max_health: int = 3
@export var move_speed: float = 120.0
@export var aggro_range: float = 200.0
@export var coin_drop_chance: float = 1.0
# ... and more
```

### 2. **BaseEnemy Class**
Core functionality all enemies share:
- Player detection & collision
- Component management
- Attack cooldowns
- Camp/home position

### 3. **Components**
- **EnemyHealth**: Damage, death, loot drops, visual effects
- **EnemyMovement**: Base AI, aggro system, separation
- **SlimeHopMovement**: Hopping behavior for slimes
- **ChaseMovement**: Walking behavior for other enemies

### 4. **Specific Enemy Types**
Just 20-30 lines each!

```gdscript
extends BaseEnemy
class_name SlimeEnemy

func setup_components() -> void:
    health = EnemyHealth.new()
    health.initialize(self, get_node("Sprite2D"), enemy_data)
    add_child(health)
    
    movement = SlimeHopMovement.new()
    movement.initialize(self, enemy_data)
    add_child(movement)
    
    create_shadow()
```

## Creating New Enemy Types

### Method 1: Use Existing Components (Easiest)

1. **Create EnemyData resource:**
```gdscript
# In Godot Editor:
# Right-click Resources/EnemyData folder
# Create New → Resource → EnemyData
# Configure stats in Inspector
```

2. **Create enemy script:**
```gdscript
extends BaseEnemy
class_name SpiderEnemy

func setup_components() -> void:
    health = EnemyHealth.new()
    health.initialize(self, get_node("Sprite2D"), enemy_data)
    add_child(health)
    
    # Use chase movement (already exists!)
    movement = ChaseMovement.new()
    movement.initialize(self, enemy_data)
    add_child(movement)
    
    create_shadow()
```

3. **Create scene:**
- Duplicate `enemy.tscn`
- Change script to `SpiderEnemy`
- Assign your spider EnemyData resource
- Change sprite
- Done!

### Method 2: Custom Movement Component

For unique behaviors:

```gdscript
extends EnemyMovement
class_name TeleportMovement

@export var teleport_cooldown: float = 3.0
var teleport_timer: float = 0.0

func physics_process(delta: float) -> void:
    teleport_timer -= delta
    
    if is_aggro and teleport_timer <= 0:
        # Teleport near player!
        var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
        enemy.global_position = player.global_position + offset
        teleport_timer = teleport_cooldown
    else:
        # Normal movement when not teleporting
        var direction = get_direction_to_player() if is_aggro else get_direction_to_camp()
        enemy.velocity = direction * data.move_speed * 0.5
```

Then use it:
```gdscript
extends BaseEnemy
class_name WizardEnemy

func setup_components() -> void:
    health = EnemyHealth.new()
    health.initialize(self, get_node("Sprite2D"), enemy_data)
    add_child(health)
    
    movement = TeleportMovement.new()  # Your custom movement!
    movement.initialize(self, enemy_data)
    add_child(movement)
```

## Lambda Functions Used

### 1. **Filtering Arrays**
```gdscript
# Old way
var valid_enemies = []
for e in enemies:
    if e != self and is_instance_valid(e):
        valid_enemies.append(e)

# New way
var valid_enemies = enemies.filter(
    func(e): return e != self and is_instance_valid(e)
)
```

### 2. **Cleanup Callbacks**
```gdscript
# Old way - separate function
func cleanup_particle():
    effect.queue_free()
timer.timeout.connect(cleanup_particle)

# New way
timer.timeout.connect(func(): effect.queue_free())
```

### 3. **Conditional Logic**
```gdscript
# Encapsulate complex conditions
var should_aggro = func() -> bool:
    if distance_to_player <= data.aggro_range:
        return true
    if distance_to_camp > data.return_home_range:
        return false
    return is_aggro

is_aggro = should_aggro.call()
```

### 4. **Animation Sequences**
```gdscript
# Clean animation code with lambda
var animate_hop = func():
    var jump_height = sin(hop_progress * PI) * 0.4
    sprite.scale = Vector2(0.65, 0.65) * Vector2(1.0 - jump_height, 1.0 + jump_height)
    sprite.position.y = -jump_height * 8

animate_hop.call()
```

## Example Enemy Types You Can Create

### Fast Runner
```gdscript
# fast_runner_data.tres
move_speed = 200.0  # Fast!
aggro_range = 300.0  # Detects from far
max_health = 1  # But fragile

# Uses ChaseMovement component
```

### Tank
```gdscript
# tank_data.tres
max_health = 10  # Lots of HP
move_speed = 60.0  # Slow
knockback_strength = 500.0  # Hard to push
coin_drop_chance = 1.0
min_coins = 5
max_coins = 10  # Better loot!
```

### Ranged Enemy
Create `RangedMovement` component:
```gdscript
extends EnemyMovement
class_name RangedMovement

@export var attack_range: float = 150.0
@export var retreat_distance: float = 80.0
var projectile_scene = preload("res://Scenes/enemy_projectile.tscn")

func physics_process(delta: float) -> void:
    if not is_aggro or not player:
        return
    
    var distance = get_distance_to_player()
    
    if distance < retreat_distance:
        # Too close! Back away
        var direction = -get_direction_to_player()
        enemy.velocity = direction * data.move_speed
    elif distance > attack_range:
        # Too far! Get closer
        var direction = get_direction_to_player()
        enemy.velocity = direction * data.move_speed * 0.5
    else:
        # Perfect range! Stay still and attack
        enemy.velocity = Vector2.ZERO
```

## Migration from Old Enemy Script

### Option 1: Update Existing Scene
1. Open `enemy.tscn`
2. Change script from `enemy.gd` to `SlimeEnemy`
3. Add `green_slime_data.tres` to `enemy_data` property
4. Test

### Option 2: Create Fresh (Recommended)
1. Create new scene
2. Add CharacterBody2D → SlimeEnemy script
3. Add child nodes:
   - Sprite2D
   - CollisionShape2D
   - HitEffect (CPUParticles2D)
   - DeathEffect (CPUParticles2D)
   - HitSound (AudioStreamPlayer2D)
4. Assign `enemy_data` resource
5. Done!

## Benefits

### 1. **Rapid Enemy Creation**
- New enemy type in **5 minutes**
- No code duplication
- Just configure data + choose components

### 2. **Easy Balancing**
Change stats in EnemyData resource:
```
# Make all slimes tougher:
# Edit green_slime_data.tres
max_health = 5  # Was 3
```

### 3. **Behavior Reuse**
```gdscript
# Both use hopping!
SlimeEnemy → SlimeHopMovement
FrogEnemy → SlimeHopMovement  # Same component!

# Both chase player
BatEnemy → ChaseMovement
WolfEnemy → ChaseMovement  # Reuse!
```

### 4. **Clean Code**
- SlimeEnemy: **26 lines** (was 487!)
- BaseEnemy: **120 lines** (reusable)
- Each component: **100-150 lines** (focused)

## Advanced: Component Signals

Components can communicate:

```gdscript
# In enemy script
func setup_components() -> void:
    movement = SlimeHopMovement.new()
    add_child(movement)
    
    # React to hops!
    movement.hop_started.connect(func(): print("Hop!"))
    movement.hop_finished.connect(func(): _check_landing())
```

## Debugging Tips

### Check Component Setup
```gdscript
func _ready():
    super._ready()
    print("Health component: ", health)
    print("Movement component: ", movement)
    print("Enemy data: ", enemy_data.enemy_name if enemy_data else "MISSING!")
```

### Test in Isolation
```gdscript
# Test movement without health
func setup_components() -> void:
    # health = ...  # Comment out
    movement = ChaseMovement.new()
    # ...
```

## Next Steps

1. **Test SlimeEnemy** with existing slime scene
2. **Create a new enemy** using BatEnemy as template
3. **Design custom movement** for unique enemies
4. **Balance with EnemyData** resources

## Quick Reference

### Create New Enemy Checklist
- [ ] Create EnemyData resource
- [ ] Create enemy script extending BaseEnemy
- [ ] Implement `setup_components()`
- [ ] Choose/create movement component
- [ ] Create scene with required nodes
- [ ] Assign enemy_data in Inspector
- [ ] Test!

Your enemy system is now **modular, scalable, and maintainable**!
