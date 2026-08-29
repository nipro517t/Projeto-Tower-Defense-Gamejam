extends Area2D

@export var velocidade: float = 100.0  # pixels p segundo
var path_follow: PathFollow2D

func _process(delta):
	path_follow.progress += velocidade * delta
	global_position = path_follow.global_position
	
	if path_follow.progress_ratio >= 1.0:
		path_follow.queue_free()
		queue_free()
