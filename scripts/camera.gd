extends Camera2D

# Declaração do alvo da câmera
var target: Node2D 
# Procurar esse alvo entre os nós da cena
func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error(">>>ERRO: Player não encontrado!!!")
		return
	target = nodes[0]
# Método 
func _ready() -> void:
	get_target() # Procurar alvo assim que começar a cena, primeiro frame
# Processo
func _process(_delta: float) -> void:
	position = target.position # Atualizar a posição da câmera em relação ao alvo a cada frame
