extends Area2D

@export var velocidade: float = 100.0
@export var vida_max: int = 10
@export var valor_recompensa: int = 25
@export var dano_na_base: int = 2   # vidas que o jogador perde quando este inimigo chega ao fim

# --- Visual (muda por variação de inimigo no Inspetor) ---
@export var cor_base: Color = Color(1, 1, 1)   # tinge o sprite todo (branco = cor original)
@export var escala_visual: float = 0.7         # tamanho do sprite

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

# --- Sprite e animação ---
const PASTA_SPRITES := "res://Assets/Inimigos/Enemy2/"
const TAM_QUADRO := 96
const FPS_ANIMACAO := 10.0
var _sprite: AnimatedSprite2D
var _pos_anterior: Vector2
var _direcao_atual: String = "S"   # D = frente, S = lado, U = costas
var _tween_cor: Tween = null

# Cores por tipo de dano. "numero" = cor do número que sobe; "sprite" = cor do
# flash no inimigo (valores acima de 1 deixam a cor mais brilhante).
# Para um tipo novo, é só adicionar uma linha aqui.
const TIPOS := {
	"normal": {"numero": Color(1.0, 0.25, 0.25), "sprite": Color(2.2, 2.2, 2.2)},
	"fogo":   {"numero": Color(1.0, 0.6, 0.1),   "sprite": Color(2.0, 1.1, 0.4)},
	"gelo":   {"numero": Color(0.5, 0.85, 1.0),  "sprite": Color(0.6, 1.2, 2.0)},
}


func _ready():
	vida = vida_max
	label.position = Vector2(-10, 22)   # número de vida abaixo dos pés do cavaleiro
	_montar_visual()
	_icones = preload("res://Scripts/icones_efeito.gd").new()
	add_child(_icones)
	_pos_anterior = global_position


# Cria o AnimatedSprite2D por código, cortando cada PNG em quadros de 96x96.
func _montar_visual():
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for direcao in ["D", "S", "U"]:
		for anim in ["Run", "Death"]:
			var nome: String = direcao + "_" + anim          # ex: "S_Run"
			var tex := load(PASTA_SPRITES + nome + ".png") as Texture2D
			if tex == null:
				push_error("Sprite não encontrado: " + PASTA_SPRITES + nome + ".png")
				return
			frames.add_animation(nome)
			frames.set_animation_speed(nome, FPS_ANIMACAO)
			frames.set_animation_loop(nome, anim == "Run")
			for i in range(int(tex.get_width() / float(TAM_QUADRO))):
				var quadro := AtlasTexture.new()
				quadro.atlas = tex
				quadro.region = Rect2(i * TAM_QUADRO, 0, TAM_QUADRO, TAM_QUADRO)
				frames.add_frame(nome, quadro)

	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(escala_visual, escala_visual)
	_sprite.modulate = cor_base
	_sprite.speed_scale = clampf(velocidade / 100.0, 0.6, 2.0)   # mais rápido = anima mais rápido
	add_child(_sprite)
	move_child(_sprite, 0)   # fica atrás do Label
	_sprite.animation_finished.connect(_on_animacao_terminou)
	_sprite.play("S_Run")


func _process(delta):
	if _morto or not is_instance_valid(path_follow):
		return

	label.text = str(vida)
	path_follow.progress += velocidade * delta
	global_position = path_follow.global_position
	_atualizar_animacao()

	if path_follow.progress_ratio >= 1.0:
		morrer(false)


# Escolhe a animação pela direção em que o inimigo está andando.
func _atualizar_animacao():
	if _sprite == null:
		return
	var deslocamento := global_position - _pos_anterior
	_pos_anterior = global_position
	if deslocamento.length() < 0.01:
		return

	if absf(deslocamento.x) >= absf(deslocamento.y):
		_direcao_atual = "S"
		_sprite.flip_h = deslocamento.x > 0.0   # a arte de lado olha para a ESQUERDA: espelha ao ir para a direita
	else:
		_direcao_atual = "D" if deslocamento.y > 0.0 else "U"
		_sprite.flip_h = false

	var nome := _direcao_atual + "_Run"
	if _sprite.animation != nome:
		var quadro := _sprite.frame
		var progresso := _sprite.frame_progress
		_sprite.play(nome)
		_sprite.set_frame_and_progress(quadro, progresso)   # não "trava" ao virar a curva


func receber_dano(quantidade: int, tipo: String = "normal"):
	if _morto:
		return
	vida -= quantidade
	_mostrar_indicador_dano(quantidade, tipo)
	_piscar(tipo)
	if vida <= 0:
		morrer(true)


func _mostrar_indicador_dano(quantidade: int, tipo: String):
	# ⚠️ Criado por código — um Label temporário que sobe e desaparece,
	# depois se autodestrói. A cor depende do tipo de dano.
	var t := tipo if TIPOS.has(tipo) else "normal"
	var indicador = Label.new()
	indicador.text = str(quantidade)
	indicador.add_theme_color_override("font_color", TIPOS[t]["numero"])
	indicador.add_theme_color_override("font_outline_color", Color.BLACK)
	indicador.add_theme_constant_override("outline_size", 4)
	indicador.z_index = 10  # garante que desenha por cima dos sprites
	get_tree().current_scene.add_child(indicador)
	indicador.global_position = global_position + Vector2(-8, -40)

	var tween = indicador.create_tween()
	# ⚠️ "position:y" tween só a coordenada Y — sobe 24px suavemente.
	tween.tween_property(indicador, "position:y", indicador.position.y - 24, 0.6)
	# ⚠️ parallel() faz o próximo tween rodar AO MESMO TEMPO que o de
	# cima — assim sobe E desaparece juntos.
	tween.parallel().tween_property(indicador, "modulate:a", 0.0, 0.6)
	tween.tween_callback(indicador.queue_free)


# Cor "de repouso" do inimigo: a base, ou alaranjada enquanto está queimando.
func _cor_estado() -> Color:
	if burn_timer != null:
		return cor_base.lerp(TIPOS["fogo"]["sprite"], 0.35)
	return cor_base


# Flash na cor do tipo de dano, voltando depois para a cor de repouso.
func _piscar(tipo: String):
	if _sprite == null or _morto:
		return
	var t := tipo if TIPOS.has(tipo) else "normal"
	if _tween_cor != null and _tween_cor.is_valid():
		_tween_cor.kill()
	_sprite.modulate = TIPOS[t]["sprite"]
	_tween_cor = create_tween()
	_tween_cor.tween_property(_sprite, "modulate", _cor_estado(), 0.25)


func _voltar_cor():
	if _sprite == null or _morto:
		return
	if _tween_cor != null and _tween_cor.is_valid():
		_tween_cor.kill()
	_tween_cor = create_tween()
	_tween_cor.tween_property(_sprite, "modulate", _cor_estado(), 0.3)


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
	_piscar("fogo")


func _tick_burn():
	receber_dano(burn_potencia, "fogo")
	burn_ticks_restantes -= 1

	if burn_ticks_restantes <= 0 and burn_timer != null:
		burn_potencia = 0
		burn_timer.queue_free()
		burn_timer = null
		_voltar_cor()


func morrer(morte: bool):
	if _morto:
		return
	_morto = true

	if morte:
		Game.dinheiro += valor_recompensa
		_tocar_morte()
	else:
		Game.vida_jogador -= dano_na_base
		_remover()


# Toca a animação de morte e só some quando ela termina.
func _tocar_morte():
	# sai da lista de alvos das torres (elas recebem area_exited)
	set_deferred("monitorable", false)
	label.visible = false
	_icones.visible = false
	if burn_timer != null:
		burn_timer.stop()

	if _sprite == null:
		_remover()
		return
	if _tween_cor != null and _tween_cor.is_valid():
		_tween_cor.kill()
	_sprite.modulate = cor_base
	_sprite.speed_scale = 1.0

	var nome := _direcao_atual + "_Death"
	if _sprite.sprite_frames.has_animation(nome):
		_sprite.play(nome)   # o animation_finished chama _remover()
	else:
		_remover()


func _on_animacao_terminou():
	if _morto:
		_remover()


# o PathFollow2D é criado pelo Spawner e pertence ao inimigo: sai junto
func _remover():
	if is_instance_valid(path_follow):
		path_follow.queue_free()
	queue_free()
