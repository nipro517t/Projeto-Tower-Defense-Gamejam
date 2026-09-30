extends Control

# ⚠️ O caminho precisa bater EXATAMENTE com a árvore de nós da cena.
# Em selecao_fases.tscn, os botões não são filhos diretos deste Control —
# a hierarquia real é: SelecaoFases > CenterContainer > VBox > BotaoFase1.
# Por isso o caminho começa em "CenterContainer", não direto em "VBox".
func _ready():
	$CenterContainer/VBox/BotaoFase1.pressed.connect(_jogar_fase1)
	$CenterContainer/VBox/BotaoVoltar.pressed.connect(_voltar_ao_menu)


func _jogar_fase1():
	# ⚠️ Sempre reseta o estado antes de entrar numa fase — sem isso, uma
	# partida anterior (dinheiro, vida, rodada) vazaria pra fase nova.
	Game.resetar_estado()
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")


func _voltar_ao_menu():
	get_tree().change_scene_to_file("res://Scenes/menu_principal.tscn")
