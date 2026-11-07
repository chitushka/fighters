extends SceneTree

var game: Node

func _initialize() -> void:
	run.call_deferred()

func shot(file: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/"+file+".png")

func run() -> void:
	game=load("res://scripts/main.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.audio.set_process(false)
	DirAccess.make_dir_recursive_absolute("res://test-results")
	for i in 3:
		game.stage=i
		game.screen="menu"
		await shot("menu_"+str(i))
		game.guide_page=i
		game.screen="guide"
		await shot("guide_"+str(i))
		game.selected=i
		game.opponent=(i+1)%3
		game.mode=2
		game.start_match()
		game.intro=0
		game.fighters[0].x=450
		game.fighters[1].x=820
		await shot("arena_"+str(i))
	game.fighters[0].energy=100
	game.fighters[0].attack(1)
	for j in 20: game.battle(1.0/60)
	await shot("leopard")
	game.screen="pause"
	await shot("pause")
	game.winner=0
	game.scores=[2,1]
	game.screen="result"
	await shot("result")
	print("RENDER OK: 12 screens captured")
	game.queue_free()
	await process_frame
	quit()
