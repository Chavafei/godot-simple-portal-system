# Godot Simple Portal System

## Description

A Simple Portal System for Godot 4 (and 3 with a little work). Portals hopefully need no introduction. Just think of the game Portal and you get the idea. Non-nested portals are deceptively simple to implement, and can be incredibly powerful as both a gameplay mechanic and as a convenience feature to move players around your level, or to provide countless other fun special effects.

This simple portal system is meant as an educational example on how you can create portals in Godot. Consider it a starting point.

# ![Mesh orientation](https://github.com/Donitzo/godot-simple-portal-system/blob/main/images/demo.gif)

### About Modelling Portals

First you need to model some portal meshes, or just use a plane or a box.

- The portal model surface should face -Y in Blender and -Z in Godot.
- To make a portal face another way, rotate the model object, not the mesh.
- The raycasting works by treating the portal as a flat surface centered at Z=0 in Godot. Flat portals work best in raycasting.

# ![Mesh orientation](https://github.com/Donitzo/godot-simple-portal-system/blob/main/images/mesh_orientation.png)

### Setup Instructions

> **Note**: Portals are expensive to render. Disable portals which are far away or use "disable_viewport_distance".

1. Attach the `portal.gd` script to two `MeshInstance3D` nodes that represent your portal surfaces.
2. Establish a connection between the two portals: Assign one portal to the `exit_portal` property of the other portal. For a one-way portal, leave one portal disconnected.
3. Set your primary camera to the `main_camera` property. If left unset, the portal defaults to using the primary camera.
4. Define the fading range for the portal using `fade_out_distance_max` and `fade_out_distance_min`. Fades to `fade_out_color`.
5. Define the `disable_viewport_distance` for portal rendering. Put the value slightly above `fade_out_distance_max` to ensure the portal fades out completely before disabling itself.
6. Define the `exit_scale` to adjust the exit portal's view scale. Imagine, for instance, a large door leading to a small door.
7. Adjust the `exit_near_subtract` if objects behind the exit portal get cut off.
8. Set `exit_environment` to assign a specific environment to a portal. This is important if, for instance, you want to prevent environmental effects from being applied twice.

## Advanced Usage

These functions help in transitioning between the portal entrance and exit:

- `real_to_exit_transform(real:Transform3D) -> Transform3D`
- `real_to_exit_position(real:Vector3) -> Vector3`
- `real_to_exit_direction(real:Vector3) -> Vector3`

These are useful when you manipulate portal-associated objects. For instance, these functions would allow you to position a cloned spotlight at the exit portal:

```gd
clone_spotlight.global_transform = portal.real_to_exit_transform(spotlight.global_transform)
```

> **Note**: Portals currently do not nest (ie, you can't see through two portals at once). To nest portals you'd have to update the exit_camera position in-between draw calls, or figure out a way to change the camera view matrix in-between rendering viewports. That is beyond the scope of this simple system, but if you got some nice ideas how to implement these things in godot, please [open an issue](https://github.com/Donitzo/godot-simple-portal-system/issues).

## Raycasting

Raycasting through portals can be complex. To simplify this, a built-in raycasting function is provided.

Define a function with this signature:

```gd
func _handle_raycast(from:Vector3, dir:Vector3, segment_distance:float, recursive_distance:float, recursions:int) -> bool:
```

Declare a callable for your function:

```gd
var callable:Callable = Callable(self, "_handle_raycast")
```

Then, use the built-in raycasting function as follows:

```gd
Portal.raycast(get_tree(), from_position, direction, callable, [max_distance=INF], [max_recursions=2])
```

By default `max_recursions` is 2, meaning the ray may pass two portals.

`_handle_raycast` is always invoked at least once for the original ray. The `segment_distance` is `INF` if no portal was hit. The function is invoked once more each time the ray recursively passes through another portal. A ray can be prematurely interrupted if `_handle_raycast` returns true, or if it hits the `max_recursions` limit. Return true if for example the current ray segment was blocked by something.

## Feedback & Bug Reports

If you find any bugs or have feedback, please [open an issue](https://github.com/Donitzo/godot-simple-portal-system/issues) in the GitHub repository.
