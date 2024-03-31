class_name TweenManager


class TweenInstance:
	var _node: Node
	var _map: Dictionary = {}
	
	func _init(node: Node):
		self._node = node
	
	func create_tween(id: String) -> Tween:
		var old_tween: Tween = _map.get(id)
		if old_tween != null:
			old_tween.pause()
			old_tween.custom_step(1.0)
			old_tween.kill()
		
		_map[id] = self._node.create_tween()
		return _map[id]


static func create_instance(node: Node) -> TweenInstance:
	return TweenInstance.new(node)
