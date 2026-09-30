extends Node

@export var path: Path2D  # caminho do mapa, compartilhado por todos os inimigos

# ⚠️ Cada item deste Array é uma "OndaConfig" (Resource criado por você no
# Inspector) — dentro dela, você lista quais grupos de inimigos aparecem,
# em que ordem, quantos de cada e com que intervalo.
@export var ondas: Array[OndaConfig] = []

@export var intervalo_entre_ondas: float = 5.0  # descanso depois que uma onda inteira acaba

var _onda_atual_index: int = -1
var _grupo_atual_index: int = 0
var _spawns_restantes_no_grupo: int = 0
var _inimigos_vivos: int = 0
var _timer_spawn: Timer


func _ready():
	_timer_spawn = Timer.new()
	_timer_spawn.timeout.connect(_spawnar_proximo)
	add_child(_timer_spawn)
	_proxima_onda()


func _proxima_onda():
	if ondas.is_empty():
		push_warning("Spawner sem ondas configuradas.")
		return

	_onda_atual_index += 1

	if _onda_atual_index >= ondas.size():
		return

	Game.wave = _onda_atual_index + 1
	_grupo_atual_index = 0
	_iniciar_grupo()


func _iniciar_grupo():
	var onda = ondas[_onda_atual_index]

	if _grupo_atual_index >= onda.grupos.size():
		return  # essa onda não tem mais grupos pra spawnar — só falta os inimigos acabarem

	var grupo = onda.grupos[_grupo_atual_index]
	_spawns_restantes_no_grupo = grupo.quantidade
	_timer_spawn.wait_time = grupo.intervalo
	_timer_spawn.start()


func _spawnar_proximo():
	var onda = ondas[_onda_atual_index]
	var grupo = onda.grupos[_grupo_atual_index]

	_spawns_restantes_no_grupo -= 1
	_inimigos_vivos += 1

	var caminho = PathFollow2D.new()
	caminho.loop = false
	path.add_child(caminho)

	var inimigo = grupo.inimigo_cena.instantiate()
	inimigo.path_follow = caminho
	inimigo.global_position = caminho.global_position

	# ⚠️ tree_exited dispara sozinho quando o inimigo sai da árvore
	# (queue_free()) — o spawner descobre quando ele morre sem precisar
	# mexer em inimigo.gd.
	inimigo.tree_exited.connect(_on_inimigo_removido)

	add_child(inimigo)

	if _spawns_restantes_no_grupo <= 0:
		_timer_spawn.stop()
		_grupo_atual_index += 1
		_iniciar_grupo()  # já encadeia pro próximo grupo desta mesma onda, se houver


func _on_inimigo_removido():
	if not is_inside_tree():
		return  # o Spawner já foi destruído (ex: reinício da fase) — não faz nada

	_inimigos_vivos -= 1
	var onda = ondas[_onda_atual_index]
	var ja_spawnou_tudo_desta_onda = _grupo_atual_index >= onda.grupos.size()

	if _inimigos_vivos <= 0 and ja_spawnou_tudo_desta_onda:
		# Era a última onda? Então é vitória, sem esperar o descanso.
		if _onda_atual_index >= ondas.size() - 1:
			Game.checar_vitoria()
			return

		await get_tree().create_timer(intervalo_entre_ondas).timeout
		if not is_inside_tree():  # ⚠️ pode ter saído da árvore DURANTE a espera também
			return
		_proxima_onda()
