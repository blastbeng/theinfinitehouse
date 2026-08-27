extends Node
## Subtly modulates the energy of its parent PointLight2D so some lamps breathe.

var _base := 1.0
var _t := 0.0


func _ready() -> void:
	_t = randf() * 100.0
	var l := get_parent()
	if l is PointLight2D:
		_base = l.light_energy


func _process(delta: float) -> void:
	var l := get_parent()
	if not (l is PointLight2D):
		return
	_t += delta
	var n := sin(_t * 7.3) * sin(_t * 3.1 + 1.7) * sin(_t * 13.7 + 0.4)
	l.light_energy = _base * (0.8 + 0.2 * (0.5 + 0.5 * n))
