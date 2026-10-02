extends CharacterBody2D

#==================	Referencias ==================
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
#Vamos declarar uma varivel com o nome ANIM, do tipo AnimatedSprite2D e vamos buscar na arvore de nó o AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
#Quando terminar de carregar todos os nos vai buscar a variavel do tipo animatedspritee2d 
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var left_wall_detector: RayCast2D = $LeftWallDetector
@onready var right_wall_detector: RayCast2D = $RightWallDetector
@onready var reload_timer: Timer = $ReloadTimer
#===========	Valores Padrões ==============#
#obs: Posso alterar esses valores para valores especificos para cada fase sem alterar o padrao
@export var  max_jump_count = 2
@export var max_speed = 150.0
@export var acceleration = 225
@export var deceleration = 225
@export var slide_deceleration = 100
@export var wall_acceleration = 40
@export var wall_jump_velocity = 150
@export var water_acceleration = 200
@export var water_max_speed = 100
@export var water_jump_force = -150

const JUMP_VELOCITY = -300.0
var jump_count = 0
var direction = 0
var status: PlayerState

enum PlayerState {
	idle,
	walking,
	jumping,
	falling,
	duck,
	wall,
	slide,
	swimming,
	hurt
}
func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
		
	match status:		#Vai alternar entre os tres fluxos 
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walking:
			walking_state(delta)
		PlayerState.jumping:
			jumping_state(delta)
		PlayerState.falling:
			falling_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.slide:
			slide_state(delta)
		PlayerState.hurt:
			hurt_state(delta)
		PlayerState.wall:
			wall_state(delta)
		PlayerState.swimming:
			swimming_state(delta)
		
	move_and_slide()

#===========================================================================================================================#
#Funçoes que preparam / rodam 1 vez	
func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")

func go_to_walking_state():
	status = PlayerState.walking
	anim.play("walking")

func go_to_jumping_state():
	status = PlayerState.jumping
	anim.play("jumping")
	velocity.y = JUMP_VELOCITY
	jump_count += 1

func go_to_falling_state():
	status = PlayerState.falling
	anim.play("falling")

func go_to_duck_state():
	status = PlayerState.duck
	anim.play("duck")
	set_small_collider()
	
func exit_duck_state():
	set_normal_collider()
	
func go_to_slide_state():
	status = PlayerState.slide
	anim.play("slide")
	set_small_collider()
	
func exit_slide_state():
	set_normal_collider()

func go_to_hurt_state():
	if status == PlayerState.hurt: 
		return
		
	status = PlayerState.hurt
	anim.play("hurt")
	velocity = Vector2.ZERO
	set_small_collider()
	reload_timer.start()
	
func go_to_wall_state():
	status = PlayerState.wall
	anim.play("wall")
	velocity = Vector2.ZERO
	jump_count = 0

func go_to_swimming_state():
	status = PlayerState.swimming
	anim.play("swimming")
	velocity.y = min(velocity.y, 150)
#===========================================================================================================================#
#Funções que rodam infinitamente ate que o estado (state) seja trocado!
func idle_state(delta):
	apply_gravity(delta)
	move(delta)
	if Input.is_action_just_pressed("jump"):
		go_to_jumping_state()
		return
		
	if velocity.x != 0 :		#Se a velocidade for diferente de zero ela chama a função de andar
		go_to_walking_state()
		return
		
	if Input.is_action_pressed("duck"):
		go_to_duck_state()
		return
	
func walking_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if velocity.x == 0:
		go_to_idle_state()
		return
	if Input.is_action_just_pressed("jump"):
		go_to_jumping_state()
		return
	if Input.is_action_just_pressed("duck"):
		go_to_slide_state()
		return
		
	if !is_on_floor(): #Animaçao para de queda quando ele anda e cai de alguma plataforma
		jump_count +=1
		go_to_falling_state()
		return

func jumping_state(delta):
	apply_gravity(delta)
	move(delta)
	#Codigo de doublejump
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jumping_state()
		return
	if velocity.y > 0 :
		go_to_falling_state()
		return
	
func falling_state(delta):
	apply_gravity(delta)
	move(delta)
	#Codigo de doublejump
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jumping_state()
		return
		
	if is_on_floor():
		jump_count = 0
		if velocity.x == 0:
			go_to_idle_state()
			return
		else:
			go_to_walking_state()
			return
	
	if (left_wall_detector.is_colliding() or right_wall_detector.is_colliding()) && is_on_wall():
		go_to_wall_state()
		return

func duck_state(delta):
	apply_gravity(delta)
	update_direction()
	if Input.is_action_just_released("duck"):
		exit_duck_state()
		go_to_idle_state()
		return

func slide_state(delta):	#Por enquanto ele nao pode mover enquando esta escorregando, ou seja nn pode ter o move()
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, slide_deceleration * delta)
	if Input.is_action_just_released("duck"):
		exit_slide_state()
		go_to_walking_state()
		return
	if velocity.x == 0: 
		exit_slide_state()
		go_to_duck_state()
		return

func hurt_state(delta):
	apply_gravity(delta)
	pass
	
func wall_state(delta):
	velocity.y += wall_acceleration * delta
	#Vamos atualizar a direçao na parede desse jeito, diferente do update direction que atualiza usando as teclas direita e esquerda
	if left_wall_detector.is_colliding():
		anim.flip_h = false
		direction = 1
	elif right_wall_detector.is_colliding():
		anim.flip_h = true
		direction = -1
	else:
		go_to_falling_state()
		return 
		
	if is_on_floor():
		go_to_idle_state()
		return
	if Input.is_action_just_pressed("jump") :
		go_to_jumping_state()
		velocity.x = wall_jump_velocity * direction 
		return
		
func swimming_state(delta):
	update_direction()
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, water_max_speed * direction, water_acceleration * delta )
	else:
		
		velocity.x = move_toward(velocity.x, 0, water_acceleration  * delta )
	var vertical_direction = Input.get_axis("up", "down")
	
	velocity.y += water_acceleration * delta
	velocity.y = min(velocity.y, water_max_speed)
	
	if Input.is_action_pressed("up"):
		velocity.y = water_jump_force
	elif Input.is_action_pressed("down"):
		velocity.y = water_jump_force * -1
	
	
#===========================================================================================================================#
func move(delta):
	update_direction()
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
								#Velocidade atual,  Velocidade que querermos chegar, Acelerar
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
								#Velocidade atual,  Velocidade que querermos chegar, Desacelerar
func update_direction():
	direction = Input.get_axis("left", "right")
	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false

func apply_gravity(delta):
	if not is_on_floor(): #Adiciona gravidade ao Player
		velocity += get_gravity() * delta

func can_jump() ->bool:
	return jump_count < max_jump_count
	
func set_small_collider(): #Setar o tamanho da hitbox para menor
	collision_shape.shape.radius = 5
	collision_shape.shape.height = 10
	collision_shape.position.y = 3
	
	hitbox_collision_shape.shape.size.y = 10
	hitbox_collision_shape.position.y = 3

func set_normal_collider(): #Setar o tamanho da hitbox para normal
	collision_shape.shape.radius = 6
	collision_shape.shape.height = 16
	collision_shape.position.y = 0
	
	hitbox_collision_shape.shape.size.y = 15
	hitbox_collision_shape.position.y = 0.5
	

#Função de hitbox para reconhecer quando o player atinge  um inimigo, podendo matar o inimigo ou morrer por ele!
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LethalArea"):
		hit_lethal_area()
		
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		go_to_hurt_state()
	elif body.is_in_group("Water"):
		go_to_swimming_state()
	
func hit_enemy(area: Area2D):	
#***TEMPORARIA**
	if velocity.y>0:	#Verifica se o player ta caindo ( O VETOR DE VELOCIDADE AUMENTA PARA BAIXO) #queue_Free() libera memoria / "mata o inimigo"
		#inimgo morre
		area.get_parent().take_damage()
		go_to_jumping_state()
	else:
		#player morre
		if status!= PlayerState.hurt:
			go_to_hurt_state()

func hit_lethal_area():
	go_to_hurt_state()
	
	
func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()
	set_normal_collider()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Water"):
		jump_count = 0
		go_to_jumping_state() # Replace with function body.
