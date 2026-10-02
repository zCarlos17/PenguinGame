extends AnimatableBody2D

@onready var target: Sprite2D = $Target
# Called when the node enters the scene tree for the first time.
@export var time_move = 3
func _ready() -> void:
	#Quando tenho uma pos. inicial e uma pos. final, e precisamos fazer uma "caminho" entre esses pontos usando uma 
	#animaçao/ transformaçao suave
	var tween = create_tween()
	target.visible = false
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", target.global_position, time_move)
	tween.tween_property(self, "global_position", global_position, time_move)
	tween.set_loops()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
