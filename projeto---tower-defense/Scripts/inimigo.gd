extends Area2D

@export var velocidade: float = 100.0  # pixels por segundo, controla o ritmo de movimento
@export var vida_max: int = 10         # vida inicial do inimigo

var vida: int                # vida atual, diminui ao receber dano
var path_follow: PathFollow2D  # referência ao "marcador" no caminho; atribuída pelo spawner, começa vazia

func _ready():
	vida = vida_max  # sem isso, vida começaria em 0 (padrão de int) e o inimigo "nasceria morto"

func _process(delta):
	# multiplicar por delta garante velocidade consistente independente do FPS
	path_follow.progress += velocidade * delta
	global_position = path_follow.global_position  # copia a posição calculada pelo PathFollow2D

	if path_follow.progress_ratio >= 1.0:  # >= em vez de == porque progress_ratio pode "pular" o valor exato de 1.0
		morrer(false)

func receber_dano(quantidade: int):
	vida -= quantidade
	if vida <= 0:
		morrer(true)

func morrer(morte: bool):
	
	if morte:
		path_follow.queue_free()
		queue_free()
	else:
		Game.vida_jogador -= 1
		path_follow.queue_free()
		queue_free()
