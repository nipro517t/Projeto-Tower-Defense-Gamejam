extends Node

var vida_jogador = 100
var dinheiro = 500
var wave = 1

var _game_over_ativo: bool = false
# ⚠️ Guarda a referência da tela criada, pra poder remover ela explicitamente
# depois — sem isso, reload_current_scene() não a remove sozinha (ver abaixo).
var _tela_game_over: CanvasLayer = null


func _process(delta: float) -> void:
	if vida_jogador <= 0:
		game_over(true)


func game_over(over: bool):
	if over:
		if _game_over_ativo:
			return
		_game_over_ativo = true
		get_tree().paused = true
		_mostrar_tela_game_over()
	else:
		_game_over_ativo = false


func _mostrar_tela_game_over():
	var camada = CanvasLayer.new()
	camada.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(camada)
	_tela_game_over = camada  # ⚠️ guarda a referência pra poder limpar depois

	var fundo = ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.7)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(fundo)

	var centro = CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(centro)

	var caixa = VBoxContainer.new()
	centro.add_child(caixa)

	var titulo = Label.new()
	titulo.text = "GAME OVER"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 48)
	caixa.add_child(titulo)

	var botao = Button.new()
	botao.text = "Reiniciar"
	botao.process_mode = Node.PROCESS_MODE_ALWAYS
	botao.pressed.connect(_reiniciar)
	caixa.add_child(botao)


func _reiniciar():
	# ⚠️ Bug 1 corrigido aqui: remove explicitamente a tela de Game Over,
	# já que ela é filha de "root" (irmã da cena), não da cena que recarrega.
	if _tela_game_over:
		_tela_game_over.queue_free()
		_tela_game_over = null

	# ⚠️ Bug 2 corrigido aqui: Autoload NÃO reseta sozinho ao recarregar a
	# cena — sem isso, vida_jogador continuaria <= 0 e o jogo entraria em
	# Game Over de novo no frame seguinte, instantaneamente.
	vida_jogador = 100
	dinheiro = 500
	wave = 1
	_game_over_ativo = false

	get_tree().paused = false
	get_tree().reload_current_scene()
