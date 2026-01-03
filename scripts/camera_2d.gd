extends Camera2D

#=== Declaração do alvo da câmera na cena
var target: Node2D

#=== Função para procurar o alvo entre os nós da cena
func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error(">>> ERRO: Player não encontrado na cena!!!")
		return
	target = nodes[0]

#=== Métodos para fixar a câmera quando o alvo entrar em cena
func _ready() -> void:
	get_target()

#=== Processo para atualizar posição da câmera em relação ao alvo a cada frame 
func _process(_delta: float) -> void:
	position = target.position
