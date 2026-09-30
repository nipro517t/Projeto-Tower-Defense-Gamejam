extends Control

# ⚠️ Estes dois métodos são chamados pelos sinais "pressed" dos botões
# BtnJogar e BtnQuit — a ligação NÃO está aqui no código, está na própria
# cena (menu_principal.tscn), feita pelo editor (aba Nó > Sinais). Por
# isso não existe um _ready() conectando nada — o Godot já faz isso
# sozinho ao carregar a cena, lendo os "[connection]" salvos no .tscn.


func _on_btn_jogar_pressed() -> void:
	# ⚠️ change_scene_to_file troca a cena inteira (diferente de
	# reload_current_scene, que recarrega a MESMA cena do zero) — usado
	# pra navegar entre telas diferentes do jogo (menu → seleção → fase).
	get_tree().change_scene_to_file("res://Scenes/selecao_fases.tscn")


func _on_btn_quit_pressed() -> void:
	get_tree().quit()
