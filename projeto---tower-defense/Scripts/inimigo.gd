extends Area2D

@export var velocidade: float = 100.0
@export var vida_max: int = 10
@export var valor_recompensa: int = 25
@onready var label: Label = $Label


var vida: int
var path_follow: PathFollow2D

# --- Burn (DOT) acumulativo ---
var burn_potencia: int = 0        # dano por tick, soma a cada novo hit
var burn_ticks_restantes: int = 0
var burn_timer: Timer = null
const BURN_STACK_MAX: int = 10    # teto de balanceamento

func _ready():
	vida = vida_max


func _process(delta):
	label.text = str(vida)
	path_follow.progress += velocidade * delta
	global_position = path_follow.global_position

	if path_follow.progress_ratio >= 1.0:
		morrer(false)


func receber_dano(quantidade: int):
	vida -= quantidade
	if vida <= 0:
		morrer(true)


func aplicar_burn(dano_por_tick: int, duracao: float):
	# soma a potência até o teto — isso é o que faz múltiplas torres de fogo
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

func _tick_burn():
	receber_dano(burn_potencia)
	burn_ticks_restantes -= 1
	
	if burn_ticks_restantes <= 0:
		burn_potencia = 0
		burn_timer.queue_free()
		burn_timer = null


func morrer(morte: bool):
	if morte:
		Game.dinheiro += valor_recompensa
		path_follow.queue_free()
		queue_free()
	else:
		Game.vida_jogador -= 2
		path_follow.queue_free()
		queue_free()
