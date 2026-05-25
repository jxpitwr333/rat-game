package platformer

import "core:fmt"
import "rat"
import "vendor:raylib"

WINDOW_WIDTH: f32 : 512
WINDOW_HEIGHT: f32 : 512

GAME_WIDTH: i32 : 128
GAME_HEIGHT: i32 : 128

dest_rect := raylib.Rectangle{0, 0, WINDOW_WIDTH, WINDOW_HEIGHT}
src_rect := raylib.Rectangle{0.0, 0.0, f32(GAME_WIDTH), -(f32(GAME_HEIGHT))}

// init
main :: proc() {
	world := rat.create_world()
	if (rat.load_sprite_manifest(&world.sprite_lib, "assets/sprites/sprites.json")) {
		fmt.println("Loaded sprite metadata.")
	}

	raylib.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Hi!")
	defer raylib.CloseWindow()
	raylib.SetTargetFPS(60)

	// create here
	players: [dynamic]Player = make([dynamic]Player, 0, 64)
	append(&players, create_player(&world))
	// end creation

	// this needs to be here because of the opengl context
	tile_lib := load_tile_lib("assets/tiles/tileset.json")
	level, _ := load_level(&tile_lib, "assets/tiles/level.json")

	// window scaling
	target: raylib.RenderTexture2D = raylib.LoadRenderTexture(GAME_WIDTH, GAME_HEIGHT)
	defer raylib.UnloadRenderTexture(target)

	for !raylib.WindowShouldClose() {

		rat.UpdateTimers(&world.timers)
		for &player in players {
			update_player(&player, &world, &level, &tile_lib)
		}

		rat.update_grid(&world)

		raylib.BeginTextureMode(target)
		raylib.ClearBackground(raylib.SKYBLUE)
		draw_level(level, tile_lib)
		rat.render_system(&world)
		raylib.EndTextureMode()

		raylib.BeginDrawing()
		raylib.ClearBackground(raylib.BLACK)

		raylib.SetTextureFilter(target.texture, .POINT)
		raylib.DrawTexturePro(target.texture, src_rect, dest_rect, {0, 0}, 0.0, raylib.WHITE)

		raylib.EndDrawing()
	}
}
