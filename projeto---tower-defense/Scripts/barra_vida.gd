extends Node2D
## Barra de vida que fica em cima do inimigo (moldura de madeira + preenchimento vermelho).
## O inimigo cria este nó sozinho e chama atualizar() sempre que a vida muda.

const CAMINHO_BASE := "res://Assets/UI/barra_vida_base.png"
const CAMINHO_FILL := "res://Assets/UI/barra_vida_fill.png"
const POS_FILL := Vector2(2, 2)   # onde o preenchimento começa dentro da moldura (em pixels)

var _fill: Sprite2D = null
var _largura_cheia: int = 0
var _altura: int = 0


func _ready():
	var tex_base := load(CAMINHO_BASE) as Texture2D
	var tex_fill := load(CAMINHO_FILL) as Texture2D
	if tex_base == null or tex_fill == null:
		push_error("Imagens da barra de vida não encontradas em res://Assets/UI/")
		return

	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var canto := -tex_base.get_size() / 2.0   # centraliza a barra no ponto do nó

	var base := Sprite2D.new()
	base.texture = tex_base
	base.centered = false
	base.position = canto
	add_child(base)

	_largura_cheia = tex_fill.get_width()
	_altura = tex_fill.get_height()
	_fill = Sprite2D.new()
	_fill.texture = tex_fill
	_fill.centered = false
	_fill.position = canto + POS_FILL
	_fill.region_enabled = true
	add_child(_fill)

	atualizar(1.0)


# ratio: 1.0 = vida cheia, 0.0 = sem vida
func atualizar(ratio: float):
	if _fill == null:
		return
	ratio = clampf(ratio, 0.0, 1.0)
	var largura := int(round(_largura_cheia * ratio))
	if ratio > 0.0 and largura < 1:
		largura = 1
	_fill.region_rect = Rect2(0, 0, largura, _altura)
	_fill.visible = largura > 0
