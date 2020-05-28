extends KinematicBody


const UP = Vector3(0, 1, 0)
const WALK_SPEED = 4.0
const VELOCITY_BLEND = 0.15
const CAMERA_BLEND = 0.35
const ROTATE_BLEND = 0.25


onready var pivot = $Pivot
onready var camera = $CameraPivot/Camera
onready var camera_pivot = $CameraPivot
onready var camera_tween = $CameraTween

var camera_rotate_desired = 0.0
var velocity = Vector3()
onready var camera_look_at = translation + 1*UP


func _process(delta):
    if Input.is_action_just_pressed("escape"):
        get_tree().quit()  # TEMP!


func _physics_process(delta):
    
    # Camera movement.
    
    camera_rotate_desired += 45.0 * (int(Input.is_action_just_pressed("camera_right")) - int(Input.is_action_just_pressed("camera_left")))
    
    if camera_pivot.rotation_degrees.y != camera_rotate_desired:
        if camera_tween.is_active():
            camera_tween.stop_all()
        camera_tween.interpolate_property(camera_pivot, "rotation_degrees:y", camera_pivot.rotation_degrees.y, camera_rotate_desired, 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
        camera_tween.start()
    
    # Gravity.
    
    velocity -= 9.8*UP*delta
    var vel_vert = UP.dot(velocity)
    var vel_horiz = velocity - UP*vel_vert
    
    # Movement.
    
    var input_dir = Vector2(
            Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
            Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
        )
    if input_dir.length() > 1:
        input_dir = input_dir.normalized()
    var camera_tform = camera.get_global_transform()
    var target_dir = input_dir.x * camera_tform.basis[0] - input_dir.y * camera_tform.basis[2]
    target_dir = (target_dir - UP * target_dir.dot(UP)).normalized() * input_dir.length()
    vel_horiz = vel_horiz.linear_interpolate(target_dir * WALK_SPEED, VELOCITY_BLEND)    
    
    # Rotation.
    
    if vel_horiz.length() > 0.01:
        var desired_y = atan2(velocity.x, velocity.z)
        while desired_y < pivot.rotation.y - PI:
            desired_y += 2*PI
        while desired_y > pivot.rotation.y + PI:
            desired_y -= 2*PI
        pivot.rotation.y = ROTATE_BLEND*desired_y + (1-ROTATE_BLEND)*pivot.rotation.y
    
    # Apply with collisions.
    
    velocity = vel_horiz + UP*vel_vert
    #velocity = move_and_slide(velocity, UP)#, true, 4, deg2rad(90))
    velocity = move_and_slide_with_snap(velocity, Vector3(0,1,0), UP, true)
    # https://github.com/godotengine/godot/pull/33864
    # https://github.com/godotengine/godot/issues/34117
    # https://opengameart.org/content/landscape-asset-v1
    # https://opengameart.org/content/free-3d-platformer-art-pack-1
    # https://opengameart.org/content/free-3d-platformer-art-pack-3-terrain-and-extras
    
    # Camera look at.
    
    #camera_look_at = camera_look_at.linear_interpolate(translation + 0.1*velocity + 1*UP, CAMERA_BLEND)
    camera_look_at = translation + 1*UP
    camera.look_at(camera_look_at, UP)
    
    
