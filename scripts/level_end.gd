extends Area2D
#Vamos fazer um sinal para reconhecer quando o player entra dentro dessa area ddo LevelEnd

@export var next_level = ""

func _on_body_entered(_body: Node2D) -> void:
	call_deferred("load_next_scene")
	#1ºTermina todo o processamento de fisica e garantir que nao tenha nenhum bug, 
	# terminando ela chama a funçao e assim ela carrega a prroxima cena e "destroi a fase antereior"
func load_next_scene():
	get_tree().change_scene_to_file("res://scene/" + next_level + ".tscn")
	
