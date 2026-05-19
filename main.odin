package platformer

import "core:fmt"
import "rat"
import "vendor:raylib"

main :: proc() {
	// init
	world := rat.create_world()

	if (rat.load_sprite_manifest(&world.sprite_lib, "assets/sprites/sprites.json")) {
		fmt.println("Loaded sprite metadata.")
	}

	// create here
	players: [dynamic]Player = make([dynamic]Player, 0, 64)
	append(&players, create_player(&world))

	raylib.InitWindow(512, 512, "Hi!") // end creation
	raylib.SetTargetFPS(60)

	// this needs to be here because of the opengl context
	tile_lib := load_tile_lib("assets/tiles/tileset.json")
	level, _ := load_level(&tile_lib, "assets/tiles/level.json")

	defer raylib.CloseWindow()

	for !raylib.WindowShouldClose() {
		for &player in players {
			update_player(&player, &world, &level, &tile_lib)
		}

		rat.update_grid(&world)

		raylib.BeginDrawing()
		raylib.ClearBackground(raylib.SKYBLUE)
		draw_level(level, tile_lib)
		rat.render_system(&world)

		raylib.EndDrawing()
	}
}
