extends CharacterBody2D

#=== Referências dos nós
@onready var animation : AnimatedSprite2D = $Animation

#========== Componente de movimento do Player ==========
#=== Movimento no eixo x
var direction               = 0     # Sentido da direção no eixo x
@export var maximum_speed_x = 300.0 # Valor máximo do módulo velocidade no eixo x
@export var acceleration    = 500.0 # Módulo do vetor aceleração
@export var deceleration    = 300.0 # Módulo do velor "desaceleração"

# Função para virar a animação do Player para esquerda ou para direita
func update_direction():
	direction = Input.get_axis("LEFT", "RIGHT")
	if direction > 0:
		animation.flip_h = false
	elif direction < 0:
		animation.flip_h = true

# Função para atualizar a velocidade no eixo x
func move_x(delta):
	# Atualizar sentido da direção do movimento do Player no eixo x
	update_direction()
	if direction: # Se sim, acelerar para andar
		velocity.x = move_toward(velocity.x, (direction * maximum_speed_x), (acceleration * delta))
	else: # Se não, desacelerar e parar
		velocity.x = move_toward(velocity.x, 0, (deceleration * delta))

#=== Movimento no eixo y
@export var jump_speed      = -300.0 # Velocidade inicial do pulo
@export var max_jump_number = 2      # Número máximo de pulos
var jump_count              = 0      # Contador de pulos realizados

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
	RISING,   # Movendo-se no eixo y, para cima
	FALLING   # Movendo-se no eixo y, para baixo
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

# Função para entrar no estado RISING
func go_to_rising_state():
	status = PlayerState.RISING
	animation.play("RISING")
	# Pular antes de entrar no estado para sicronizar a animação
	velocity.y = jump_speed
	# Contar os pulos
	jump_count += 1

# Função para entrar no estado FALLING
func go_to_falling_state():
	status = PlayerState.FALLING
	animation.play("FALLING")

#=== Funções de processamento do estado atual
# Função para processar o estado IDLE
func idle_state(delta):
	# Enquanto estiver no estado IDLE:
	apply_gravity(delta) # Aplicar a gravidade
	move_x(delta)        # Manter o personagem parado
	# Processar o próximo estado
	# De parado para andando
	if (velocity.x != 0): # Pressionou alguma tecla de movimento horizontal
		go_to_walking_state()
		return
	# De parado para "pulando"
	if Input.is_action_just_pressed("UP"): # Pressionou alguma tecla de pulo
		go_to_rising_state()
		return

func walking_state(delta):
	# Enquanto estiver no estado WALKING:
	apply_gravity(delta) # Aplicar a gravidade
	move_x(delta)        # Manter o personagem andando no eixo x
	# Processar o próximo estado
	# De andando para parado
	if velocity.x == 0: # Parou de pressionar alguma tecla de movimento horizontal
		go_to_idle_state()
		return
	# De andando para "pulando"
	if Input.is_action_just_pressed("UP"): # Pressionou a tecla de pulo
		go_to_rising_state()
		return
	# De andando para caindo
	if not is_on_floor(): # Caiu de uma estrutura
		go_to_falling_state()
		return

func rising_state(delta):
	# Enquanto estiver no estado RISING:
	apply_gravity(delta) # Aplicar a gravidade
	move_x(delta)        # Permitir mover na horizontal enquanto pula
	# Processar o próximo estado
	# De "pulando" para caindo
	if (velocity.y > 0): # O vetor velocidade no eixo y fica positivo na descida
		go_to_falling_state()
		return
	# De "pulando" para "pulando" - segundo pulo
	if Input.is_action_just_pressed("UP") && (jump_count < max_jump_number):
		go_to_rising_state()
		return;

func falling_state(delta):
	# Enquanto estiver no estado FALLING:
	apply_gravity(delta) # Aplicar a gravidade
	move_x(delta)        # Permitir mover na horizontal enquanto cai
	# Processar o próximo estado
	# De caindo para parado ou andando
	if is_on_floor():
		jump_count = 0 # Resetar contador de pulo no solo
		if velocity.x != 0: # cair andando
			go_to_walking_state()
		else:
			go_to_idle_state() # cair parado
		return
	# De caindo para "pulando"
	else: # Lógica do segundo pulo durante a queda
		if Input.is_action_just_pressed("UP") && (jump_count < max_jump_number):
			go_to_rising_state()
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
		PlayerState.RISING:
			rising_state(delta)
		PlayerState.FALLING:
			falling_state(delta)
	move_and_slide()