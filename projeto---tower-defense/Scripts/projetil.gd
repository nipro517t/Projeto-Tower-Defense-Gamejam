extends Node2D

# ⚠️ Preenchidos pela torre logo depois de instanciar o projétil — não são
# @export porque não fazem sentido configurar no editor, só em runtime.
var alvo: Node2D = null
var dano: int = 0
var tipo_dano: String = "Normal"
var burn_dano_por_tick: int = 0
var burn_duracao: float = 0.0

@export var velocidade: float = 500.0
# ⚠️ Ajuste este valor se o sprite aparecer "de lado" — ele compensa a
# direção em que o desenho original aponta (0° = desenhado apontando pra
# direita; 90° = desenhado apontando pra cima, etc).
@export var offset_rotacao_graus: float = 90.0

func _ready():
	#Bug do projetil aparecer reto por 1 frame
	if is_instance_valid(alvo):
		rotation = (alvo.global_position - global_position).angle() + deg_to_rad(offset_rotacao_graus)
		
func _process(delta):
	if not is_instance_valid(alvo):
		# ⚠️ O inimigo já morreu (por outra torre, por exemplo) antes do
		# projétil chegar — some sem aplicar dano em vez de dar erro.
		queue_free()
		return

	var direcao = alvo.global_position - global_position

	# ⚠️ "sempre vai acertar": persegue a posição ATUAL do alvo todo frame,
	# em vez de mirar num ponto fixo — mesmo que o inimigo se mova, o
	# projétil corrige o rumo e conecta.
	if direcao.length() < 12.0:
		_atingir()
		return

	global_position += direcao.normalized() * velocidade * delta
	rotation = direcao.angle() + deg_to_rad(offset_rotacao_graus)


func _atingir():
	if is_instance_valid(alvo):
		match tipo_dano:
			"Fogo":
				alvo.aplicar_burn(burn_dano_por_tick, burn_duracao)
			_:
				alvo.receber_dano(dano)
	queue_free()
