class_name Wire
extends Node2D

export var off_color := Color.black setget set_off_color
export var on_color := Color.red setget set_on_color
export var current_state: bool = false setget set_current_state
export var buffer_state: bool = false setget set_buffer_state


func add_component(component: Component) -> void:
	assert(component.input_wire == null)
	
	add_child(component)
	if component.state_tinted != null:
		$StateTint.add_child(component.state_tinted)
	if component.buffer_tinted != null:
		$BufferTint.add_child(component.buffer_tinted)
	if component.inverter_tinted != null:
		$InverterTint.add_child(component.inverter_tinted)


func remove_component(component: Component) -> void:
	remove_child(component)
	if component.state_tinted != null:
		$StateTint.remove_child(component.state_tinted)
	if component.buffer_tinted != null:
		$BufferTint.remove_child(component.buffer_tinted)
	if component.inverter_tinted != null:
		$InverterTint.remove_child(component.inverter_tinted)


func add_segment(segment: WireSegment) -> void:
	assert(segment.wire == null)
	segment.wire = self
	
	$StateTint.add_child(segment)


func remove_segment(segment: WireSegment) -> void:
	assert(segment.wire == self)
	segment.wire = null
	
	$StateTint.remove_child(segment)


func set_off_color(color: Color) -> void:
	off_color = color
	update_materials()


func set_on_color(color: Color) -> void:
	on_color = color
	update_materials()


func set_current_state(state: bool) -> void:
	current_state = state
	update_materials()


func set_buffer_state(state: bool) -> void:
	buffer_state = state
	update_materials()


func update_materials() -> void:
	$StateTint.modulate = on_color if current_state else off_color
	$BufferTint.modulate = on_color if buffer_state else off_color
	$InverterTint.modulate = off_color if buffer_state else on_color
