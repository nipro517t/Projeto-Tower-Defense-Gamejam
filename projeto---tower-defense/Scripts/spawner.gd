extends Node

@export var inimigo_cena: PackedScene
@export var path: Path2D

func _ready():
	var tempo = Timer.new()
	tempo.wait_time = 2.0 # tempo para spawnar outro inimigo
	tempo.timeout.connect(_spawnar_inimigo)
	add_child(tempo)
	tempo.start()



func _spawnar_inimigo():
	var caminho = PathFollow2D.new()
	caminho.loop = false
	path.add_child(caminho)
	
	var inimigo = inimigo_cena.instantiate()
	inimigo.path_follow = caminho
	inimigo.global_position = caminho.global_position
	add_child(inimigo)
	
