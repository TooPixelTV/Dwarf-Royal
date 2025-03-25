extends Node
class_name Component

@onready var parent = get_parent()

var component_name: String = "Component"

func _init() -> void:
	if self.component_name == "Component":
		push_warning("A component must override the 'component_name' variable.")

func get_component(component_type):
	var results = parent.get_children().filter(func (c): return is_instance_of(c, component_type))
	
	if results.is_empty():
		return null
	
	return results[0]

func get_multiple_components(component_type):
	var results = parent.get_children().filter(func (c): return is_instance_of(c, component_type))
	
	return results

static func get_child_component(element: Node, component_type: Script) -> Component:
	return element.get_children()\
			.filter(func (e): return is_instance_of(e, component_type) and is_instance_of(e, Component))[0]

static func get_multiple_child_components(element: Node, component_type: Script) -> Array:
	return element.get_children()\
			.filter(func (e): return is_instance_of(e, component_type) and is_instance_of(e, Component))


func required_components_warning(component_types: Array[Variant]) -> PackedStringArray:
	var result: PackedStringArray = []
	
	for component_type in component_types:
		if get_component(component_type) == null:
			var instance = component_type.new()
			result.append("Missing " + instance.component_name + " component.")
	
	return result
