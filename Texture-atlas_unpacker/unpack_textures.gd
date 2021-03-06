tool
extends EditorPlugin
	
var plugin_button = null
var dialog = null
var jsonpath = null
	
func _init():
	pass
	
func get_name():
	return "Unpack texture-atlas plugin"
	
#adds button to godot editor, registers it and instance dialog
func _enter_tree():
	plugin_button = Button.new()
	plugin_button.set_text("Unpack texture-atlas")
	
	plugin_button.connect("pressed",self,"_show_dialog")
	add_custom_control(CONTAINER_CANVAS_EDITOR_MENU, plugin_button)
	
	dialog = preload("unpacker-dialog.xml").instance();
	dialog.get_ok().set_custom_minimum_size(Vector2(50,20))
	pass
	
func _on_file_selected(path):
	jsonpath = path
	
func _show_dialog():
	if dialog.get_parent() == null:
		add_child(dialog)
	dialog.show()
	dialog.popup_centered()
	if not dialog.is_connected("confirmed",self,"_on_dialog_confirm"):
		dialog.connect("confirmed",self,"_on_dialog_confirm")
	if not dialog.is_connected("on_file_selected",self,"_on_file_selected"):
		dialog.connect("on_file_selected",self,"_on_file_selected")
	
#process selected texture
func _on_dialog_confirm():
	var root = get_tree().get_edited_scene_root()
	var image  = ImageTexture.new()

	var lpos = jsonpath.find_last("/")
	var dir = jsonpath.substr(0,lpos)
	
	#load selected texture
	var selector = dialog.get_node("textureSelector")
	var imgPath = selector.get_item_text(selector.get_selected())
	imgPath = imgPath.split("-")[1]
	if image.load(dir + "/" + imgPath.strip_edges()) != 1:
		print("failed to load texture")
		pass
	
	#split texture into sprites
	var atlasProps = dialog.get_AtlasProps()[imgPath.strip_edges()]
	for img in atlasProps:
		var xy = atlasProps[img]["xy"].split(",")
		var wh = atlasProps[img]["size"].split(",")
		var s = Sprite.new()
		s.set_texture(image)
		s.set_region(true)
		s.set_region_rect(Rect2(xy[0].strip_edges().to_float(), xy[1].strip_edges().to_float(), wh[0].strip_edges().to_float(), wh[1].strip_edges().to_float()))
		root.add_child(s)
		var pos = Vector2(xy[0].strip_edges().to_float(), xy[1].strip_edges().to_float())
		s.set_pos(pos)
		
		var baseW = dialog.get_node("tileW").get_text().to_float();
		var baseH = dialog.get_node("tileH").get_text().to_float();
		
		if baseW > 0 || baseH > 0:
			var w = wh[0].strip_edges().to_float()				
			var h = wh[1].strip_edges().to_float()
			var off = Vector2(0, baseH - h)
			if w > baseW && w < baseW + baseW / 2:
				off.x = (baseW - w) / 2
			if off.y != 0:
				s.set_offset(off)
		
		s.set_owner(root)
		
		if (atlasProps[img]["index"]).to_int() != -1:
			s.set_name(img.split("_")[0] + atlasProps[img]["index"])
		else:
			s.set_name(img)
	
	dialog.disconnect("confirmed",self,"_on_dialog_confirm")
	dialog.disconnect("on_file_selected",self,"_on_file_selected")
	pass
	
func _exit_tree():
	plugin_button.disconnect("pressed",self,"_show_dialog")
	plugin_button.free()
	dialog.disconnect("confirmed",self,"_on_dialog_confirm")
	dialog.disconnect("on_file_selected",self,"_on_file_selected")
	dialog.dispose()
	dialog.queue_free()
	plugin_button  = null
	dialog = null
	pass
