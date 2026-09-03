extends Node2D

@export var dano: int = 5
@export var cadencia: float = 1.0  # segundos entre cada ataque

var inimigos_no_alcance: Array = []  # guarda todos os inimigos dentro da Area2D de alcance

func _ready():
	# $Area2D referencia o filho fixo da própria torre; conecta os sinais de entrada/saída de alcance
	$Area2D.area_entered.connect(_on_area_entered)
	$Area2D.area_exited.connect(_on_area_exited)

	var timer_ataque = Timer.new()
	timer_ataque.wait_time = cadencia
	timer_ataque.timeout.connect(_atacar)  
	add_child(timer_ataque)
	timer_ataque.start()

func _on_area_entered(area):
	inimigos_no_alcance.append(area)

func _on_area_exited(area):
	inimigos_no_alcance.erase(area)

func escolher_alvo():
	var alvo = null
	var maior_progresso = -1.0
	for inimigo in inimigos_no_alcance:
		# is_instance_valid evita crash se o inimigo já morreu mas ainda não foi removido da lista
		if is_instance_valid(inimigo) and inimigo.path_follow.progress > maior_progresso:
			maior_progresso = inimigo.path_follow.progress
			alvo = inimigo
	return alvo

func _atacar():
	var alvo = escolher_alvo()
	if alvo:
		alvo.receber_dano(dano)
