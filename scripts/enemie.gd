extends CharacterBody2D

#=== Referências dos nós
@onready var animation           : AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox              : Area2D           = $hitbox
@onready var wall_detector       : RayCast2D        = $WallDetector
@onready var ground_detector     : RayCast2D        = $GroundDetector
@onready var player_detector     : RayCast2D        = $PlayerDetector
@onready var bone_start_position : Node2D           = $BoneStartPosition

#=== Referências dos recursos
const SPINNING_BONE = preload("res://entities/skillshot.tscn")

#========== Componente de ações do esqueleto ==========
#=== Variáveis e constantes para o movimento no eixo x
const SPEED              = 100.0
var   skeleton_direction = 1

#=== Variáveis e constantes para habilidades
var can_throw = true

#======================================================
#========== Máquina de estados do esqueleto ==========
enum SkeletonState {
	WALKING = 0, # Andando
	ATTACKING,   # Atacando
	DEAD         # Morto
}

var status: SkeletonState # Guardar o estado atual e o próximo do esqueleto

#=== Funções de atualização do próximo estado
#= Funções de entrada no estado
func go_to_walking_state():
	status = SkeletonState.WALKING
	animation.play("WALKING")

func go_to_attacking_state():
	status = SkeletonState.ATTACKING
	# Parar e atacar
	velocity = Vector2.ZERO
	animation.play("ATTACKING")
	can_throw = true # O ataque deve ser feito no frame específico da animação

func go_to_dead_state():
	status = SkeletonState.DEAD
	animation.play("DEAD")
	# Desativar a hitbox
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	# Parar a caveira antes de morrer
	velocity = Vector2.ZERO

#=== Funções de processamento do estado atual
func walking_state(_delta):
	if animation.frame == 3 or animation.frame == 4:
		velocity.x = (SPEED * skeleton_direction)
	else:
		velocity.x = 0
	# Detectar parede
	if wall_detector.is_colliding():
		scale.x            *= -1 # Espelhar personagem para inverter animação
		skeleton_direction *= -1 # Inverter o sentido do movimento
	# Detectar solo
	if not ground_detector.is_colliding():
		scale.x            *= -1
		skeleton_direction *= -1
	# Detectar player
	if player_detector.is_colliding():
		go_to_attacking_state()
		return

func throw_bone():
	# Instanciar um preload da skill a cena
	var new_bone = SPINNING_BONE.instantiate()
	add_sibling(new_bone)
	# Definir posição do projétil em relação a animação do esqueleto
	new_bone.position = bone_start_position.global_position
	# Definir o sentido do arremeço
	new_bone.set_direction(skeleton_direction)

func attacking_state(_delta):
	# Atacar uma única vez no frame específico da animação
	if animation.frame == 2 && can_throw:
		throw_bone()
		can_throw = false

# O inimigo ira entrar no estado DEAD por meio dessa função
# que será chamada no script do personagem quando as áreas colidirem
func take_damage():
	go_to_dead_state()
	return

func dead_state(_delta):
	pass

func _physics_process(delta: float) -> void:
	# Aplicar a gravidade:
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Capturar o estado do esqueleto
	match status:
		SkeletonState.WALKING:
			walking_state(delta)
		SkeletonState.ATTACKING:
			attacking_state(delta)
		SkeletonState.DEAD:
			dead_state(delta)
	move_and_slide()

#=== Função de inicialização da máquina de estados
func _ready() -> void:
	go_to_walking_state()
	return


func _on_animated_sprite_2d_animation_finished() -> void:
	if animation.animation == "ATTACKING":
		go_to_walking_state()
		return
