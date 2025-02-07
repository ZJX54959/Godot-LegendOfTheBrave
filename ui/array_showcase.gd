extends HBoxContainer
class_name ArrayShowcase

@export var Show_Array: Array

func _physics_process(delta: float) -> void:
	if not has_node("*"):
		return
	for child in get_children():
		child.queue_free()
	for item in Show_Array:
		var i := PanelContainer.new()
		var text := RichTextLabel.new()
		text.append_text(item)
		i.add_child(text)
		self.add_child(i)
