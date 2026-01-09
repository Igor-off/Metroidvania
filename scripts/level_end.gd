extends Area2D

@export var next_level = ""

# Sinal do level_end que verifica se um entrou em contato
func _on_body_entered(_body: Node2D) -> void: # Passa por parâmetro qual corpo que entrou
	# Chamar a próxima fase dinamicamente
	call_deferred("load_next_scene")

func load_next_scene():
	get_tree().change_scene_to_file("res://scene/" + next_level + ".tscn")
