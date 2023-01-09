extends Control

onready var SceneDisplayerWindow: WindowDialog = $SceneNavigatorCanvas/SceneNavigatorWindow
onready var sceneTree: Tree = $SceneNavigatorCanvas/SceneNavigatorWindow/Tree
var sceneDisplayerRoot: TreeItem
var sceneDisplayerDictionary: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	SceneDisplayerWindow.window_title = "Scene Navigator Tree" #+ str(self.get_instance_id())
	setup_scene_displayer()
	_update_node_tree()
	get_tree().connect("node_added", self, "_on_node_added")
	get_tree().connect("node_removed", self, "_on_node_removed")
	
func _on_node_added(node: Node):
#	_update_node_tree()
	_node_tree_add(node)
	pass
	
func _on_node_removed(node):
	_node_tree_remove(node)
	pass
	
func _node_tree_add(node: Node):
	if node == self:
		return
	if self.is_a_parent_of(node):
		return
		
	var nodeId: int = node.get_instance_id()
	if sceneDisplayerDictionary.has(nodeId):
		return
		
	var parentTreeItem: TreeItem = sceneDisplayerDictionary[node.get_parent().get_instance_id()]
	var treeItem: TreeItem = sceneTree.create_item(parentTreeItem)
	treeItem.collapsed = true
	treeItem.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	
	if node.has_method("is_visible"):
		if node.is_visible():
			treeItem.set_checked(0, true)
		
	if node.get_child_count() > 0:
		treeItem.set_text(0, node.name + " [" + str(node.get_child_count()) + "]")
	else:
		treeItem.set_text(0, node.name)
	treeItem.set_text(1, node.get_class())
	treeItem.set_text(2, str(nodeId))
	
	sceneDisplayerDictionary[nodeId] = treeItem
	
func _node_tree_remove(node: Node):
	if node == null:
		return
	if node == self:
		return
	if self.is_a_parent_of(node):
		return
		
	var nodeId = node.get_instance_id()
	if sceneDisplayerDictionary.has(nodeId):
		var rootNode: Node = node.get_parent()
		if rootNode == null:
			return
		var parentTreeItem: TreeItem = sceneDisplayerDictionary[rootNode.get_instance_id()]
		var treeItem: TreeItem = sceneDisplayerDictionary[nodeId]
		sceneDisplayerDictionary.erase(nodeId)
		treeItem.free()
	
func _update_node_tree():
#	sceneTree.clear()
#	sceneDisplayerDictionary.clear()
	get_all_children(get_tree().get_root())
	
func get_all_children(root: Node, level: int = 0):
	var _level: int = level # retains local level property
	for node in root.get_children():
		if node != self:
			_node_tree_add(node)
			if node.get_child_count() > 0:
				get_all_children(node, _level + 1)
	
func setup_scene_displayer():
	sceneTree.set_column_title(0, "Name")
	sceneTree.set_column_title(1, "Type")
	sceneTree.set_column_title(2, "Instance")
	sceneTree.set_column_min_width(0, 125)
	sceneTree.set_column_min_width(1, 95)
	sceneTree.set_column_min_width(2, 75)
	sceneTree.set_column_expand(1, false)
	sceneTree.set_column_expand(2, false)
	sceneTree.set_column_titles_visible(true)
	
	sceneTree.anchor_right = 1
	sceneTree.anchor_bottom = 1
	
	sceneDisplayerRoot = sceneTree.create_item()
	sceneDisplayerRoot.set_text(0, "SceneDisplayer")
	sceneDisplayerDictionary[get_tree().get_root().get_instance_id()] = sceneDisplayerRoot
	
func _input(ev):
	if Input.is_key_pressed(KEY_K):
		if !SceneDisplayerWindow.is_visible_in_tree():
			SceneDisplayerWindow.show()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			SceneDisplayerWindow.hide()
			
func _on_SearchNode_text_changed(new_text):
	var treeArray = Array(sceneDisplayerDictionary.values())
	for treeItem in treeArray:
		var text: String = treeItem.get_text(0)
		if text.capitalize().begins_with(new_text.capitalize()):
#			treeItem.collapsed = false
			if !treeItem.is_selected(0):
				treeItem.select(0)
			return

#func _select_tree_item(treeItem: TreeItem):
#	treeItem.select(0)
	
