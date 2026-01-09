extends Area2D

#=== Referências dos nós
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

#========== Componente de movimento do projétil ==========
#=== Variáveis do movimento no eixo x
var SPEED          = 100 # Pixel por frame
var bone_direction = 1   # Direção 1 para direita e -1 para esquerda

#=== Função para definir a direção e o sentido do movimento do projétil
func set_direction(direction):
	# Recebe a direção(direction) do personagem
	bone_direction = direction
	# Ajustar o sentido da rotação da animação com base no sentido do personagem
	animation.flip_h = (bone_direction < 0)

#=== Função para movimentar o projétil
func _process(delta: float) -> void:
	position.x += (SPEED * delta * bone_direction) # pixel por segundo

#=== Função para destruir objeto da cena e liberar a memória
func _on_self_destruct_timer_timeout() -> void:
	queue_free()


func _on_area_entered(_area: Area2D) -> void:
	queue_free()


func _on_body_entered(_body: Node2D) -> void:
	queue_free()
