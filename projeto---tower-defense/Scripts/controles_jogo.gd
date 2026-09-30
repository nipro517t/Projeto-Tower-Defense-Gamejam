extends Control

@onready var botao_play_pause: Button = $HBoxControles/BotaoPlayPause
@onready var botao_velocidade: Button = $HBoxControles/BotaoVelocidade
@onready var botao_menu: Button = $HBoxControles/BotaoMenu
@onready var menu_pausa: Panel = $MenuPausa

var _velocidade_2x: bool = false


func _ready():
	# ⚠️ ALWAYS: sem isso, os próprios botões ficariam congelados junto
	# com o resto do jogo enquanto pausado — um impasse.
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_pausa.visible = false

	botao_play_pause.pressed.connect(_alternar_play_pause)
	botao_velocidade.pressed.connect(_alternar_velocidade)
	botao_menu.pressed.connect(_abrir_menu)

	$MenuPausa/VBox/BotaoContinuar.pressed.connect(_fechar_menu)
	$MenuPausa/VBox/BotaoVoltarMenu.pressed.connect(_voltar_ao_menu)
	$MenuPausa/VBox/BotaoSair.pressed.connect(func(): get_tree().quit())
	# ⚠️ "Configurações" ainda não tem pra onde ir (não existe tela de
	# configurações neste projeto ainda) — o botão já está criado, só
	# faltando conectar a ação quando você tiver essa tela.

	_atualizar_texto_play_pause()
	_atualizar_texto_velocidade()


func _alternar_play_pause():
	# ⚠️ Só alterna a pausa — nunca mexe no menu. Isso é intencional: você
	# pediu Play/Pause e o Menu como coisas separadas, cada botão faz só
	# uma coisa.
	get_tree().paused = !get_tree().paused
	_atualizar_texto_play_pause()


func _atualizar_texto_play_pause():
	botao_play_pause.text = "Play" if get_tree().paused else "Pause"


func _alternar_velocidade():
	_velocidade_2x = !_velocidade_2x
	Engine.time_scale = 2.0 if _velocidade_2x else 1.0
	_atualizar_texto_velocidade()


func _atualizar_texto_velocidade():
	# ⚠️ O texto mostra a velocidade ATUAL (não a ação que o clique vai
	# fazer) — aparece "2x" quando já está em 2x, "1x" quando normal.
	botao_velocidade.text = "2x" if _velocidade_2x else "1x"


func _abrir_menu():
	get_tree().paused = true
	menu_pausa.visible = true
	_atualizar_texto_play_pause()


func _fechar_menu():
	get_tree().paused = false
	menu_pausa.visible = false
	_atualizar_texto_play_pause()


func _voltar_ao_menu():
	Engine.time_scale = 1.0  # ⚠️ sem isso, o menu principal herdaria a velocidade 2x
	Game.resetar_estado()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/menu_principal.tscn")
