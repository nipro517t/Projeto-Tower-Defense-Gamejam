extends Panel

@onready var botao_toggle: Button = $BotaoToggle

# ⚠️ Cada torre da loja tem sua própria cena e seu próprio preço —
# arraste torre.tscn/torre_burn.tscn e ajuste os custos aqui no Inspector.
@export var cena_torre_normal: PackedScene
@export var cena_torre_fogo: PackedScene
@export var custo_torre_normal: int = 50
@export var custo_torre_fogo: int = 80

var aberto: bool = false
# ⚠️ ajuste esse valor pra bater com a largura real que você quer pro painel
var largura_painel: float = 135
var _offset_fechado: float = 0.0
var _offset_aberto: float

# ⚠️ Lidas por fora (gerenciador_torres.gd) pra saber qual torre comprar e
# quanto custa — é assim que o painel da loja "avisa" o resto do jogo sem
# precisar de sinal nenhum, só expondo essas duas variáveis públicas.
var torre_selecionada: PackedScene = null
var custo_selecionado: int = 0


func _ready():
	_offset_aberto = -largura_painel
	offset_left = _offset_fechado  # começa fechado (largura 0)
	botao_toggle.pressed.connect(_alternar)
	_conectar_botoes_de_compra()


func _alternar():
	aberto = !aberto
	var alvo = _offset_aberto if aberto else _offset_fechado

	# ⚠️ create_tween() é a API de animação do Godot 4 (substituiu o nó
	# Tween do Godot 3). tween_property anima QUALQUER propriedade numérica
	# de qualquer objeto, suavemente, ao longo do tempo.
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "offset_left", alvo, 0.3)


func _conectar_botoes_de_compra():
	# ⚠️ func(): ... cria uma função anônima na hora — evita escrever uma
	# função separada só pra chamar _selecionar com valores diferentes
	# pra cada botão.
	$MarginContainer/ScrollContainer/GridContainer/BtnTorrePadrao.pressed.connect(
		func(): _selecionar(cena_torre_normal, custo_torre_normal)
	)
	$MarginContainer/ScrollContainer/GridContainer/BtnTorreBurn.pressed.connect(
		func(): _selecionar(cena_torre_fogo, custo_torre_fogo)
	)


func _selecionar(cena: PackedScene, custo: int):
	# ⚠️ Só guarda a escolha — quem realmente instancia e posiciona a torre
	# é o gerenciador_torres.gd, lendo essas duas variáveis a cada clique
	# no mapa.
	torre_selecionada = cena
	custo_selecionado = custo
