extends CharacterBody2D

@export var SPEED := 300.0
@export var RECOIL_FORCE := 2000.0
@export var FRICTION := 10.0

@onready var ray_cast: RayCast2D = $RayCast2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const HAZARD_LAYER := 2

var is_resetting := false
var spawn_position: Vector2

func _ready() -> void:
	spawn_position = global_position
	ray_cast.collision_mask = 1 | HAZARD_LAYER

	if collision_shape and collision_shape.shape:
		var hurtbox := Area2D.new()
		hurtbox.collision_layer = 0
		hurtbox.collision_mask = HAZARD_LAYER
		
		var shape := CollisionShape2D.new()
		shape.shape = collision_shape.shape.duplicate()
		hurtbox.add_child(shape)
		
		add_child(hurtbox)
		
		# Connect to both bodies and areas to prevent missed hits
		hurtbox.body_entered.connect(_on_hazard_entered)
		hurtbox.area_entered.connect(_on_hazard_entered)

func _physics_process(delta: float) -> void:
	if is_resetting:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	look_at(get_global_mouse_position())

	if Input.is_action_just_pressed("click") and ray_cast.is_colliding():
		launch_backward()

	move_and_slide()

	for i in get_slide_collision_count():
		if _is_hazard_collision(get_slide_collision(i)):
			reset_player()
			break

func _on_hazard_entered(_node: Node) -> void:
	reset_player()

func _is_hazard_collision(collision: KinematicCollision2D) -> bool:
	var collider := collision.get_collider()
	if collider is CollisionObject2D:
		return bool(collider.collision_layer & HAZARD_LAYER)
	
	var rid := collision.get_collider_rid()
	if rid.is_valid():
		var layer := PhysicsServer2D.body_get_collision_layer(rid)
		return bool(layer & HAZARD_LAYER)
		
	return false

func reset_player() -> void:
	if is_resetting:
		return
	is_resetting = true
	# Deferred because this is usually triggered from a physics callback
	call_deferred("_respawn")

func _respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	rotation = 0.0
	is_resetting = false

func launch_backward() -> void:
	var direction_to_mouse := global_position.direction_to(get_global_mouse_position())
	velocity = -direction_to_mouse * RECOIL_FORCE
