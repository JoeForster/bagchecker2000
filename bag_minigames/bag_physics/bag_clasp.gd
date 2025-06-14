class_name BagClasp
extends Node2D

var is_opening = false
var is_opened = false

func _on_anim_finished(anim_name: StringName):
	# HACK assumes only one anim
	is_opening = false
	is_opened = true

func open():
	if !is_opening and !is_opened:
		var player = $AnimationPlayer
		player.play("open_clasp")
		player.animation_finished.connect(_on_anim_finished)
		is_opening = true
