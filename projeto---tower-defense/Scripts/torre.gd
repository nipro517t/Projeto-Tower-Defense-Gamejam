extends Node2D

# ⚠️ @export_enum cria um dropdown no Inspector — assim você pode duplicar
# torre.tscn (ex: torre_burn.tscn) e só trocar esse valor pelo editor, sem
# duplicar código nenhum.
@export_enum("Normal", "Fogo") var tipo_dano: String = "Normal"
@export var dano: int = 5           # usado quando tipo_dano == "Normal"
@export var cadencia: float = 1.0

# usados apenas quando tipo_dano == "Fogo"
@export var burn_dano_por_tick: int = 2
@export var burn_duracao: float = 3.0

# ⚠️ Prioridade de alvo (mecânica "Foco em determinado inimigo" do GDD).
@export_enum("Mais avançado", "Mais forte", "Primeiro que entrou") var prioridade_alvo: String = "Mais avançado"

# ⚠️ Arraste projetil_normal.tscn ou projetil_fogo.tscn aqui. Se deixar
# vazio, a torre volta a aplicar dano instantâneo (sem projétil visual).
@export var projetil_cena: PackedScene

# --- Animação de recarga ---
# Número do quadro (começando em 0) em que o projétil sai da arma.
# Balestra: 1 (a flecha sobe). Catapulta: 4 (a bola sai). Ajuste olhando a animação.
@export var frame_disparo: int = 1

# --- Upgrade / Venda ---
@export var custo_upgrade_base: int = 100
@export var multiplicador_custo_upgrade: float = 1.5
@export var incremento_dano_upgrade: int = 3
@export var incremento_cadencia_upgrade: float = 0.1
@export var fracao_venda: float = 0.7
const NIVEL_MAX_UPGRADE: int = 5

var custo_pago: int = 0
var nivel_upgrade: int = 0
var _custo_gasto_upgrades: int = 0

var inimigos_no_alcance: Array = []
var _indicador_alcance: Node2D = null
var _timer_ataque: Timer = null
var _alvo_pendente: Node2D = null   # alvo do disparo que está esperando o quadro certo da animação


func _ready():
	$Area2D.area_entered.connect(_on_area_entered)
	$Area2D.area_exited.connect(_on_area_exited)
	$Area2D.input_event.connect(_on_area_input_event)

	# Animação: fica parada no quadro 0 ("pronta") até a torre atirar
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AnimatedSprite2D.animation_finished.connect(_on_animacao_terminou)
	$AnimatedSprite2D.stop()
	$AnimatedSprite2D.frame = 0
	_ajustar_velocidade_animacao()

	_timer_ataque = Timer.new()
	_timer_ataque.wait_time = cadencia
	_timer_ataque.timeout.connect(_atacar)
	add_child(_timer_ataque)
	_timer_ataque.start()

	_criar_indicador_alcance()


func _criar_indicador_alcance():
	$Area2D.mouse_entered.connect(_mostrar_alcance)
	$Area2D.mouse_exited.connect(_esconder_alcance)

	var raio = $Area2D/CollisionShape2D.shape.radius

	_indicador_alcance = Node2D.new()
	add_child(_indicador_alcance)
	_indicador_alcance.visible = false

	_indicador_alcance.draw.connect(func():
		_indicador_alcance.draw_arc(Vector2.ZERO, raio, 0, TAU, 64, Color(1, 1, 1, 0.6), 2.0)
	)
	_indicador_alcance.queue_redraw()


func _mostrar_alcance():
	_indicador_alcance.visible = true


func _esconder_alcance():
	_indicador_alcance.visible = false


func _on_area_entered(area):
	inimigos_no_alcance.append(area)


func _on_area_exited(area):
	inimigos_no_alcance.erase(area)


func _on_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Game.torre_selecionada_info.emit(self)
		get_viewport().set_input_as_handled()


func escolher_alvo():
	match prioridade_alvo:
		"Mais forte":
			var alvo = null
			var maior_vida = -1
			for inimigo in inimigos_no_alcance:
				if is_instance_valid(inimigo) and inimigo.vida > maior_vida:
					maior_vida = inimigo.vida
					alvo = inimigo
			return alvo
		"Primeiro que entrou":
			for inimigo in inimigos_no_alcance:
				if is_instance_valid(inimigo):
					return inimigo
			return null
		_:  # "Mais avançado" (padrão)
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

	_apontar_arma(alvo)
	_alvo_pendente = alvo

	# Toca a animação do começo; o projétil sai quando chegar no frame_disparo
	var anim: AnimatedSprite2D = $AnimatedSprite2D
	anim.stop()
	anim.frame = 0
	anim.play("default")
	if frame_disparo <= 0:
		_on_frame_changed()


# Gira a arma inteira na direção do inimigo (a arte aponta para CIMA, por isso o + PI/2).
func _apontar_arma(alvo: Node2D):
	var direcao = alvo.global_position - global_position
	$AnimatedSprite2D.rotation = direcao.angle() + PI / 2.0


func _on_frame_changed():
	if _alvo_pendente != null and $AnimatedSprite2D.frame >= frame_disparo:
		var alvo = _alvo_pendente
		_alvo_pendente = null
		_disparar(alvo)


func _on_animacao_terminou():
	# Terminou de recarregar: volta para a pose "pronta" (quadro 0)
	if _alvo_pendente != null:      # segurança: se o frame_disparo estiver fora da animação
		var alvo = _alvo_pendente
		_alvo_pendente = null
		_disparar(alvo)
	$AnimatedSprite2D.frame = 0


func _disparar(alvo):
	if not is_instance_valid(alvo):
		return

	if projetil_cena:
		var projetil = projetil_cena.instantiate()
		projetil.global_position = global_position
		projetil.alvo = alvo
		projetil.dano = dano
		projetil.tipo_dano = tipo_dano
		projetil.burn_dano_por_tick = burn_dano_por_tick
		projetil.burn_duracao = burn_duracao
		get_tree().current_scene.add_child(projetil)
	else:
		match tipo_dano:
			"Fogo":
				alvo.aplicar_burn(burn_dano_por_tick, burn_duracao)
			_:
				alvo.receber_dano(dano)


# Faz a animação inteira durar um pouco menos que a cadência,
# assim ela termina (arma recarregada) antes do próximo tiro.
func _ajustar_velocidade_animacao():
	var frames: SpriteFrames = $AnimatedSprite2D.sprite_frames
	if frames == null or not frames.has_animation("default"):
		return
	var duracao_natural = frames.get_frame_count("default") / frames.get_animation_speed("default")
	$AnimatedSprite2D.speed_scale = duracao_natural / (cadencia * 0.9)


func custo_proximo_upgrade() -> int:
	return int(custo_upgrade_base * pow(multiplicador_custo_upgrade, nivel_upgrade))


func aplicar_upgrade():
	if nivel_upgrade >= NIVEL_MAX_UPGRADE:
		return

	var custo = custo_proximo_upgrade()
	if Game.dinheiro < custo:
		return

	Game.dinheiro -= custo
	_custo_gasto_upgrades += custo
	nivel_upgrade += 1

	dano += incremento_dano_upgrade
	cadencia = max(0.1, cadencia - incremento_cadencia_upgrade)
	_timer_ataque.wait_time = cadencia
	_ajustar_velocidade_animacao()   # a animação acompanha a nova cadência


func valor_venda() -> int:
	return int((custo_pago + _custo_gasto_upgrades) * fracao_venda)


func vender():
	Game.dinheiro += valor_venda()
	_indicador_alcance.queue_free()
	queue_free()
