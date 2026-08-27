extends RefCounted
## Minimal data-driven objective chain. Each objective may point to a "next"
## id; when the chain ends, `finished` is emitted and the escape prompt shows.

signal objective_changed(text: String)
signal finished

const OBJECTIVES: Dictionary = {
	"find_key": {
		"text": "Find the key hidden in the house.",
		"next": null,
	},
}

var current_id := ""
var text := ""


func start(id: String) -> void:
	current_id = id
	text = OBJECTIVES[id]["text"]
	objective_changed.emit(text)


func complete(id: String) -> void:
	if id != current_id:
		return
	var nxt: Variant = OBJECTIVES[current_id].get("next")
	if nxt == null:
		text = "The front door is unlocked. Escape."
		objective_changed.emit(text)
		finished.emit()
	else:
		start(nxt)
