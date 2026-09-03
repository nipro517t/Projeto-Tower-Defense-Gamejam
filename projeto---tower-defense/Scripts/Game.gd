extends Node

var vida_jogador = 100
var dinheiro = 500

func _process(delta: float) -> void:
	print(vida_jogador)
	
	if vida_jogador <= 0:
		game_over(true)
	
func game_over(over: bool):
	
	if over:
		get_tree().paused = true
		pass
	else:
		pass
