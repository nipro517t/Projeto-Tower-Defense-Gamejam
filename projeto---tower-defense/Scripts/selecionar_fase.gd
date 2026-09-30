extends Control

@onready var camera_2d: Camera2D = $Camera2D


func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("cameraD"):
		camera_2d.position.x +=5
	
	if Input.is_action_just_pressed("cameraE"):
		camera_2d.position.x -= 5


#a ideia e fazer cada "mundo" ter seus leveis e os leveis serao escolhidos nos panels dessa cena. E ao ir arrastando pro lado aparecem as fases a se escolher
