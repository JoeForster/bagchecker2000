extends Panel

func refresh():
	# HACK: We have one preplaced label and dupe it. There is probably a better way
	# (could we just create all the rows here, or use a table control?
	var current_label_offset = 0
	var rule_label = $RuleLabel
	for label in get_children():
		if label is Label and label != rule_label:
			label.queue_free()

	for rule in GameRulesProto.current_rules:
		var this_rule_label : Label
		if current_label_offset == 0:
			this_rule_label = rule_label
		else:
			this_rule_label = rule_label.duplicate()
			rule_label.add_sibling(this_rule_label)
			this_rule_label.set_owner(rule_label.get_parent())
			this_rule_label.set_position(rule_label.get_position() + Vector2(0, current_label_offset))
		current_label_offset += this_rule_label.get_size().y
		# Populate the rule label
		if rule.max_num_of_shape <= 0:
			this_rule_label.text = "No "
		else:
			this_rule_label.text = "No more than " + this_rule_label.max_num_of_shape + " "

		if rule.restricted_item_tag:
			# Show just the tag and the preformatted list of shapes it could be
			# TODO human readable, and with visual aid?
			this_rule_label.text += rule.restricted_item_tag
			this_rule_label.text += " " + rule.restricted_item_possible_shapes_label

		else:
			this_rule_label.text += rule.restricted_colour_name + " " + rule.restricted_shape + "s"
			var text_colour = GameRulesProto.possible_colours[rule.restricted_colour_name]
			this_rule_label.add_theme_color_override("font_color", text_colour)

func _process(_delta: float) -> void:
	if GameRulesProto.HACK_ui_dirty:
		refresh()
		GameRulesProto.HACK_ui_dirty = false

func _ready() -> void:
	refresh()
