extends Control

@onready var coin_counter: Label = $MarginContainer/coins_container/coin_counter
@onready var wave_counter: Label = $MarginContainer/wave_container/wave_counter
@onready var life_counter: Label = $MarginContainer/life_container/life_counter


func _process(delta: float) -> void:
	coin_counter.text = str(Game.dinheiro)
	life_counter.text = str(Game.vida_jogador)
	wave_counter.text = str(Game.wave)
