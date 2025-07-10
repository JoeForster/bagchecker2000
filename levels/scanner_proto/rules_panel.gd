extends Panel

func _ready():
	var current_label_offset = 0
	for rule in GameRulesProto.current_rules:
		# HACK: Get or duplicate the rule label per rule
		var this_rule_label : Label
		var rule_label = $RuleLabel
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
			this_rule_label.text = "No " + rule.restricted_colour_name + " " + rule.restricted_shape + "s"
		else:
			this_rule_label.text = "No more than " + this_rule_label.max_num_of_shape + " " + rule.restricted_colour_name + " " + rule.restricted_shape + "s"
		var text_colour = GameRulesProto.possible_colours[rule.restricted_colour_name]
		this_rule_label.add_theme_color_override("font_color", text_colour)
