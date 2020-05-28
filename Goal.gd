extends StaticBody


signal entered


func _on_Area_body_entered(body):
    emit_signal("entered")
