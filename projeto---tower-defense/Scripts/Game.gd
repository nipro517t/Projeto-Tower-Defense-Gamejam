extends Node

signal torre_selecionada_info(torre)
signal vitoria

var vida_jogador = 100
var dinheiro = 500
var wave = 1

var _game_over_ativo: bool = false
var _vitoria_ativa: bool = false
var _tela_game_over: CanvasLayer = null
var _tela_vitoria: CanvasLayer = null


func _ready():
	# Começa pausado até o jogador apertar "Play" no controles_jogo.gd
	get_tree().paused = true


func _process(delta: float) -> void:
	if vida_jogador <= 0:
		game_over(true)


func game_over(over: bool):
	if over:
		if _game_over_ativo or _vitoria_ativa:
			return
		_game_over_ativo = true
		get_tree().paused = true
		_mostrar_tela_game_over()
	else:
		_game_over_ativo = false


func resetar_estado():
	Engine.time_scale = 1.0
	vida_jogador = 100
	dinheiro = 500
	wave = 1
	_game_over_ativo = false
	_vitoria_ativa = false
	if _tela_game_over:
		_tela_game_over.queue_free()
		_tela_game_over = null
	if _tela_vitoria:
		_tela_vitoria.queue_free()
		_tela_vitoria = null


# O Spawner chama isto quando a última onda acabou e não sobrou inimigo.
func checar_vitoria():
	if _game_over_ativo or _vitoria_ativa or vida_jogador <= 0:
		return
	_vitoria_ativa = true
	get_tree().paused = true
	vitoria.emit()
	_mostrar_tela_vitoria()


func _mostrar_tela_game_over():
	_tela_game_over = _criar_tela("GAME OVER", "Reiniciar")


func _mostrar_tela_vitoria():
	_tela_vitoria = _criar_tela("VITÓRIA!", "Jogar de novo")


# Monta uma tela (fundo meio transparente + título + 2 botões) por código.
func _criar_tela(texto_titulo: String, texto_botao: String) -> CanvasLayer:
	var camada = CanvasLayer.new()
	camada.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(camada)

	var fundo = ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.65)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(fundo)

	var centro = CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(centro)

	var caixa = VBoxContainer.new()
	centro.add_child(caixa)

	var titulo = Label.new()
	titulo.text = texto_titulo
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 48)
	caixa.add_child(titulo)

	var botao = Button.new()
	botao.text = texto_botao
	botao.process_mode = Node.PROCESS_MODE_ALWAYS
	botao.pressed.connect(_reiniciar)
	caixa.add_child(botao)

	var botao_menu = Button.new()
	botao_menu.text = "Voltar ao Menu"
	botao_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	botao_menu.pressed.connect(_voltar_ao_menu)
	caixa.add_child(botao_menu)

	return camada


func _reiniciar():
	resetar_estado()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _voltar_ao_menu():
	resetar_estado()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/menu_principal.tscn")
