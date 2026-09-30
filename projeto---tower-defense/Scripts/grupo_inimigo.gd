extends Resource
class_name GrupoInimigo

# ⚠️ Um "grupo" é uma sequência de UM tipo de inimigo dentro de uma onda.
# Uma onda pode ter vários grupos diferentes, um atrás do outro (ex: 5
# inimigos normais, depois 3 fortes).
@export var inimigo_cena: PackedScene
@export var quantidade: int = 5
@export var intervalo: float = 1.0  # segundos entre cada spawn deste grupo
