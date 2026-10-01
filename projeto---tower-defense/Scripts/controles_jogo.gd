extends Control

@onready var botao_play_pause: Button = $HBoxControles/BotaoPlayPause
@onready var botao_velocidade: Button = $HBoxControles/BotaoVelocidade
@onready var botao_menu: Button = $HBoxControles/BotaoMenu
@onready var menu_pausa: Panel = $MenuPausa

var _velocidade_2x: bool = false
var _pausado_antes_do_menu: bool = false


func _ready():
	# ⚠️ ALWAYS: sem isso, os próprios botões (e o atalho ESC) ficariam
	# congelados junto com o resto do jogo enquanto pausado — um impasse.
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_pausa.visible = false

	botao_play_pause.pressed.connect(_alternar_play_pause)
	botao_velocidade.pressed.connect(_alternar_velocidade)
	botao_menu.pressed.connect(_abrir_menu)

	$MenuPausa/VBox/BotaoContinuar.pressed.connect(_fechar_menu)
	$MenuPausa/VBox/BotaoVoltarMenu.pressed.connect(_voltar_ao_menu)
	$MenuPausa/VBox/BotaoSair.pressed.connect(func(): get_tree().quit())
	# "Configurações" ainda não tem tela — conectar a ação quando existir.

	_atualizar_texto_play_pause()
	_atualizar_texto_velocidade()


# ESC: cancela a torre da mão, ou abre/fecha o menu de pausa.
func _unhandled_input(event):
	if not event.is_action_pressed("ui_cancel"):
		return

	# Não abre o menu por cima da tela de Game Over / Vitória
	if Game.has_method("partida_acabou") and Game.partida_acabou():
		return

	get_viewport().set_input_as_handled()

	if menu_pausa.visible:
		_fechar_menu()
		return

	# Se o jogador está com uma torre selecionada na loja, o primeiro ESC só cancela ela
	var loja = get_node_or_null("../ShopPanel")
	if loja != null and "torre_selecionada" in loja and loja.torre_selecionada != null:
		loja.torre_selecionada = null
		return

	_abrir_menu()


func _alternar_play_pause():
	if menu_pausa.visible:
		return  # com o menu aberto, o jogo fica pausado até fechar o menu
	get_tree().paused = !get_tree().paused
	_atualizar_texto_play_pause()


func _atualizar_texto_play_pause():
	botao_play_pause.text = "Play" if get_tree().paused else "Pause"


func _alternar_velocidade():
	if menu_pausa.visible:
		return
	_velocidade_2x = !_velocidade_2x
	Engine.time_scale = 2.0 if _velocidade_2x else 1.0
	_atualizar_texto_velocidade()


func _atualizar_texto_velocidade():
	# O texto mostra a velocidade ATUAL: "2x" quando já está em 2x.
	botao_velocidade.text = "2x" if _velocidade_2x else "1x"


func _abrir_menu():
	_pausado_antes_do_menu = get_tree().paused   # lembra se já estava pausado
	get_tree().paused = true
	menu_pausa.visible = true
	_travar_botoes(true)
	_atualizar_texto_play_pause()


func _fechar_menu():
	get_tree().paused = _pausado_antes_do_menu   # volta ao estado anterior
	menu_pausa.visible = false
	_travar_botoes(false)
	_atualizar_texto_play_pause()


# Enquanto o menu está aberto, os botões do topo ficam desativados.
func _travar_botoes(travar: bool):
	botao_play_pause.disabled = travar
	botao_velocidade.disabled = travar
	botao_menu.disabled = travar


func _voltar_ao_menu():
	Engine.time_scale = 1.0  # sem isso, o menu principal herdaria a velocidade 2x
	Game.resetar_estado()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/menu_principal.tscn")
