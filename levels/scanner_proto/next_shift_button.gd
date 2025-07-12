extends SceneTransitionButton

func _on_transitioning_scene():
	GameRulesProto.next_shift()

func _ready():
	super._ready()
	on_transitioning_scene.connect(_on_transitioning_scene)
