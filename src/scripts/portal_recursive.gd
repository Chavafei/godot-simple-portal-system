extends Portal
class_name Portal_recursive
## this is the extended class of Portal to make recusive possible
## the Node that this script is attached to should have all layer mask disable

# the number of recursion portal that will be created
@export var max_recursion : int = 3

# the layers of what the portal should see, should not overlap with starting layer mask.
@export var visible_layer_masks : Array[int] = [1]

# this is the starting layer the portal will belong to, as each recusive portal created. it the later mask value will keeps increasing. so make sure you have a few empty layer mask after the starting layer mask 
# the main camera must have culling mask of the starting value for the portal to be visible.  but it should not have the culling mask of the layer after this starting layer mask.
@export var starting_layer_mask : int = 11


var current_recursion : int = 0
var previous_portal : Portal_recursive

func real_to_exit_transform(real:Transform3D) -> Transform3D:
	return super(real)

func _create_viewport() -> void:
	for n in get_children():
		remove_child(n)
		n.queue_free()

	super()
	
	set_layer_mask_value(current_recursion + starting_layer_mask, true)
	set_layer_mask_value(current_recursion + starting_layer_mask + 1, true)
	set_layer_mask_value(current_recursion + starting_layer_mask - 1, false)
	
	if current_recursion < max_recursion :
		var next_recursion_portal = self.duplicate()
		var instance = next_recursion_portal
		
		instance.previous_portal = self

		instance.current_recursion = current_recursion + 1
		instance.name = "_recursion_" + str(instance.current_recursion)

		add_child(instance)
		instance.global_transform = global_transform


	_viewport.set_update_mode(4)

	_exit_camera.cull_mask = layers
	
	for i in visible_layer_masks :
		_exit_camera.set_cull_mask_value(i, true)
	

func _process(delta:float) -> void:
	# Disable the viewport if the portal is further away than disable_viewport_distance or if the portal is invisible in the scene tree
	var disable_viewport:bool = not is_visible_in_tree() or\
		main_camera.global_position.distance_squared_to(global_position) > disable_viewport_distance * disable_viewport_distance
		
	
	# Enable or disable 3D rendering for the viewport (if it exists)
	if _viewport != null:
		_viewport.disable_3d = disable_viewport

	if disable_viewport:
		# Destroy the disabled viewport to save memory
		if _viewport != null and destroy_disabled_viewport:
			material_override.set_shader_parameter("albedo", null)
			_viewport.queue_free()
			_viewport = null

		# Ensure the portal can re-size the second it is enabled again
		if not is_nan(_seconds_until_resize):
			_seconds_until_resize = 0

		# Don't process the rest if the viewport is disabled
		return

	# Re/-Create viewport
	if _viewport == null:
		_create_viewport()

	# Throttle the viewport resizing for better performance
	if not is_nan(_seconds_until_resize):
		_seconds_until_resize -= delta
		if _seconds_until_resize <= 0:
			_seconds_until_resize = NAN

			var viewport_size:Vector2i = get_viewport().size
			if vertical_viewport_resolution == 0:
				# Resize the viewport to the main viewport size
				_viewport.size = viewport_size
			else:
				# Resize the viewport to the fixed height vertical_viewport_resolution and dynamic width
				var aspect_ratio:float = float(viewport_size.x) / viewport_size.y
				_viewport.size = Vector2i(int(vertical_viewport_resolution * aspect_ratio + 0.5), vertical_viewport_resolution)

	# Move the exit camera relative to the exit portal based on the main camera's position relative to the entrance portal    
	

	
	
	if previous_portal :
		_exit_camera.global_transform = real_to_exit_transform(previous_portal._exit_camera.global_transform)
	else :
		_exit_camera.global_transform = real_to_exit_transform(main_camera.global_transform)
	
	
	
	
	#var rotDiff = _exit_camera.global_rotation - main_camera.global_rotation 
	#_exit_camera.global_rotation = real_to_exit_direction(main_camera.global_rotation) + rotDiff * dumb_multiplyTest
	
	# Get the four X, Y corners of the scaled entrance portal bounding box clamped to Z=0 (portal surface) relative to the exit portal.
	# The entrance portal bounding box is used since the entrance portal mesh does not need to match the exit portal mesh.
	var corner_1:Vector3 = exit_portal.to_global(Vector3(_mesh_aabb.position.x, _mesh_aabb.position.y, 0) * exit_scale)
	var corner_2:Vector3 = exit_portal.to_global(Vector3(_mesh_aabb.position.x + _mesh_aabb.size.x, _mesh_aabb.position.y, 0) * exit_scale)
	var corner_3:Vector3 = exit_portal.to_global(Vector3(_mesh_aabb.position.x + _mesh_aabb.size.x, _mesh_aabb.position.y + _mesh_aabb.size.y, 0) * exit_scale)
	var corner_4:Vector3 = exit_portal.to_global(Vector3(_mesh_aabb.position.x, _mesh_aabb.position.y + _mesh_aabb.size.y, 0) * exit_scale)

	# Calculate the distance along the exit camera forward vector at which each of the portal corners projects
	var camera_forward:Vector3 = -_exit_camera.global_transform.basis.z.normalized()

	var d_1:float = (corner_1 - _exit_camera.global_position).dot(camera_forward)
	var d_2:float = (corner_2 - _exit_camera.global_position).dot(camera_forward)
	var d_3:float = (corner_3 - _exit_camera.global_position).dot(camera_forward)
	var d_4:float = (corner_4 - _exit_camera.global_position).dot(camera_forward)

	# The near clip distance is the shortest distance which still contains all the corners
	_exit_camera.near = max(_EXIT_CAMERA_NEAR_MIN, min(d_1, d_2, d_3, d_4) - exit_near_subtract)
	_exit_camera.far = main_camera.far
	_exit_camera.fov = main_camera.fov
	_exit_camera.keep_aspect = main_camera.keep_aspect
