extends KinematicBody


enum STATE {ALIVE, DROWNED, SPIKED, COMPLETE}

const UP = Vector3(0, 1, 0)
const WALK_SPEED = 5.0
const JUMP_SPEED = 5.5
const BODY_JUMP_SPEED = 3.2
const VELOCITY_BLEND = 0.15
const CAMERA_BLEND = 0.35
const ROTATE_BLEND = 0.25
const AIR_REDUCTION = 0.6
const ON_FLOOR_COUNT = 6

onready var pivot = $Pivot
onready var camera = $CameraPivot/Camera
onready var camera_pivot = $CameraPivot
onready var camera_tween = $CameraTween

var camera_rotate_desired = 0
var velocity = Vector3()
onready var camera_look_at = translation + 1*UP

var holding_item = null
var collected_items = []
var collectable_items = []
var feet_on_floor = 0  # Using int to count down frames, allowing extra time to press jump.
var body_on_floor = 0
var state = STATE.ALIVE


func set_collectable_items(items):
    collectable_items = items.duplicate()
    collectable_items.sort()
    var y = 0
    for item in items:
        $GUI/Items.get_node(item).visible = true
        $GUI/Items.get_node(item).position.y = y - (20 if item == "Pizza" or item == "Steak" else 0)  # Hack-city-bitch.
        y += 80


func strv(vector):
    return "(%11.5f, %11.5f, %11.5f)" % [vector.x, vector.y, vector.z]


func _physics_process(delta):
    
    $GUI/Debug.text = """
    move_left = %s
    move_right = %s
    move_forward = %s
    move_back = %s
    camera_left = %s
    camera_right = %s
    jump = %s
    feet_on_floor = %s
    body_on_floor = %s
    speed = %s
    position = %s
    """ % [
        Input.get_action_strength("move_left"),
        Input.get_action_strength("move_rightt"),
        Input.get_action_strength("move_forward"),
        Input.get_action_strength("move_back"),
        Input.is_action_just_pressed("camera_left"),
        Input.is_action_just_pressed("camera_right"),
        Input.is_action_just_pressed("jump"),
        feet_on_floor,
        body_on_floor,
        velocity.length(),
        translation,
       ]
    
    var initial_velocity = velocity
    
    # Camera movement.
    
    camera_rotate_desired += 45 * (int(Input.is_action_just_pressed("camera_right")) - int(Input.is_action_just_pressed("camera_left")))
    
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
    if state != STATE.ALIVE:
        input_dir *= 0.0
    var camera_tform = camera.get_global_transform()
    var target_dir = input_dir.x * camera_tform.basis[0] - input_dir.y * camera_tform.basis[2]
    target_dir = (target_dir - UP * target_dir.dot(UP)).normalized() * input_dir.length()
    vel_horiz = vel_horiz.linear_interpolate(target_dir * WALK_SPEED * (AIR_REDUCTION if feet_on_floor < ON_FLOOR_COUNT-1 else 1.0), VELOCITY_BLEND)    

    # Rotation.

    if vel_horiz.length() > 0.05 and feet_on_floor > 0:
        var desired_y = atan2(velocity.x, velocity.z)
        while desired_y < pivot.rotation.y - PI:
            desired_y += 2*PI
        while desired_y > pivot.rotation.y + PI:
            desired_y -= 2*PI
        pivot.rotation.y = ROTATE_BLEND*desired_y + (1-ROTATE_BLEND)*pivot.rotation.y

    # Apply with collisions.

    velocity = vel_horiz + UP*vel_vert
    velocity = move_and_slide(velocity, UP)
    # Giving up on snapping, and no sliding. :(
    #$Debug.text = "pos = %s\nfloor = %s" % [strv(translation), is_on_floor()]
    
    # Check collisions.
    
    for i in range(get_slide_count()):
        var coll = get_slide_collision(i)
        if coll.local_shape == $Feet and coll.normal.dot(Vector3.UP) > 0.25:
            feet_on_floor = ON_FLOOR_COUNT
        if coll.local_shape == $Body and coll.normal.dot(Vector3.UP) > 0.25:
            body_on_floor = ON_FLOOR_COUNT
        # Trying to do spikes.. seems that collision mask doesn't make it to here, only the top level GridMap mask is used.
    feet_on_floor = clamp(feet_on_floor-1, 0, ON_FLOOR_COUNT)
    body_on_floor = clamp(body_on_floor-1, 0, ON_FLOOR_COUNT)
        
    # Jumping.
    
    if state == STATE.ALIVE and Input.is_action_just_pressed("jump"):# and velocity.y <= 0.1:
        if feet_on_floor > 0:
            velocity.y = JUMP_SPEED
        elif body_on_floor > 0:
            velocity.y = BODY_JUMP_SPEED
    
    # Drowning.
    
    if translation.y < -1:
        state = STATE.DROWNED
        $GUI/Drowned/Pivot.visible = true
    
    # Camera look at.
    
    camera_look_at = translation + 1*UP #camera_look_at = camera_look_at.linear_interpolate(translation + 0.1*velocity + 1*UP, CAMERA_BLEND)
    camera.look_at(camera_look_at, UP)


func try_pickup_item(item):
    
    if holding_item != null:
        return false
    
    item.get_parent().remove_child(item)
    $Pivot.add_child(item)
    item.translation = Vector3(0, 1.75, 0)
    holding_item = item
    return true
    

func _on_Goal_entered():
    
    if holding_item != null:
        collected_items.append(holding_item.which)
        collected_items.sort()
        $GUI/Items.get_node(holding_item.which).modulate.a = 1.0
        $Pivot.remove_child(holding_item)
        holding_item.queue_free()
        holding_item = null
    
    if collected_items == collectable_items:
        $GUI/Completed/Pivot.visible = true
        state = STATE.COMPLETE


