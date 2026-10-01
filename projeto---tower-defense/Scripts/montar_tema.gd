@tool
extends EditorScript
## Cria o tema de UI (botões, painéis e fitas de título) a partir dos PNGs de res://Assets/UI/
## e salva em res://Assets/UI/tema_ui.tres.
##
## COMO USAR: abra este script no editor de scripts e use Arquivo > Executar.
## Pode rodar de novo quando quiser: ele recria o tema.

const PASTA := "res://Assets/UI/"
const SAIDA := "res://Assets/UI/tema_ui.tres"

const COR_TEXTO := Color(1, 1, 1)
const COR_TEXTO_DESATIVADO := Color(0.7, 0.72, 0.76)
const COR_CONTORNO := Color(0.086, 0.11, 0.18)   # azul-marinho da arte


func _run() -> void:
	var tema := Theme.new()

	# Botões: azul é o padrão; "BotaoVermelho" é uma variação (Theme Type Variation)
	_botao(tema, "Button", "azul")
	tema.set_type_variation("BotaoVermelho", "Button")
	_botao(tema, "BotaoVermelho", "vermelho")

	# Painéis (menu de pausa, janelas)
	var painel := _caixa("painel_escuro.png", [23, 18, 23, 18], [28, 22, 28, 22])
	tema.set_stylebox("panel", "Panel", painel)
	tema.set_stylebox("panel", "PanelContainer", painel)

	# Títulos em fita (Theme Type Variation "TituloFita" e "TituloFitaVermelha" no Label)
	_titulo(tema, "TituloFita", "azul")
	_titulo(tema, "TituloFitaVermelha", "vermelho")

	var erro := ResourceSaver.save(tema, SAIDA)
	if erro != OK:
		push_error("Não consegui salvar %s (erro %d)." % [SAIDA, erro])
		return
	EditorInterface.get_resource_filesystem().scan()
	print("Tema salvo em ", SAIDA)


func _botao(tema: Theme, tipo: String, cor: String) -> void:
	var estados := {
		"normal": "normal",
		"hover": "hover",
		"pressed": "pressionado",
		"disabled": "desativado",
	}
	for estilo in estados:
		var arquivo := "botao_%s_%s.png" % [cor, estados[estilo]]
		tema.set_stylebox(estilo, tipo, _caixa(arquivo, [18, 17, 18, 18], [14, 8, 14, 10]))
	tema.set_stylebox("focus", tipo, StyleBoxEmpty.new())

	tema.set_color("font_color", tipo, COR_TEXTO)
	tema.set_color("font_hover_color", tipo, COR_TEXTO)
	tema.set_color("font_pressed_color", tipo, COR_TEXTO)
	tema.set_color("font_hover_pressed_color", tipo, COR_TEXTO)
	tema.set_color("font_focus_color", tipo, COR_TEXTO)
	tema.set_color("font_disabled_color", tipo, COR_TEXTO_DESATIVADO)
	tema.set_color("font_outline_color", tipo, COR_CONTORNO)
	tema.set_constant("outline_size", tipo, 4)


func _titulo(tema: Theme, tipo: String, cor: String) -> void:
	tema.set_type_variation(tipo, "Label")
	tema.set_stylebox("normal", tipo, _caixa("fita_%s.png" % cor, [59, 0, 58, 0], [70, 14, 70, 14]))
	tema.set_color("font_color", tipo, COR_TEXTO)
	tema.set_color("font_outline_color", tipo, COR_CONTORNO)
	tema.set_constant("outline_size", tipo, 6)
	tema.set_font_size("font_size", tipo, 30)


# m = margens do 9-slice [esq, cima, dir, baixo]; c = margens de conteúdo (espaço do texto)
func _caixa(arquivo: String, m: Array, c: Array) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(PASTA + arquivo) as Texture2D
	if sb.texture == null:
		push_error("Imagem não encontrada: %s%s (espere o Godot terminar de importar e rode de novo)" % [PASTA, arquivo])
	sb.texture_margin_left = m[0]
	sb.texture_margin_top = m[1]
	sb.texture_margin_right = m[2]
	sb.texture_margin_bottom = m[3]
	sb.content_margin_left = c[0]
	sb.content_margin_top = c[1]
	sb.content_margin_right = c[2]
	sb.content_margin_bottom = c[3]
	return sb
