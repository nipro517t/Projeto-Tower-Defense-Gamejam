@tool
extends EditorScript
## Monta o mapa (chão + caminho de terra + decoração) da fase aberta no editor.
##
## COMO USAR
## 1. Abra a cena da fase (ex.: level_1.tscn) no editor.
## 2. Abra ESTE script no editor de scripts.
## 3. Menu Arquivo > Executar (Ctrl+Shift+X).
## Pode rodar de novo quando quiser: ele apaga o "Chao" e a "Decoracao" antigos
## e refaz tudo seguindo o Path2D atual da cena. Para mudar a decoração sorteada,
## troque o valor de SEMENTE.

const TILESET_PNG := "res://Assets/Tiles/FieldsTileset.png"
const TILESET_RES := "res://Assets/Tiles/tileset_campos.tres"
const DECOR_DIR := "res://Assets/Decor/"

const TAMANHO := 32                 # tamanho de cada tile, em pixels
const LARGURA_CAMINHO := 64.0       # largura da estrada (2 tiles)
const EXTENSAO_INICIO := 128.0      # a estrada continua para fora da tela no começo
const EXTENSAO_FIM := 0.0           # e não passa do fim do Path2D
const MARGEM := 160.0               # quanto de chão pintar além da tela
const SEMENTE := 7
const FOLGA_CAMINHO := 10.0         # espaço extra (px) entre a decoração e a estrada

const GRAMA := Vector2i(5, 4)       # tile de grama pura no FieldsTileset.png

# Qual tile usar na terra conforme os lados que encostam na grama.
# Bits: 1 = Norte, 2 = Sul, 4 = Oeste, 8 = Leste (0 = terra no meio da estrada).
const VARIANTES = {
	0: [Vector2i(0, 0), Vector2i(4, 0), Vector2i(6, 0), Vector2i(2, 1), Vector2i(5, 1), Vector2i(7, 1), Vector2i(1, 2), Vector2i(3, 2), Vector2i(6, 2), Vector2i(2, 3), Vector2i(0, 4), Vector2i(4, 4), Vector2i(4, 5), Vector2i(5, 5), Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7)],
	1: [Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(2, 6), Vector2i(6, 6), Vector2i(7, 6)],
	2: [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(3, 6), Vector2i(6, 7), Vector2i(7, 7)],
	3: [Vector2i(5, 3), Vector2i(6, 3), Vector2i(6, 4)],
	4: [Vector2i(4, 1), Vector2i(4, 2), Vector2i(4, 3), Vector2i(1, 6), Vector2i(5, 6), Vector2i(5, 7)],
	5: [Vector2i(5, 0), Vector2i(1, 1)],
	6: [Vector2i(5, 2), Vector2i(1, 3)],
	7: [Vector2i(0, 5)],
	8: [Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 6), Vector2i(4, 6), Vector2i(4, 7)],
	9: [Vector2i(7, 0), Vector2i(3, 1)],
	10: [Vector2i(7, 2), Vector2i(3, 3)],
	11: [Vector2i(1, 5)],
	12: [Vector2i(7, 3), Vector2i(7, 4), Vector2i(7, 5)],
	13: [Vector2i(2, 5)],
	14: [Vector2i(3, 5)],
	15: [Vector2i(6, 5)],
}

# nomes = arquivos em Assets/Decor, qtd = quantos tentar colocar,
# dist = distância mínima do caminho, borda = só perto das bordas da tela,
# ymin = altura mínima na tela, esp = espaço mínimo entre itens.
const REGRAS = [
	{"nomes": ["tree_1.png"], "qtd": 4, "dist": 125.0, "borda": true, "ymin": 100.0, "esp": 48.0},
	{"nomes": ["tree_2.png"], "qtd": 6, "dist": 70.0, "borda": false, "ymin": 12.0, "esp": 36.0},
	{"nomes": ["bush_1.png", "bush_2.png", "bush_3.png", "bush_4.png", "bush_5.png", "bush_6.png"], "qtd": 12, "dist": 60.0, "borda": false, "ymin": 12.0, "esp": 40.0},
	{"nomes": ["stone_1.png", "stone_3.png", "stone_4.png", "stone_6.png", "stone_9.png", "stone_13.png", "stone_14.png", "stone_15.png", "stone_16.png"], "qtd": 12, "dist": 50.0, "borda": false, "ymin": 12.0, "esp": 30.0},
	{"nomes": ["log_1.png", "log_3.png"], "qtd": 3, "dist": 60.0, "borda": false, "ymin": 12.0, "esp": 40.0},
	{"nomes": ["flower_1.png", "flower_2.png", "flower_3.png", "flower_4.png", "flower_5.png", "flower_6.png", "flower_7.png", "flower_8.png", "flower_9.png", "flower_10.png", "flower_11.png", "flower_12.png"], "qtd": 45, "dist": 40.0, "borda": false, "ymin": 12.0, "esp": 20.0},
	{"nomes": ["grass_1.png", "grass_2.png", "grass_3.png", "grass_4.png", "grass_5.png", "grass_6.png"], "qtd": 60, "dist": 38.0, "borda": false, "ymin": 12.0, "esp": 16.0},
]


func _run() -> void:
	var raiz := EditorInterface.get_edited_scene_root() as Node2D
	if raiz == null:
		push_error("Abra a cena da fase (raiz Node2D) antes de rodar o script.")
		return
	var caminho := raiz.get_node_or_null("Path2D") as Path2D
	if caminho == null or caminho.curve == null:
		push_error("Nao encontrei um Path2D com curva na cena.")
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = SEMENTE

	var tela := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1152)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 648)))

	var amostras := _amostrar_caminho(raiz, caminho)
	var off := _melhor_offset(amostras)

	var tileset := _criar_tileset()
	if tileset == null:
		return

	# apaga o que foi gerado antes
	for nome in ["Chao", "Decoracao"]:
		var antigo := raiz.get_node_or_null(nome)
		if antigo != null:
			raiz.remove_child(antigo)
			antigo.queue_free()

	# ---------- chão ----------
	var x0 := int(floor((-MARGEM - off.x) / TAMANHO))
	var x1 := int(ceil((tela.x + MARGEM - off.x) / TAMANHO))
	var y0 := int(floor((-MARGEM - off.y) / TAMANHO))
	var y1 := int(ceil((tela.y + MARGEM - off.y) / TAMANHO))
	var raio := LARGURA_CAMINHO * 0.5
	var raio2 := raio * raio

	var terra := {}
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			var centro := off + (Vector2(cx, cy) + Vector2(0.5, 0.5)) * TAMANHO
			if _dist2_min(centro, amostras) < raio2:
				terra[Vector2i(cx, cy)] = true

	var layer := TileMapLayer.new()
	layer.name = "Chao"
	layer.tile_set = tileset
	layer.position = off
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	raiz.add_child(layer)
	layer.owner = raiz
	raiz.move_child(layer, 0)

	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			var c := Vector2i(cx, cy)
			if terra.has(c):
				var m := 0
				if not terra.has(c + Vector2i(0, -1)):
					m |= 1
				if not terra.has(c + Vector2i(0, 1)):
					m |= 2
				if not terra.has(c + Vector2i(-1, 0)):
					m |= 4
				if not terra.has(c + Vector2i(1, 0)):
					m |= 8
				var lista: Array = VARIANTES[m]
				layer.set_cell(c, 0, lista[rng.randi_range(0, lista.size() - 1)])
			else:
				layer.set_cell(c, 0, GRAMA)

	# ---------- decoração ----------
	var deco := Node2D.new()
	deco.name = "Decoracao"
	deco.y_sort_enabled = true
	deco.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	raiz.add_child(deco)
	deco.owner = raiz
	raiz.move_child(deco, 1)

	var pos_final := Vector2(-99999.0, -99999.0)
	var no_final := raiz.get_node_or_null("Final") as Node2D
	if no_final != null:
		pos_final = no_final.position

	var ocupados: Array[Vector2] = []
	var faltando := {}
	for regra in REGRAS:
		var nomes: Array = regra["nomes"]
		var dist_min: float = regra["dist"]
		var esp: float = regra["esp"]
		var ymin: float = regra["ymin"]
		var so_borda: bool = regra["borda"]
		var colocados := 0
		var tentativas := 0
		while colocados < int(regra["qtd"]) and tentativas < 400:
			tentativas += 1
			var p := Vector2(
				rng.randf_range(4.0, tela.x - 4.0),
				rng.randf_range(ymin, tela.y - 4.0))
			if so_borda and not _perto_da_borda(p, tela, 110.0):
				continue
			if _dist2_min(p, amostras) < dist_min * dist_min:
				continue
			if p.distance_to(pos_final) < 110.0:
				continue
			var livre := true
			for o in ocupados:
				if o.distance_to(p) < esp:
					livre = false
					break
			if not livre:
				continue
			var arquivo: String = nomes[rng.randi_range(0, nomes.size() - 1)]
			var tex := load(DECOR_DIR + arquivo) as Texture2D
			if tex == null:
				faltando[arquivo] = true
				continue
			var tam := tex.get_size()
			var area := Rect2(p.x - floorf(tam.x / 2.0), p.y - tam.y, tam.x, tam.y)
			if _toca_caminho(area, terra, off):
				continue
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.offset = Vector2(-floorf(tam.x / 2.0), -tam.y)   # pé do objeto no ponto sorteado
			s.position = p.round()
			deco.add_child(s, true)
			s.owner = raiz
			ocupados.append(p)
			colocados += 1

	if not faltando.is_empty():
		push_warning("Faltam imagens em %s: %s" % [DECOR_DIR, ", ".join(faltando.keys())])

	EditorInterface.save_scene()
	print("Mapa montado: %d tiles de terra, %d itens de decoração. Cena salva." % [terra.size(), deco.get_child_count()])


func _criar_tileset() -> TileSet:
	var textura := load(TILESET_PNG) as Texture2D
	if textura == null:
		push_error("Nao achei %s. Confira o caminho no topo do script." % TILESET_PNG)
		return null
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TAMANHO, TAMANHO)
	var fonte := TileSetAtlasSource.new()
	fonte.texture = textura
	fonte.texture_region_size = Vector2i(TAMANHO, TAMANHO)
	ts.add_source(fonte, 0)
	var colunas := int(textura.get_width() / float(TAMANHO))
	var linhas := int(textura.get_height() / float(TAMANHO))
	for y in range(linhas):
		for x in range(colunas):
			fonte.create_tile(Vector2i(x, y))
	var erro := ResourceSaver.save(ts, TILESET_RES)
	if erro != OK:
		push_error("Nao consegui salvar %s (erro %d)." % [TILESET_RES, erro])
		return null
	return ResourceLoader.load(TILESET_RES, "", ResourceLoader.CACHE_MODE_REPLACE) as TileSet


# Pontos ao longo do Path2D (em coordenadas da cena), com a estrada esticada no começo.
func _amostrar_caminho(raiz: Node2D, caminho: Path2D) -> Array[Vector2]:
	var base: Array[Vector2] = []
	for p in caminho.curve.get_baked_points():
		base.append(raiz.to_local(caminho.to_global(p)))
	var amostras: Array[Vector2] = []
	var ultimo := base.size() - 1
	var dir_ini := (base[0] - base[mini(3, ultimo)]).normalized()
	for i in range(int(EXTENSAO_INICIO / 5.0), 0, -1):
		amostras.append(base[0] + dir_ini * 5.0 * i)
	for p in base:
		amostras.append(p)
	var dir_fim := (base[ultimo] - base[maxi(ultimo - 3, 0)]).normalized()
	for i in range(1, int(EXTENSAO_FIM / 5.0) + 1):
		amostras.append(base[ultimo] + dir_fim * 5.0 * i)
	return amostras


# Desloca a grade de tiles para o centro da estrada cair na divisa entre 2 tiles.
func _melhor_offset(amostras: Array[Vector2]) -> Vector2:
	var melhor := Vector2.ZERO
	var custo_x := INF
	var custo_y := INF
	for o in range(TAMANHO):
		var cx := 0.0
		var cy := 0.0
		for i in range(1, amostras.size()):
			var d := amostras[i] - amostras[i - 1]
			if absf(d.y) > absf(d.x):
				cx += _dist_grade(amostras[i].x - o)
			else:
				cy += _dist_grade(amostras[i].y - o)
		if cx < custo_x:
			custo_x = cx
			melhor.x = o
		if cy < custo_y:
			custo_y = cy
			melhor.y = o
	return melhor


func _dist_grade(v: float) -> float:
	var m := fposmod(v, float(TAMANHO))
	return minf(m, TAMANHO - m)


func _dist2_min(p: Vector2, amostras: Array[Vector2]) -> float:
	var melhor := INF
	for a in amostras:
		var d := p.distance_squared_to(a)
		if d < melhor:
			melhor = d
	return melhor


func _perto_da_borda(p: Vector2, tela: Vector2, margem: float) -> bool:
	return p.x < margem or p.y < margem or p.x > tela.x - margem or p.y > tela.y - margem


# Diz se a imagem (area) encosta em algum tile de terra da estrada.
func _toca_caminho(area: Rect2, terra: Dictionary, off: Vector2) -> bool:
	var a := area.grow(FOLGA_CAMINHO)
	var cx0 := floori((a.position.x - off.x) / TAMANHO)
	var cx1 := floori((a.end.x - off.x) / TAMANHO)
	var cy0 := floori((a.position.y - off.y) / TAMANHO)
	var cy1 := floori((a.end.y - off.y) / TAMANHO)
	for cy in range(cy0, cy1 + 1):
		for cx in range(cx0, cx1 + 1):
			if terra.has(Vector2i(cx, cy)):
				return true
	return false
