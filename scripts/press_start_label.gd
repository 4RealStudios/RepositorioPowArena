extends AnimatedSprite2D

var shown := false

func _ready() -> void:
	visible = false

func play_show_animation():
	if not visible:
		visible = true
		play("enter")

func play_hide_animation():
	if visible:
		play("exit")
		await animation_finished
		visible = false

func _on_animation_finished():
	if animation == "exit":
		visible = false
