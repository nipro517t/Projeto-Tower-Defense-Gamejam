extends Node2D

# ⚠️ Essa referência aponta pro script do painel da loja, pra ler qual
# torre está selecionada. Arraste o nó ShopPanel aqui no Inspector.
@export var loja: Panel

# Path2D da fase. Se ficar vazio, o script procura um nó chamado "Path2D" na cena.
@export var caminho: Path2D
# Distância mínima do CENTRO da torre até a linha do caminho (em pixels).
@export var distancia_minima: float = 48.0

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
		# Preview fica vermelho quando o local não é permitido (em cima do caminho)
		if _pode_construir(_preview.global_position):
			_preview.modulate = Color(1, 1, 1)
		else:
			_preview.modulate = Color(1, 0.35, 0.35)


# Retorna false se a posição estiver perto demais da linha do caminho.
func _pode_construir(pos: Vector2) -> bool:
	if caminho == null or caminho.curve == null:
		return true
	var ponto_local := caminho.curve.get_closest_point(caminho.to_local(pos))
	var ponto_global := caminho.to_global(ponto_local)
	return pos.distance_to(ponto_global) >= distancia_minima


func _atualizar_preview():
	_cena_no_preview = loja.torre_selecionada

	if _preview:
		_preview.queue_free()
		_preview = null

	if _cena_no_preview == null:
		return

	# ⚠️ Instanciamos a torre de verdade só pra LER o alcance (raio da
	# CollisionShape2D) e copiar as texturas (base + arma) — depois
	# descartamos essa instância. Assim o preview é só visual, sem Area2D
	# nem Timer de ataque, e não afeta o jogo de verdade enquanto está "na mão".
	var torre_real = _cena_no_preview.instantiate()
	var raio = torre_real.get_node("Area2D/CollisionShape2D").shape.radius
	var sprite_original = torre_real.get_node("Sprite2D")
	var textura = sprite_original.texture
	var escala = sprite_original.scale
	var pos_base = sprite_original.position

	# ⚠️ A arma (AnimatedSprite2D) também entra no preview — sem isso, o
	# preview mostrava só a base, sem a arma por cima.
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
	arma_preview.frame = 0  # ⚠️ só uma pose fixa pro preview, não precisa mirar em nada ainda
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
		# Não deixa construir em cima do caminho (a torre continua na mão)
		if not _pode_construir(get_global_mouse_position()):
			print("Não dá pra construir no caminho!")
			return

		if Game.dinheiro >= loja.custo_selecionado:
			var torre = loja.torre_selecionada.instantiate()
			torre.global_position = get_global_mouse_position()
			torre.custo_pago = loja.custo_selecionado  # ⚠️ guardado pra calcular o valor de revenda depois
			get_tree().current_scene.add_child(torre)
			Game.dinheiro -= loja.custo_selecionado
			loja.torre_selecionada = null
		else:
			print("Dinheiro insuficiente!")
