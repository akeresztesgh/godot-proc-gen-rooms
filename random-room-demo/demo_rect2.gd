extends Node2D

var num_rooms:int = 50  # number of rooms to generate
var min_size:int = 20
var max_size:int = 60
var hspread:float = 400  # horizontal spread (in pixels)
var cull:float = 0.5  # chance to cull room
var RoomBoundingBoxes: Array[Rect2i] = []
var path_out:AStar2D

func _draw() -> void:
	for bb in RoomBoundingBoxes:
		draw_rect(bb, Color.RED)
		var center:Vector2 = Vector2(bb.position.x + bb.size.x / 2.0, bb.position.y + bb.size.y / 2.0)
		var p = path_out.get_closest_point(center)
		for conn in path_out.get_point_connections(p):
			var start = path_out.get_point_position(p)
			var end = path_out.get_point_position(conn)
			draw_line(start, end, Color.BLUE)

func _ready() -> void:
	_on_button_pressed()
	
func make_rooms():
	#var time = Time.get_ticks_msec()
	var vspread = hspread
	var rooms_temp = []  # Store rooms as dictionaries for now
	for i in range(num_rooms):
		var pos = Vector2(randf_range(-hspread, hspread), randf_range(-vspread, vspread))
		var w = min_size + randi() % (max_size - min_size)
		var h = min_size + randi() % (max_size - min_size)
		# note size is 1/2 total size
		var room = {
			"position": pos,
			"size": Vector2(w, h)
		}
		rooms_temp.append(room)
	
	# Separate rooms iteratively (repulsion)
	var max_iterations = 100
	var iteration = 0
	var moved = true
	while moved and iteration < max_iterations:
		moved = false
		for i in range(rooms_temp.size()):
			var room_a = rooms_temp[i]
			# room.size is 1/2 total size
			var rect_a = Rect2(room_a.position - room_a.size, room_a.size * 2)
			
			for j in range(i + 1, rooms_temp.size()):
				var room_b = rooms_temp[j]
				var rect_b = Rect2(room_b.position - room_b.size, room_b.size * 2)
				
				if rect_a.intersects(rect_b):
					moved = true
					var direction:Vector2 = (room_a.position - room_b.position).normalized()
					var overlap:Vector2 = (rect_a.size + rect_b.size) - (room_a.position - room_b.position).abs()
					var push:Vector2 = direction * overlap / 2.0
					room_a.position += push
					room_b.position -= push
	
		iteration += 1
	
	# Cull rooms and instantiate
	for room in rooms_temp:
		if randf() < cull:
			continue  # Skip culled rooms
		var top_left_tile = room.position - room.size
		# Calculate the final Rect2i for the room's bounding box and pathing
		var final_rect = Rect2i(top_left_tile, Vector2i(room.size * 2))
		# map coords
		RoomBoundingBoxes.append(final_rect)

func find_mst(nodes:Array[Vector2]) -> AStar2D:
	# Prim's algorithm
	# Given an array of positions (nodes), generates a minimum
	# spanning tree
	# Returns an AStar object
	
	# Initialize the AStar and add the first point
	var path:AStar2D = AStar2D.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	# Repeat until no more nodes remain
	while nodes:
		var min_dist = INF  # Minimum distance so far
		var min_p = null  # Position of that node
		var p = null  # Current position
		# Loop through points in path
		for p1 in path.get_point_ids():
			var p1_vec = path.get_point_position(p1)
			# Loop through the remaining nodes
			for p2 in nodes:
				# If the node is closer, make it the closest
				if p1_vec.distance_to(p2) < min_dist:
					min_dist = p1_vec.distance_to(p2)
					min_p = p2
					p = p1_vec
		# Insert the resulting node into the path and add
		# its connection
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		# Remove the node from the array so it isn't visited again
		nodes.erase(min_p)
	return path

func _on_button_pressed() -> void:
	RoomBoundingBoxes = []
	make_rooms()	
	var room_positions: Array[Vector2] = []
	for rect in RoomBoundingBoxes:
		# Use the center of the bounding box for path finding
		room_positions.append(Vector2(rect.position + rect.size / 2))
	path_out = find_mst(room_positions)
	queue_redraw()
