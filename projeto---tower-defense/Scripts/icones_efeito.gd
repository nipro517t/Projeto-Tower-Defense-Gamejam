extends Node2D
## Mostra ícones dos efeitos (fogo, gelo...) em cima do inimigo enquanto durarem.

# Para um efeito novo: ponha o PNG na pasta e adicione uma linha aqui.
const CAMINHOS := {
	"fogo": "res://Assets/Efeitos/icone_fogo.png",
	"gelo": "res://Assets/Efeitos/icone_gelo.png",
}
const TAMANHO_ICONE := 22.0            # largura do ícone na tela, em pixels
const ESPACO := 4.0                    # espaço entre ícones
const DESLOCAMENTO := Vector2(0, -30)  # posição em relação ao inimigo

var _restante := {}   # efeito -> segundos que faltam
var _sprites := {}    # efeito -> Sprite2D


func _ready():
	top_level = true   # não herda rotação/escala do inimigo
	z_index = 10       # desenha por cima de tudo


# Chame quando o inimigo receber um efeito. Se ele já tiver, só renova a duração.
func mostrar(efeito: String, duracao: float):
	_restante[efeito] = max(duracao, _restante.get(efeito, 0.0))
	if _sprites.has(efeito):
		return

	var caminho: String = CAMINHOS.get(efeito, "")
	if caminho == "" or not ResourceLoader.exists(caminho):
		push_warning("Ícone não encontrado para o efeito: " + efeito)
		_restante.erase(efeito)
		return

	var s = Sprite2D.new()
	s.texture = load(caminho)
	var k = TAMANHO_ICONE / s.texture.get_size().x
	s.scale = Vector2(k, k)
	add_child(s)
	_sprites[efeito] = s
	_reorganizar()


func _process(delta):
	var pai = get_parent()
	if pai is Node2D:
		global_position = pai.global_position + DESLOCAMENTO

	for efeito in _restante.keys():
		_restante[efeito] -= delta
		var s: Sprite2D = _sprites[efeito]
		if _restante[efeito] <= 0.0:
			s.queue_free()
			_sprites.erase(efeito)
			_restante.erase(efeito)
			_reorganizar()
		elif _restante[efeito] < 0.6:
			s.modulate.a = 0.4 + 0.6 * abs(sin(_restante[efeito] * 12.0))  # pisca perto do fim
		else:
			s.modulate.a = 1.0


# Centraliza os ícones lado a lado (quando o inimigo tem mais de um efeito).
func _reorganizar():
	var n = _sprites.size()
	var i = 0
	for s in _sprites.values():
		s.position.x = (i - (n - 1) / 2.0) * (TAMANHO_ICONE + ESPACO)
		i += 1
