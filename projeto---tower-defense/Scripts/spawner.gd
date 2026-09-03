extends Node

@export var inimigo_cena: PackedScene  # cena a ser instanciada a cada spawn
@export var path: Path2D                # referência ao caminho do mapa (compartilhado por todos os inimigos)

func _ready():
	var tempo = Timer.new()
	tempo.wait_time = 1.0
	tempo.timeout.connect(_spawnar_inimigo)
	add_child(tempo)
	tempo.start()

func _spawnar_inimigo():
	var caminho = PathFollow2D.new()
	caminho.loop = false  # sem isso, progress_ratio nunca fica >= 1.0 (ele "dá a volta" ao chegar no fim)
	path.add_child(caminho)  # nasce como filho do Path2D já existente — não duplica a curva

	var inimigo = inimigo_cena.instantiate()
	inimigo.path_follow = caminho
	inimigo.global_position = caminho.global_position  # evita o "flash" no canto (0,0) por 1 frame
	add_child(inimigo)
