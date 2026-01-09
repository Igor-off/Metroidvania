extends CharacterBody2D

#=== Referências dos nós
@onready var player_animation        : AnimatedSprite2D = $Animation
@onready var player_collider         : CollisionShape2D = $Collider2D
@onready var player_hurtbox_collider : CollisionShape2D = $Hurtbox/Collider2D
@onready var reload_timer            : Timer            = $ReloadTimer
@onready var left_wall_detector      : RayCast2D        = $LeftWallDetector
@onready var right_wall_detector     : RayCast2D        = $RightWallDetector

# Funções para alterar o tamanho dos colisores
func set_small_colliders(): # Importante para estado agachado ou deslizando
	# Diminuir colisor do personagem
	player_collider.shape.radius = 15.0
	player_collider.shape.height = 36.0 
	player_collider.position.y   = 8.0
	# Diminuir colisor do hurtbox
	player_hurtbox_collider.shape.size.y = 36.0
	player_hurtbox_collider.position.y   = 8.0

func set_large_colliders(): # Importante ao sair do estado agachado ou deslizando
	# Aumentar colisor do personagem
	player_collider.shape.radius = 15.0
	player_collider.shape.height = 50.0 
	player_collider.position.y   = 1.0
	# Aumentar colisor do hurtbox
	player_hurtbox_collider.shape.size.y = 50.0
	player_hurtbox_collider.position.y   = 1.0

#========== Componente de movimento do personagem ==========
#=== Movimento no eixo x
var sense_direction              = 0     # Sentido do vetor velocidade no eixo x
# Variáveis default
@export var max_speed_x          = 260.0 # Módulo da velocidade no eixo x
@export var acceleration         = 1400.0 # Módulo da aceleração
@export var deceleration         = 1800.0 # Módulo da desaceleração
@export var slide_deceleration   = 200.0 # Módulo da desaceleração para derrapada

# Função para atualizar o sentido do movimento no eixo x
func update_direction():
	# Verificar as entradas(botões de movimento no eixo x)
	sense_direction = Input.get_axis("left", "right")
	if sense_direction < 0:   # Se -1, left foi acionado, inverter a animação no eixo y
		player_animation.flip_h = true
	elif sense_direction > 0: # Se 1, right foi acionado, manter o sentido da animação
		player_animation.flip_h = false

# Função para atualizar o módulo da velocidade no eixo x
func move_x(delta): 
	update_direction()
	if sense_direction: # Se -1 ou 1, os botões de movimento em x estão sendo pressionados
		# Andar gradativamente
		velocity.x = move_toward(velocity.x, (sense_direction * max_speed_x), (acceleration * delta))
	else: # Se 0, os botões de movimento em x foram soltos
		# Parar gradativamente
		velocity.x = move_toward(velocity.x, 0, (deceleration * delta))

#=== Movimento no eixo y
var jump_count                   = 0      # Contador de pulos
# Variáveis default
@export var max_jump             = 2      # Quantidade máxima de pulos permitido
@export var jump_speed           = -650.0 # Módulo da velocidade inicial em y no pulo a partir do solo
@export var ONWALL_acceleration  = 140.0   # Módulo da aceleração na parede (vamos desconsiderar a gravidade nesse caso)
@export var ONWALL_jump_speed    = -600.0  # Módulo da velocidade inicial em y no pulo a partir de uma parede

# Função para aplicar a gravidade
func apply_gravity(delta):
	if not is_on_floor():
		velocity += (get_gravity() * delta)

# Função para validar pulo
func can_jump() -> bool:
	return (jump_count < max_jump)

#======================================================
#========== Máquina de estados do personagem ==========
#=== Estados do personagem
enum PlayerState {
	IDLE = 0,  # Parado, sem receber comando
	WALKING,   # Andando no eixo X
	DASH,      # Impulso no eixo x
	RUNNING,   # Correndo no eixo x
	JUMPING,   # Pulando, subindo no eixo y
	FALLING,   # Caindo, descendo no eixo y
	GILDING,   # Planando
	SQUATTING, # Agachado
	SKIMMING,  # Deslizando, movendo-se no eixo x
	ONWALL,    # Deslizando na parede, movendo-se no eixo y
	DEAD       # Morto
}
var status: PlayerState # Guardar o estado do personagem

#=== Funções de entrada no estado
# Função para entrar no estado IDLE
func go_to_idle_state():
	status = PlayerState.IDLE     # Mudar estado atual
	player_animation.play("IDLE") # Mudar animação
	
# Função para entrar no estado WALKING
func go_to_walking_state():
	status = PlayerState.WALKING     # Mudar estado atual
	player_animation.play("WALKING") # Mudar animação

# Função para entrar no estado DASH
func go_to_dash_state():
	pass
# Função para entrar no estado RUNNING
func go_to_running_state():
	pass

# Função para entrar no estado JUMPING
func go_to_jumping_state():
	status = PlayerState.JUMPING     # Mudar estado atual
	player_animation.play("JUMPING") # Mudar animação
	velocity.y = jump_speed          # Aplicar o pulo
	jump_count += 1                  # Atualizar o contador de pulos  
	
# Função para entrar no estado FALLING
func go_to_falling_state():
	status = PlayerState.FALLING     # Mudar estado atual
	player_animation.play("FALLING") # Mudar animação

# Função para entrar no estado GILDING
func go_to_gilding_state():
	pass

# Função para entrar no estado SQUATTING
func go_to_squatting_state():
	status = PlayerState.SQUATTING     # Mudar estado atual
	player_animation.play("SQUATTING") # Mudar animação
	set_small_colliders()              # Diminuir tamanho dos colisores ao agachar

# Função para entrar no estado SKIMMING
func go_to_skimming_state():
	status = PlayerState.SKIMMING     # Mudar estado atual
	player_animation.play("SKIMMING") # Mudar animação
	set_small_colliders()             # Aumentar o tamanho dos colisores ao deslizar

# Função para entrar no estado ONWALL
func go_to_onwall_state():
	status = PlayerState.ONWALL     # Mudar estado atual
	player_animation.play("ONWALL") # Mudar animação
	velocity = Vector2.ZERO         # Zerar todos os efeitos de velocidade, tanto em x quanto em y.
	jump_count = 0                  # Resetar o duplo pulo, permitir dar dois pulos a partir desse estado

# Função para entrar no estado DEAD
func go_to_dead_state():
	# Impedir morrer várias vezes em colisões consecutivas
	if status == PlayerState.DEAD:
		return
	status = PlayerState.DEAD     # Mudar estado atual
	player_animation.play("DEAD") # Mudar animação
	velocity = Vector2.ZERO       # Parar o personagem em todas as direções
	reload_timer.start()          # Resetar fase após o timer de animação da morte

#=== Funções de saída do estado
# Função para sair do estado SQUATTING
func exit_from_squatting_estate():
	set_large_colliders() # Aumentar os colisores ao levantar 

# Função para sair do estado SKIMMING
func exit_from_skimming_state():
	set_large_colliders() # Aumentar os colisores ao levantar

#=== Funções de processamento do estado atual
# Função de processamento do estado IDLE
func idle_state(delta):
	# I  - Enquanto estiver no estado IDLE
	apply_gravity(delta) # Aplicar a gravidade
	move_x(delta)        # Manter parado
	# II - Verificações de mudança de estado
	# IDLE para JUMPING
	if Input.is_action_just_pressed("up"):
		go_to_jumping_state()
		return
	# IDLE para WALKING
	if velocity.x != 0:
		go_to_walking_state()
		return
	# IDLE para SQUATTING
	if Input.is_action_pressed("down"):
		go_to_squatting_state()
		return

# Função de processamento do estado WALKING
func walking_state(delta):
	# I  - Enquanto estiver no estado IDLE
	apply_gravity(delta) # Aplicar a gravidade
	move_x(delta)        # Mover no eixo x
	# II - Verificações de mudança de estado
	# WALKING para IDLE
	if velocity.x == 0:
		go_to_idle_state()
		return
	# WALKING para JUMPING
	if Input.is_action_just_pressed("up"):
		go_to_jumping_state()
		return
	# WALKING para FALLING - quando acabar o terrano durando o estado WALKING
	if not is_on_floor():
		jump_count += 1 # descontar um pulo
		go_to_falling_state()
		return
	# WALKING para SKIMMING
	if Input.is_action_just_pressed("down"):
		go_to_skimming_state()
		return

# Função de processamento do estado JUMPING
func jumping_state(delta):
	# I  - Enquanto estiver no estado IDLE
	apply_gravity(delta) # Aplicar a gravidade
	move_x(delta)        # Permitir mover no ar na diração x
	# II - Verificações de mudança de estado
	# JUMPING para JUMPING (segundo pulo)
	if Input.is_action_just_pressed("up") && can_jump(): # Limitar a quantodade de pulo
		go_to_jumping_state()
		return
	# JUMPING para FALLING 
	if (velocity.y > 0): # Na altura máxima do pulo, o vetor y deixa de ser negativo, torna-se zero e depois positivo
		go_to_falling_state()
		return

# Função de processamento do estado FALLING
func falling_state(delta):
	# I  - Enquanto estiver no estado IDLE
	apply_gravity(delta) # Aplicar a gravidade
	move_x(delta)        # Permitir mover no eixo x durante a queda
	# II - Verificações de mudança de estado
	# FALLING para JUMPING (segundo pulo durante a queda)
	if Input.is_action_just_pressed("up") && can_jump():
		go_to_jumping_state()
		return
	# FALLING para IDLE ou WALKING
	if is_on_floor():
		jump_count = 0 # Zerar contador de pulo sempre que encostar no solo
		if velocity.x == 0:
			go_to_idle_state()    # Cair parado
		else:
			go_to_walking_state() # Cair andando
		return
	# FALLING para ONWALL - única forma de ir para ONWALL
	if (left_wall_detector.is_colliding() or right_wall_detector.is_colliding()) && is_on_wall():
		go_to_onwall_state()
		return

# Função de processamento do estado SQUATTING
func squatting_state(delta):
	# I  - Enquanto estiver no estado IDLE
	apply_gravity(delta) # Aplicar a gravidade
	update_direction()   # Permitir virar em relação ao eixo x
	# II - Verificações de mudança de estado
	# SQUATTING para IDLE
	if Input.is_action_just_released("down"): # Sair do estado SQUATTIING ao soltar a tecla "down" 
		exit_from_squatting_estate() # Atualizar os colisores
		go_to_idle_state()
		return

# Função de processamento do estado SKIMMING
func skimming_state(delta):
	# I  - Enquanto estiver no estado IDLE
	apply_gravity(delta) # Aplicar a gravidade
	# Atribuir aceleração específica do movimento no eixo x
	velocity.x = move_toward(velocity.x, 0, (slide_deceleration * delta))
	# II - Verificações de mudança de estado
	# SKIMMING para WALKING
	if Input.is_action_just_released("down"): # Voltar a andar ao soltar o botão "down"
		exit_from_skimming_state()
		go_to_walking_state()
		return
	# SKIMMING para SQUATTING
	if velocity.x == 0: # Se a velocidade em x chegou a zero e o botão "down" não foi solto
		exit_from_skimming_state()
		go_to_squatting_state()
		return

# Função de processamento do estado ONWALL
func onwall_state(delta):
	# I  - Enquanto estiver no estado ONWALL
	velocity.y += (ONWALL_acceleration * delta) # Aplicar a aceleração específica no estado no eixo y (gravidade)
	# II - Verificações de mudança de estado
	# Ajustar a direção e o sentido do personagem de acordo com a parede
	if left_wall_detector.is_colliding():
		player_animation.flip_h = false
		sense_direction = 1
	elif right_wall_detector.is_colliding():
		player_animation.flip_h = true
		sense_direction = -1
	# ONWALL para FALLING - Terminou a parede durante o estado ONWALL
	else:
		go_to_falling_state()
		return
	# ONWALL para IDLE
	if is_on_floor(): # Tocou no chão durante o estado ONWALL
		go_to_idle_state()
		return
	# ONWALL para JUMPING
	if Input.is_action_just_pressed("up"):
		velocity.x = (ONWALL_jump_speed * sense_direction)
		go_to_jumping_state()
		return

# Função de processamento do estado DEAD
func dead_state(_delta):
	pass

#=== Processadores da máquina de estado
# Função de inicialização da máquina de estados
func _ready() -> void:  
	go_to_idle_state() # Iniciar sempre no estado IDLE 

# Processo que atualiza o estado a cada frame
func _physics_process(delta: float) -> void:
	# Capturar o estado atual e processá-lo
	match status:
		PlayerState.IDLE:
			idle_state(delta)
		PlayerState.WALKING:
			walking_state(delta)
		PlayerState.JUMPING:
			jumping_state(delta)
		PlayerState.SQUATTING:
			squatting_state(delta)
		PlayerState.FALLING:
			falling_state(delta)
		PlayerState.SKIMMING:
			skimming_state(delta)
		PlayerState.ONWALL:
			onwall_state(delta)
		PlayerState.DEAD:
			dead_state(delta)
	move_and_slide()

#====================================================
#========== Funões sinais ==========
#=== Sinais da hitbox do personagem
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LetalArea"):
		hit_lethal_area()

func hit_enemy(area: Area2D):
	# Matar com pulo só acontecerá se o personagem estiver em queda
	if velocity.y > 0: 
		# Pegar o nó pai(inimigo em si) da área da hitbox e entrou na hitbox do personagem
		area.get_parent().take_damage() # Aplicar dano
		go_to_jumping_state()
	else:
		go_to_dead_state()

func hit_lethal_area():
	go_to_dead_state()

#=== Sinais do timer
func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LetalArea"):
		go_to_dead_state()
