extends Camera2D

var surface_material

var resolution = Vector2.ZERO

var shader_transformMatrix
var shader_position
var shader_orientation
var shader_fourvel
var shader_boost
var shader_iResolution
var shader_view2d
var shader_viewForward
var shader_viewUp
var shader_viewRight
var shader_enemyPosition
var shader_projectionDistance

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	surface_material = $CanvasLayer/ColorRect.get_material()
	
	shader_transformMatrix = StringName("transformMatrix")
	shader_fourvel = StringName("fourvel")
	shader_position = StringName("uposition")
	shader_boost = StringName("boost")
	shader_orientation = StringName("orientation")
	shader_iResolution = StringName("iResolution")
	shader_view2d = StringName("view2d")
	shader_viewForward = StringName("viewForward")
	shader_viewUp = StringName("viewUp")
	shader_viewRight = StringName("viewRight")
	shader_enemyPosition = StringName("enemyPosition")
	shader_projectionDistance = StringName("projectionDistance")
	
	update_resolution(1.0)
	
func update_shader_values(sim : Global.Sim, view : Global.View, gameplay : Global.Gameplay) -> void:
	surface_material.set_shader_parameter(shader_iResolution, resolution)
	
	surface_material.set_shader_parameter(shader_position, sim.uposition)
	surface_material.set_shader_parameter(shader_fourvel, sim.fourvel)
	surface_material.set_shader_parameter(shader_transformMatrix, sim.transform_matrix)
	
	surface_material.set_shader_parameter(shader_projectionDistance, view.projectionDistance)
	surface_material.set_shader_parameter(shader_viewForward, view.Forward)
	surface_material.set_shader_parameter(shader_viewUp, view.Up)
	surface_material.set_shader_parameter(shader_viewRight, view.Right)
	
	surface_material.set_shader_parameter(shader_enemyPosition, gameplay.enemyPosition)	
	
func update_resolution(retardation : float):
	resolution = Vector3(get_viewport().size.x, get_viewport().size.y, retardation)	
