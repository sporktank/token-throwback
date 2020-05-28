extends Area


export(String, MULTILINE) var text = "?"

var has_shown = false


func _ready():
    $Pivot/Label.text = text


func _on_Zone_body_entered(body):
    if has_shown: return
    has_shown = true
    $Pivot.visible = true
    yield(get_tree().create_timer(10.0), "timeout")
    $Pivot.visible = false
    
    
func _on_Zone_body_exited(body):
    yield(get_tree().create_timer(1.2), "timeout")
    $Pivot.visible = false
