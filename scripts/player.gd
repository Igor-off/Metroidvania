extends CharacterBody2D

#=== Referências dos nós
@onready var animation : AnimatedSprite2D = $Animation

#========== Componente de movimento do Player ==========
#=== Movimento no eixo x
var direction             = 0
@export var maximum_speed = 100.0
@export var acceleration  = 400.0
@export var deceleration  = 400.0

# Função para virar a animação do Player para esquerda ou para direita
func update_direction():
	direction = Input.get_axis("LEFT", "RIGHT")
	if direction < 0:
		animation.flip_h = true
	elif direction > 0:
		animation.flip_h = false

# Função para atualizar a velocidade no eixo x
func move_x(delta):
	# Atualizar sentido da direção do movimento do Player no eixo x
	update_direction()
	if direction: 
		# Se sim, acelerar para andar
		velocity.x = move_toward(velocity.x, (direction * maximum_speed), (acceleration * delta))
	else:
		# Se não, desacelerar e parar
		velocity.x = move_toward(velocity.x, 0, (deceleration * delta))

#=== Movimento no eixo y
const jump_speed = -300.0

# Função para aplicar a gravidade sobre o Player
func apply_gravity(delta):
	if not is_on_floor():
		velocity += (get_gravity() * delta)
		

# Função para pular
func jump(_delta):
	if Input.is_action_just_pressed("UP"):
		velocity.y = jump_speed

#======================================================

# Processo que aplicara as funções a cada frame
func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	move_x(delta)
	jump(delta)
	move_and_slide()
