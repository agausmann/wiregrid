class_name WiregridWorld
extends Node2D

const Component := preload("res://util/component.gd")
const Direction := preload("res://util/direction.gd")
const Simulation := preload("res://simulation/simulation.gdns")

var wires := []
var segments := []
var tiles := {}
var _free_wires := []
var _free_segments := []
var _simulation := Simulation.new()


class Wire:
	var state := false
	var buffered_state := false
	var segments := []


class Segment:
	var start: Vector2
	var end: Vector2
	var wire: int


class Tile:
	var edges := [-1, -1, -1, -1]
	var component := Component.NONE
	var component_direction := Direction.RIGHT
