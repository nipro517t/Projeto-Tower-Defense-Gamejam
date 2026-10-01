extends Node2D

# ⚠️ Essa referência aponta pro script do painel da loja, pra ler qual
# torre está selecionada. Arraste o nó ShopPanel aqui no Inspector.
@export var loja: Panel

# Path2D da fase. Se ficar vazio, o script procura um nó chamado "Path2D" na cena.
@export var caminho: Path2D
# Metade da largura/altura do espaço que a torre ocupa no chão.
@export var meia_pegada: Vector2 = Vector2(36, 48)
# Metade da largura da estrada (64 px de largura -> 32) e uma folga extra.
@export var meia_largura_estrada: float = 32.0
@export var folga_caminho: float = 4.0

var _preview: Node2D = null
var _cena_no_preview: PackedScene = null  # guarda qual cena o preview atual representa


func _ready():
	# ⚠️ ALWAYS faz esse nó continuar recebendo clique e _process mesmo com
	# o jogo pausado — necessário pra poder comprar/posicionar torre ANTES
	# de apertar "Play" (a partida em si começa pausada, ver controles_jogo.gd).
	process_mode = Node.PROCESS_MODE_ALWAYS

	if caminho == null:
		caminho = get_tree().current_scene.get_node_or_null("Path2D")


func _process(_delta):
	# ⚠️ Sempre que a seleção na loja muda (escolheu outra torre, ou
	# cancelou/já posicionou), recria o preview do zero.
	if loja.torre_selecionada != _cena_no_preview:
		_atualizar_preview()

	if _preview:
		_preview.global_position = get_global_mouse_position()
		# Preview fica vermelho quando o local não é permitido
		if _pode_construir(_preview.global_position):
			_preview.modulate = Color(1, 1, 1)
		else:
			_preview.modulate = Color(1, 0.35, 0.35)


# Retorna false se a torre encostaria na estrada ou em outra torre.
func _pode_construir(pos: Vector2) -> bool:
	# 1) A área ocupada pela torre não pode tocar a estrada.
	#    Testa 9 pontos (cantos, meios das bordas e centro) da área da torre.
	if caminho != null and caminho.curve != null:
		var minimo := meia_largura_estrada + folga_caminho
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var ponto := pos + Vector2(dx * meia_pegada.x, dy * meia_pegada.y)
				var mais_perto := caminho.curve.get_closest_point(caminho.to_local(ponto))
				if ponto.distance_to(caminho.to_global(mais_perto)) < minimo:
					return false

	# 2) A área da torre não pode se sobrepor à de outra torre.
	for outra in get_tree().get_nodes_in_group("torres"):
		if not is_instance_valid(outra):
			continue
		var d: Vector2 = outra.global_position - pos
		if absf(d.x) < meia_pegada.x * 2.0 and absf(d.y) < meia_pegada.y * 2.0:
			return false

	return true


func _atualizar_preview():
	_cena_no_preview = loja.torre_selecionada

	if _preview:
		_preview.queue_free()
		_preview = null

	if _cena_no_preview == null:
		return

	# ⚠️ Instanciamos a torre de verdade só pra LER o alcance (raio da
	# CollisionShape2D) e copiar as texturas (base + arma) — depois
	# descartamos essa instância.
	var torre_real = _cena_no_preview.instantiate()
	var raio = torre_real.get_node("Area2D/CollisionShape2D").shape.radius
	var sprite_original = torre_real.get_node("Sprite2D")
	var textura = sprite_original.texture
	var escala = sprite_original.scale
	var pos_base = sprite_original.position

	# ⚠️ A arma (AnimatedSprite2D) também entra no preview.
	var arma_original = torre_real.get_node("AnimatedSprite2D")
	var frames_arma = arma_original.sprite_frames
	var pos_arma = arma_original.position
	var z_index_arma = arma_original.z_index

	torre_real.queue_free()

	_preview = Node2D.new()
	add_child(_preview)

	var sprite_preview = Sprite2D.new()
	sprite_preview.texture = textura
	sprite_preview.scale = escala
	sprite_preview.position = pos_base
	sprite_preview.modulate = Color(1, 1, 1, 0.5)  # transparência
	_preview.add_child(sprite_preview)

	var arma_preview = AnimatedSprite2D.new()
	arma_preview.sprite_frames = frames_arma
	arma_preview.frame = 0  # ⚠️ só uma pose fixa pro preview
	arma_preview.position = pos_arma
	arma_preview.z_index = z_index_arma
	arma_preview.modulate = Color(1, 1, 1, 0.5)
	_preview.add_child(arma_preview)

	var indicador = Node2D.new()
	_preview.add_child(indicador)
	indicador.draw.connect(func():
		indicador.draw_arc(Vector2.ZERO, raio, 0, TAU, 64, Color(1, 1, 1, 0.6), 2.0)
	)
	indicador.queue_redraw()


func _unhandled_input(event):
	if loja.torre_selecionada == null:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Não deixa construir em cima da estrada nem de outra torre (a torre continua na mão)
		if not _pode_construir(get_global_mouse_position()):
			print("Não dá pra construir aqui!")
			return

		if Game.dinheiro >= loja.custo_selecionado:
			var torre = loja.torre_selecionada.instantiate()
			torre.global_position = get_global_mouse_position()
			torre.custo_pago = loja.custo_selecionado  # ⚠️ guardado pra calcular o valor de revenda depois
			torre.add_to_group("torres")               # usado pra impedir torre sobre torre
			get_tree().current_scene.add_child(torre)
			Game.dinheiro -= loja.custo_selecionado
			loja.torre_selecionada = null
		else:
			print("Dinheiro insuficiente!")
