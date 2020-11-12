class_name WireComponent
extends Node2D

var type: int

var state_tinted: Node2D = null
var buffer_tinted: Node2D = null
var inverter_tinted: Node2D = null

var input_wire = null
var output_wire = null

func _init(type: int) -> void:
	self.type = type
