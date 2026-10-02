extends CharacterBody2D

const SPINNING_BONE = preload("uid://ogad336qkacd")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
#Vamos declarar uma varivel com o nome ANIM, do tipo AnimatedSprite2D e vamos buscar na arvore de nó o AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var bone_start_position: Node2D = $BoneStartPosition

enum SkeletonState{
	walk,
	attack,
	hurt
}

const SPEED = 30.0
const JUMP_VELOCITY = -400.0

var status: SkeletonState
var direction = 1
var can_throw = true

#===========================================================================================================================#
func _ready() -> void:
	go_to_walk_state()

func _physics_process(delta: float) -> void:
	# Adiciona gravidade!
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	match status:
		SkeletonState.walk:
			walk_state(delta)
		SkeletonState.hurt:
			hurt_state(delta)
		SkeletonState.attack:
			attack_state(delta)
			
	move_and_slide()

func take_damage():
	go_to_hurt_state()

func throw_bone():
	var new_bone = SPINNING_BONE.instantiate()
	add_sibling(new_bone)
	new_bone.position = bone_start_position.global_position
	new_bone.set_direction(self.direction)
	
func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		go_to_walk_state()
		return

#===========================================================================================================================#
#Funçoes que preparam / rodam 1 vez	
func go_to_walk_state():
	status =SkeletonState.walk
	anim.play("walk")

func go_to_hurt_state():
	status =SkeletonState.hurt
	anim.play("hurt")
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO
	
func go_to_attack_state():
	status = SkeletonState.attack
	anim.play("attack")
	velocity = Vector2.ZERO
	throw_bone()
	can_throw = true
	
#===========================================================================================================================#
#Funções que rodam infinitamente ate que o estado (state) seja trocado!
func walk_state(_delta):
	if anim.frame == 3 or anim.frame == 4:
		velocity.x = SPEED * direction
	else:
		velocity.x = 0
	if wall_detector.is_colliding(): #se o wall_detector  estiver colidindo
		scale.x *=-1
		direction *= -1
	if not ground_detector.is_colliding(): #se o wall_detector  estiver colidindo
		scale.x *=-1
		direction *= -1
	
	if player_detector.is_colliding():
		go_to_attack_state()
		return
		
func hurt_state(_delta):
	pass

func attack_state(_delta):
	if anim.frame == 2 && can_throw:
		throw_bone()
		can_throw = false
