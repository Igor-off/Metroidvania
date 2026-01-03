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
		

#======================================================
#========== Máquina de estados do personagem ==========
#=== Estados do personagem
enum PlayerState {
	IDLE = 0, # Parado sem receber comandos de entrada
	WALKING,  # Movendo-se no eixo X
	JUMPING,  # Movendo-se no eixo y
}
var status: PlayerState # Variável para guardar o estado atual do Player
#=== Funções de entrada no estado
# Função para entrar no estado IDLE
func go_to_idle_state():
	status = PlayerState.IDLE # Mudar o estao do personagem
	animation.play("IDLE")    # Mudar a anmação do personagem

# Função para entrar no estado WALKING
func go_to_walking_state():
	status = PlayerState.WALKING
	animation.play("WALKING")

# Função para entrar no estado JUMPING
func go_to_jumping_state():
	status = PlayerState.JUMPING
	animation.play("JUMPING")
	velocity.y = jump_speed

#=== Funções de processamento do estado atual
# Função para processar o estado IDLE
func idle_state(delta):
	# Enquanto estiver no estado:
	apply_gravity(delta) # Aplicar a gravidade
	move_x(delta)        # Manter o personagem parado
	# Mudar estado
	if Input.is_action_just_pressed("UP"):
		go_to_jumping_state()
		return
	if (velocity.x != 0):
		go_to_walking_state()
		return

func walking_state(delta):
	apply_gravity(delta)
	move_x(delta)
	# Mudar estado
	if velocity.x == 0:
		go_to_idle_state()
		return
	if Input.is_action_just_pressed("UP"):
		go_to_jumping_state()
		return

func jumping_state(delta):
	apply_gravity(delta)
	move_x(delta)
	# Mudar estado
	if is_on_floor():
		# Cair parado
		if velocity.x == 0:
			go_to_idle_state()
		# Cair correndo
		else:
			go_to_walking_state()
		return

#======================================================

# Método de inicialização do estado
func _ready() -> void:
	go_to_idle_state() # Inicializar no estado IDLE

# Processo para processar o estado a cada frame
func _physics_process(delta: float) -> void:
	# Capturar os estados a cada frame
	match status:
		PlayerState.IDLE:
			idle_state(delta)
		PlayerState.WALKING:
			walking_state(delta)
		PlayerState.JUMPING:
			jumping_state(delta)
	move_and_slide()
