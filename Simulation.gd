extends Reference
class_name Simulation

class Component:
	func update(_state: State, _send_update: FuncRef) -> void:
		pass
		
class Blotter extends Component:
	var is_on := false
	var input_wire: int
	var output_wire: int
	
	func update(state: State, send_update: FuncRef) -> void:
		var input: bool = state.wires[input_wire].is_on()
		if is_on != input:
			is_on = input
			send_update.call_func(output_wire, input)

class Inverter extends Component:
	var is_on := false
	var input_wire: int
	var output_wire: int
	
	func update(state: State, send_update: FuncRef) -> void:
		var input: bool = state.wires[input_wire].is_on()
		if is_on != input:
			is_on = input
			send_update.call_func(output_wire, !input)

class Wire:
	var on_count := 0
	var components := []
	
	func is_on() -> bool:
		return on_count > 0

class UpdateBuffer:
	var updates := {}
	
	func send_update(wire_id: int, is_on: bool) -> void:
		if !updates.has(wire_id):
			updates[wire_id] = 0
		if is_on:
			updates[wire_id] += 1
		else:
			updates[wire_id] -= 1

class State:
	var components := []
	var wires := []
	var updates := {}
	
	func step() -> UpdateBuffer:
		var update_buffer := UpdateBuffer.new()
		for component in updates:
			component.update(self, funcref(update_buffer, "send_update"))
		updates.clear()
		for wire_id in update_buffer.updates:
			var wire: Wire = wires[wire_id]
			var delta: int = update_buffer.updates[wire]
			wire.on_count += delta
			if delta != 0 and (wire.on_count == 0 or wire.on_count == delta):
				for component_id in wire.components:
					updates[component_id] = null
		return update_buffer
