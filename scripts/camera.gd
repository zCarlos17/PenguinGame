extends Camera2D
#tag -> Caracteristica de algum item ou elemento do jogo 

#Referencia
var target: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_target()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#Para todos os frames serem processados ele deve passar por esse codigo:
func _process(_delta: float) -> void:
	position = target.position #Copia a posiçao da camera como posiçao do player (nesse exemplo/situaçao)

func get_target():
	#Vai buscar todos os nós dentro de um grupo
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error("Player não encontrado!")
		return 
	
	target = nodes[0] #Cochetes indica a posiçao do objeto dentro da lista! // nodes [ ] -- "vetor"
