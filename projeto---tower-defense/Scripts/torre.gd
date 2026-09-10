extends Node2D

# ⚠️ @export_enum cria um dropdown no Inspector — assim você pode duplicar
# torre.tscn (ex: torre_fogo.tscn) e só trocar esse valor pelo editor, sem
# duplicar código nenhum.
@export_enum("Normal", "Fogo") var tipo_dano: String = "Normal"
@export var dano: int = 5           # usado quando tipo_dano == "Normal"
@export var cadencia: float = 1.0

# usados apenas quando tipo_dano == "Fogo"
@export var burn_dano_por_tick: int = 2
@export var burn_duracao: float = 3.0

var inimigos_no_alcance: Array = []


func _ready():
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
		if is_instance_valid(inimigo) and inimigo.path_follow.progress > maior_progresso:
			maior_progresso = inimigo.path_follow.progress
			alvo = inimigo
	return alvo


func _atacar():
	var alvo = escolher_alvo()
	if not alvo:
		return

	# ⚠️ match funciona como um switch: ramifica o comportamento da torre
	# de acordo com sua "classe" (ideia do seu GDD de Classes de torre).
	match tipo_dano:
		"Fogo":
			alvo.aplicar_burn(burn_dano_por_tick, burn_duracao)
		_:
			alvo.receber_dano(dano)
