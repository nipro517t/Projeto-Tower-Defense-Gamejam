extends Area2D

@export var velocidade: float = 100.0
@export var vida_max: int = 10
@export var valor_recompensa: int = 25
@export var dano_na_base: int = 2   # vidas que o jogador perde quando este inimigo chega ao fim
@onready var label: Label = $Label


var vida: int
var path_follow: PathFollow2D
var _morto: bool = false   # impede morrer duas vezes (ex: burn + torre no mesmo frame)

# --- Ícones de efeito (fogo, gelo...) em cima do inimigo ---
var _icones: Node2D

# --- Burn (DOT) acumulativo ---
var burn_potencia: int = 0        # dano por tick, soma a cada novo hit
var burn_ticks_restantes: int = 0
var burn_timer: Timer = null
const BURN_STACK_MAX: int = 50    # teto de balanceamento


func _ready():
	vida = vida_max
	_icones = preload("res://Scripts/icones_efeito.gd").new()
	add_child(_icones)


func _process(delta):
	if _morto or not is_instance_valid(path_follow):
		return

	label.text = str(vida)
	path_follow.progress += velocidade * delta
	global_position = path_follow.global_position

	if path_follow.progress_ratio >= 1.0:
		morrer(false)


func receber_dano(quantidade: int):
	if _morto:
		return
	vida -= quantidade
	_mostrar_indicador_dano(quantidade)
	if vida <= 0:
		morrer(true)


func _mostrar_indicador_dano(quantidade: int):
	# ⚠️ Criado por código — um Label temporário que sobe e desaparece,
	# depois se autodestrói.
	var indicador = Label.new()
	indicador.text = str(quantidade)
	indicador.modulate = Color(1, 0.25, 0.25)
	indicador.z_index = 10  # garante que desenha por cima dos sprites
	get_tree().current_scene.add_child(indicador)
	indicador.global_position = global_position + Vector2(-8, -30)

	var tween = indicador.create_tween()
	# ⚠️ "position:y" tween só a coordenada Y — sobe 24px suavemente.
	tween.tween_property(indicador, "position:y", indicador.position.y - 24, 0.6)
	# ⚠️ parallel() faz o próximo tween rodar AO MESMO TEMPO que o de
	# cima — assim sobe E desaparece juntos.
	tween.parallel().tween_property(indicador, "modulate:a", 0.0, 0.6)
	tween.tween_callback(indicador.queue_free)


func aplicar_burn(dano_por_tick: int, duracao: float):
	if _morto:
		return

	# soma a potência até o teto — é isso que faz múltiplas torres de fogo
	# (ou hits repetidos da mesma torre) aumentarem o dano por tick
	burn_potencia = min(burn_potencia + dano_por_tick, BURN_STACK_MAX)
	# reseta a duração a cada novo hit, independente da potência
	burn_ticks_restantes = int(duracao)

	# só cria o timer na PRIMEIRA aplicação; hits seguintes só atualizam
	# as variáveis acima, reaproveitando o mesmo timer já rodando
	if burn_timer == null:
		burn_timer = Timer.new()
		burn_timer.wait_time = 1.0
		add_child(burn_timer)
		burn_timer.timeout.connect(_tick_burn)
		burn_timer.start()

	# ícone de fogo: dura até o último tick do burn (tempo até o próximo
	# tick + os ticks que ainda faltam depois dele)
	_icones.mostrar("fogo", burn_timer.time_left + max(burn_ticks_restantes - 1, 0))


func _tick_burn():
	receber_dano(burn_potencia)
	burn_ticks_restantes -= 1

	if burn_ticks_restantes <= 0 and burn_timer != null:
		burn_potencia = 0
		burn_timer.queue_free()
		burn_timer = null


func morrer(morte: bool):
	if _morto:
		return
	_morto = true

	if morte:
		Game.dinheiro += valor_recompensa
	else:
		Game.vida_jogador -= dano_na_base

	# o PathFollow2D é criado pelo Spawner e pertence ao inimigo: sai junto
	if is_instance_valid(path_follow):
		path_follow.queue_free()
	queue_free()
