extends MeshInstance3D

var orientation : Vector3
var uposition : Vector4
var velocity : Vector4
var boost : Vector4

var shader_position
var shader_resolution

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	orientation = Vector3(0,0,0)
	uposition = Vector4(0,0,0,0)
	velocity = Vector4(0,0,0,0)
	boost = Vector4(0,0,0,0)
	
	shader_position = get_active_material(0).get_shader_parameter("uposition")
	shader_resolution = get_active_material(0).get_shader_parameter("iResolution")
	shader_resolution = get_viewport().size;	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	uposition[3] += delta
	shader_position = uposition
