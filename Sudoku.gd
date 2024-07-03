extends Node2D

const bold_font = preload("res://assets/fonts/BoldFont.tres")
const extra_bold_font = preload("res://assets/fonts/ExtraBoldFont.tres")

const height = 450
const width = 450
const gap = height / 9
const magic = Vector2(0, -gap/2)

@onready var label = $Label

var select_idx # 鼠标选中的位置 [row, col]的格式
var state # 已经填了的数字, 格式和 puzzle 一样.
var notes # [row][col] -> [number] -> 笔记 label
var labels # 格式跟 state 一样, 里面放的是 label 节点
var blocks # [block] -> {rows: [], cols: []} 一个 block 里面包含哪些行和列

const empty = [
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0]
]
const puzzles = [
	[
		[1,0,0,0,0,0,0,0,3],
		[0,9,0,0,6,0,0,2,0],
		[7,0,0,0,4,8,6,9,0],
		[0,8,0,5,0,1,9,0,0],
		[0,0,0,6,0,4,0,0,0],
		[0,0,5,9,0,7,0,1,0],
		[0,4,1,2,7,0,0,0,9],
		[0,7,0,0,1,0,0,6,0],
		[3,0,0,0,0,0,0,0,8],
	],
	[
		[3,0,0,0,0,0,1,0,0],
		[2,0,0,8,6,0,7,0,0],
		[0,7,0,0,0,4,6,2,0],
		[7,0,0,0,8,2,0,3,0],
		[0,0,0,4,0,6,0,0,0],
		[0,8,0,9,7,0,0,0,6],
		[0,3,7,5,0,0,0,6,0],
		[0,0,5,0,2,8,0,0,9],
		[0,0,8,0,0,0,0,0,1]
	],
	[
		[3,0,0,0,0,0,1,0,0],
		[2,0,0,8,6,0,7,0,0],
		[0,7,0,0,0,4,6,2,0],
		[7,0,0,0,8,2,0,3,0],
		[0,0,0,4,0,6,0,0,0],
		[0,8,0,9,7,0,0,0,6],
		[0,3,7,5,0,0,0,6,0],
		[0,0,5,0,2,8,0,0,9],
		[0,0,8,0,0,0,0,0,1]
	],
	[
		[0,9,0,0,0,3,0,0,0],
		[8,0,0,5,6,2,9,4,0],
		[0,6,4,9,7,0,0,0,0],
		[3,0,0,6,9,0,5,0,0],
		[9,0,0,0,0,0,0,0,4],
		[0,0,6,0,3,7,0,0,9],
		[0,0,0,0,2,6,3,1,0],
		[0,8,3,7,1,5,0,0,6],
		[0,0,0,3,0,0,0,7,0]
	]
]
const puzzle = puzzles[0]

func _ready():
	set_blocks()
	draw_puzzle()
	init_state()
	draw_grid()
	generate_notes()

func set_blocks():
	blocks = []
	for block in range(9):
		var rows
		var cols
		match block:
			0:
				rows = [0,1,2]
				cols = [0,1,2]
			1:
				rows = [0,1,2]
				cols = [3,4,5]
			2:
				rows = [0,1,2]
				cols = [6,7,8]
			3:
				rows = [3,4,5]
				cols = [0,1,2]
			4:
				rows = [3,4,5]
				cols = [3,4,5]
			5:
				rows = [3,4,5]
				cols = [6,7,8]
			6:
				rows = [6,7,8]
				cols = [0,1,2]
			7:
				rows = [6,7,8]
				cols = [3,4,5]
			8:
				rows = [6,7,8]
				cols = [6,7,8]
		blocks.append({"rows": rows, "cols": cols})

func test():
	var has = block_has(0, 1)
	print(has)

func init_state():
	state = puzzle.duplicate(true)
	
	labels = [
		[null,null,null,null,null,null,null,null,null],
		[null,null,null,null,null,null,null,null,null],
		[null,null,null,null,null,null,null,null,null],
		[null,null,null,null,null,null,null,null,null],
		[null,null,null,null,null,null,null,null,null],
		[null,null,null,null,null,null,null,null,null],
		[null,null,null,null,null,null,null,null,null],
		[null,null,null,null,null,null,null,null,null],
		[null,null,null,null,null,null,null,null,null],
	]
	
	notes = []
	for row in range(9):
		notes.append([])
		for col in range(9):
			var cell = [null,null,null,null,null,null,null,null,null]
			notes[row].append(cell)

func _unhandled_input(event):
	if event is InputEventMouseButton && event.is_pressed():
		var position = event.position
		select_idx = position_to_grid_idx(position)
	
	if event is InputEventKey && event is InputEventWithModifiers && event.is_pressed():
		var number = event.keycode - KEY_0
		if 1 <= number && number <= 9:
			input_number(select_idx[0], select_idx[1], number, event.shift)

func grid_idx_to_position(row, col):
	var x = col * gap + gap / 2
	var y = row * gap + gap / 2
	return Vector2(x, y)

func position_to_grid_idx(position):
	var row = int(position.y / gap)
	var col = int(position.x / gap)
	return [row, col]

func draw_grid():
	var y = 0
	for row in range(9 + 1):
		var line = Line2D.new()
		line.add_point(Vector2(0, y))
		line.add_point(Vector2(width, y))
		if row % 3 == 0:
			line.width = 8
		else:
			line.width = 5
		add_child(line)
		y += gap

	var x = 0
	for col in range(9 + 1):
		var line = Line2D.new()
		line.add_point(Vector2(x, 0))
		line.add_point(Vector2(x, height))
		if col % 3 == 0:
			line.width = 8
		else:
			line.width = 3
		add_child(line)
		x += gap

func draw_puzzle():
	for row_idx in len(puzzle):
		var row = puzzle[row_idx]
		for col_idx in len(row):
			var cell = row[col_idx]
			if cell != 0:
				add_fix_number(row_idx, col_idx, cell)

func generate_notes():
	for row in range(9):
		for col in range(9):
			if puzzle[row][col] == 0:
				for number in range(1, 10):
					add_note(row, col, number)

func prune_by_row():
	for row in range(9):
		for number in range(1, 10):
			if row_has(row, number):
				clear_row(row, number)

func prune_by_col():
	for col in range(9):
		for number in range(1, 10):
			if col_has(col, number):
				clear_col(col, number)

func prune_by_block():
	for block in range(9):
		for number in range(1, 10):
			if block_has(block, number):
				clear_block(block, number)

func row_has(row, number):
	"""
	判断第 row 行是否有 number
	"""
	for col in range(9):
		if get_number(row, col) == number:
			return true
	return false

func col_has(col, number):
	"""
	判断第 col 列是否有 number
	"""
	for row in range(9):
		if get_number(row, col) == number:
			return true
	return false

func block_has(block, number):
	var rows = blocks[block]["rows"]
	var cols = blocks[block]["cols"]
	
	for row in rows:
		for col in cols:
			if get_number(row, col) == number:
				return true
	return false

func clear_row(row, number):
	"""
	把第 row 行上面的 number 标记都删除
	"""
	for col in range(9):
		remove_note(row, col, number)

func clear_col(col, number):
	for row in range(9):
		remove_note(row, col, number)

func clear_block(block, number):
	var rows = blocks[block]["rows"]
	var cols = blocks[block]["cols"]
	
	for row in rows:
		for col in cols:
			remove_note(row, col, number)

func input_number(row, col, number, is_note):
	if is_note:
		if notes[row][col][number-1] == null:
			add_note(row, col, number)
		else:
			remove_note(row, col, number)
	else:
		if state[row][col] == 0:
			add_number(row, col, number)
		else:
			labels[row][col].free()
			add_number(row, col, number)

func add_fix_number(row, col, number):
	var label = Label.new()
	label.text = str(number)
	label.set_position(grid_idx_to_position(row, col) + magic)
	label.set("theme_override_fonts/font", extra_bold_font)
	add_child(label)

func add_number(row, col, number):
	state[row][col] = number
	var label = Label.new()
	label.text = str(number)
	var position = grid_idx_to_position(row, col) + magic
	label.set_position(position)
	label.set("theme_override_fonts/font", bold_font)
	add_child(label)
	labels[row][col] = label
	
	# 填了确定数字之后, note都可以清除
	for i in range(1, 10):
		remove_note(row, col, i)
	
	# 填一次数字剪枝一次
	prune()

func add_note(row, col, number):
	var label = Label.new()
	label.text = str(number)
	var position = grid_idx_to_position(row, col)
	match number:
		1: position += Vector2(-gap/3, -gap/3)
		2: position += Vector2(0, -gap/3)
		3: position += Vector2(gap/3, -gap/3)
		4: position += Vector2(-gap/3, 0)
		5: position += Vector2(0, 0)
		6: position += Vector2(gap/3, 0)
		7: position += Vector2(-gap/3, gap/3)
		8: position += Vector2(0, gap/3)
		9: position += Vector2(gap/3, gap/3)
	label.set_position(position)
	add_child(label)
	notes[row][col][number-1] = label

func remove_note(row, col, number):
	var label = notes[row][col][number-1]
	if label != null:
		label.free()

func get_number(row, col):
	"""
	获取 [row, col] 位置的数字
	题目给了数字, 或者已经填了就会返回数字, 否则返回 null
	"""
	if puzzle[row][col] != 0:
		return puzzle[row][col]
	if state[row][col] != 0:
		return state[row][col]
	return null

func fill1():
	"""
	找只有一种可能性的格子, 填充
	"""
	for row in range(9):
		for col in range(9):
			# 已经填了数字, 不需要再填
			if get_number(row, col) != null:
				continue
			var set = {}
			for number in range(1, 10):
				if notes[row][col][number-1] != null:
					set[number] = null
			if set.size() == 1:
				var number = set.keys()[0]
				add_number(row, col, number)

func fill2():
	"""
	可能会有某个数字, 在一行/列/block里面, 可能出现的位置只有一个
	那么这个位置一定是这个数字
	"""
	fill2_row()
	fill2_col()

func fill2_row():
	for row in range(9):
		# 数字 -> [出现位置]
		var position = {}
		for col in range(9):
			for number in range(1, 10):
				if notes[row][col][number-1] != null:
					if position.has(number):
						position[number].append(col)
					else:
						position[number] = [col]
		for number in position.keys():
			if len(position[number]) == 1:
				var col = position[number][0]
				add_number(row, col, number)

func fill2_col():
	for col in range(9):
		# 数字 -> [出现位置]
		var position = {}
		for row in range(9):
			for number in range(1, 10):
				if notes[row][col][number-1] != null:
					if position.has(number):
						position[number].append(row)
					else:
						position[number] = [row]
		for number in position.keys():
			if len(position[number]) == 1:
				var row = position[number][0]
				add_number(row, col, number)

func check():
	# check row
	for row in range(9):
		var count = {}
		for col in range(9):
			var number = get_number(row, col)
			if number != null:
				if count.has(number):
					printerr("错误", row, col, number)
				else:
					count[number] = null
	# check col
	for col in range(9):
		var count = {}
		for row in range(9):
			var number = get_number(row, col)
			if number != null:
				if count.has(number):
					printerr("错误", row, col, number)
				else:
					count[number] = null

func prune():
	prune_by_row()
	prune_by_col()
	prune_by_block()

func _on_NextButton_pressed():
	prune()
	fill1()
	fill2()
	check()
