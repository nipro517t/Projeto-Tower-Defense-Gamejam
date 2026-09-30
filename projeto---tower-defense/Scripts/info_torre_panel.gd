extends Panel

@onready var label_nome: Label = $VBox/LabelNome
@onready var label_stats: Label = $VBox/LabelStats
@onready var label_prioridade: Label = $VBox/HBoxPrioridade/LabelPrioridade
@onready var botao_upgrade: Button = $VBox/BotaoUpgrade
@onready var botao_vender: Button = $VBox/BotaoVender

# ⚠️ Referências pra loja "sumir" enquanto este painel está aberto, como
# você pediu — arraste ShopPanel e BotaoToggle aqui no Inspector.
@export var loja_panel: Panel
@export var botao_abrir_loja: Button

var _torre_atual: Node2D = null
var _opcoes_prioridade: Array = ["Mais avançado", "Mais forte", "Primeiro que entrou"]


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	$VBox/HBoxPrioridade/BotaoAnterior.pressed.connect(func(): _mudar_prioridade(-1))
	$VBox/HBoxPrioridade/BotaoProximo.pressed.connect(func(): _mudar_prioridade(1))
	botao_upgrade.pressed.connect(_on_upgrade_pressionado)
	botao_vender.pressed.connect(_on_vender_pressionado)
	$VBox/BotaoFechar.pressed.connect(fechar)

	# ⚠️ Autoload avisa quando QUALQUER torre é clicada — não importa se
	# foi criada agora ou já existia na cena, todo torre.gd emite o mesmo sinal.
	Game.torre_selecionada_info.connect(mostrar)


func mostrar(torre: Node2D):
	_torre_atual = torre
	visible = true

	# ⚠️ Esconde a loja enquanto o painel de info estiver aberto, pra não
	# sobrepor um painel no outro — igual você pediu.
	loja_panel.visible = false
	botao_abrir_loja.visible = false

	_atualizar()


func fechar():
	_torre_atual = null
	visible = false

	loja_panel.visible = true
	botao_abrir_loja.visible = true


func _unhandled_input(event):
	# ⚠️ Clicar fora (no mapa vazio) fecha o painel. Cliques em cima de
	# botões ou de outra torre nunca chegam aqui (Controls e a própria
	# torre.gd já "consomem" o clique antes), então isso só pega cliques
	# genuínos no vazio.
	if visible and event is InputEventMouseButton and event.pressed:
		fechar()


func _atualizar():
	if not is_instance_valid(_torre_atual):
		fechar()
		return

	label_nome.text = "Torre de Fogo" if _torre_atual.tipo_dano == "Fogo" else "Torre Normal"
	label_stats.text = "Dano: %d\nCadência: %.1fs\nNível: %d/%d" % [
		_torre_atual.dano, _torre_atual.cadencia, _torre_atual.nivel_upgrade, _torre_atual.NIVEL_MAX_UPGRADE
	]
	label_prioridade.text = _torre_atual.prioridade_alvo

	if _torre_atual.nivel_upgrade >= _torre_atual.NIVEL_MAX_UPGRADE:
		botao_upgrade.text = "Nível máximo"
		botao_upgrade.disabled = true
	else:
		botao_upgrade.text = "Upgrade ($%d)" % _torre_atual.custo_proximo_upgrade()
		botao_upgrade.disabled = Game.dinheiro < _torre_atual.custo_proximo_upgrade()

	botao_vender.text = "Vender ($%d)" % _torre_atual.valor_venda()


func _mudar_prioridade(direcao: int):
	var indice_atual = _opcoes_prioridade.find(_torre_atual.prioridade_alvo)
	var novo_indice = (indice_atual + direcao + _opcoes_prioridade.size()) % _opcoes_prioridade.size()
	_torre_atual.prioridade_alvo = _opcoes_prioridade[novo_indice]
	_atualizar()


func _on_upgrade_pressionado():
	_torre_atual.aplicar_upgrade()
	_atualizar()


func _on_vender_pressionado():
	_torre_atual.vender()
	fechar()
