extends Node2D
var num_rooms:int = 50  # number of rooms to generate
var min_size:int = 20
var max_size:int = 60
var hspread:float = 400  # horizontal spread (in pixels)
var cull:float = 0.5  # chance to cull room
var path_out:AStar2D

@onready var rooms: Node2D = $rooms

func _draw() -> void:
	for room:RigidBody2D in rooms.get_children():
		var collision:CollisionShape2D = room.get_child(0)
		var rect_shape = collision.shape as RectangleShape2D
		var rect:Rect2 = Rect2(room.position - rect_shape.size / 2, rect_shape.size)
		draw_rect(rect, Color.RED)
		if path_out:
			var center:Vector2 = room.position
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
	
	for room in rooms_temp:
		var rigid:RigidBody2D = RigidBody2D.new()
		rigid.gravity_scale = 0
		var collisionShape:CollisionShape2D = CollisionShape2D.new()
		var rect:RectangleShape2D = RectangleShape2D.new()
		collisionShape.shape = rect
		rect.size = room.size * 2
		rigid.add_child(collisionShape)
		rigid.position = room.position
		rooms.add_child(rigid)


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

func _process(_delta: float) -> void:
	queue_redraw()

func _on_button_pressed() -> void:
	path_out = null
	for child in rooms.get_children():
		rooms.remove_child(child)
	make_rooms()
	await get_tree().create_timer(0.5).timeout
	for room in rooms.get_children():
		if randf() < cull:
			rooms.remove_child(room)

	var room_positions: Array[Vector2] = []
	for room:RigidBody2D in rooms.get_children():
		room_positions.push_back(room.position)
	path_out = find_mst(room_positions)
