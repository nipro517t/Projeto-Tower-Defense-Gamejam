extends Control

# ⚠️ @onready busca o nó DEPOIS que a cena termina de montar — precisa
# disso porque esses Labels são filhos aninhados (dentro de TopBar), não
# dá pra acessar antes da árvore existir de verdade.
@onready var coin_counter: Label = $TopBar/coins_container/coin_counter
@onready var wave_counter: Label = $TopBar/wave_container/wave_counter
@onready var life_counter: Label = $TopBar/life_container/life_counter


func _process(delta: float) -> void:
	# ⚠️ Lê direto do Autoload Game a cada frame e escreve nos Labels — é a
	# forma mais simples de manter a HUD sincronizada, sem precisar de
	# sinais. Pra um jogo pequeno como este, rodar isso todo frame não pesa
	# nada (é só trocar texto, não é um cálculo pesado).
	coin_counter.text = str(Game.dinheiro)
	life_counter.text = str(Game.vida_jogador)
	wave_counter.text = str(Game.wave)
