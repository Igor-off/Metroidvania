extends CharacterBody2D

#========== Componente de movimento do Player ==========
#=== Movimento no eixo x
@export var max_speed = 100.0

# Função para atualizar a velocidade no eixo x
func move_x(_delta):
	# Verificar se algum botão de movimento foi pressionado
	var direction := Input.get_axis("LEFT", "RIGHT")
	if direction:
		velocity.x = (direction * max_speed)
	else:
		# Parar gradativamente
		velocity.x = move_toward(velocity.x, 0, max_speed)

#=== Movimento no eixo y
@export var jump_velocity = -300.0

# Função que aplica velocidade no pulo

func _physics_process(delta: float) -> void:
	# Aplicar gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Mover no eixo x
	move_x(delta)
	# Verificar confdição de pulo
	if Input.is_action_just_pressed("UP") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
