package platformer

import "core:math"
import "rat"
import "vendor:raylib"

Player :: struct {
	speed:          f32,
	health:         i32,
	is_grounded:    bool,
	hsp:            f32,
	vsp:            f32,
	eid:            rat.Entity,
	coyote_counter: i32,
	buffer_counter: i32,
}

GRAVITY: f32 : 0.3
COYOTE_MAX: i32 : 6
JUMP_HEIGHT: f32 : 4
MAX_BUFFER: i32 : 4

create_player :: proc(world: ^rat.World) -> Player {
	return Player {
		speed = 5,
		health = 3,
		is_grounded = false,
		eid = rat.create_object(
			world,
			rat.transform_t{position = {64, 64}, rotation = 0, scale = {1, 1}},
			rat.ImageParams {
				type = .Sprite,
				sprite_name = "rat",
				image_index = 0,
				image_speed = 0.1,
				offset = {-4, -4},
				color = raylib.WHITE,
				hflip = 1,
				vflip = 1,
			},
			[2]f32{8, 8},
		),
	}
}


update_player :: proc(player: ^Player, world: ^rat.World, level: ^Level, tile_lib: ^TileLib) {
	// get components
	transform, _ := rat.get(&world.transforms, player.eid)
	bbox, _ := rat.get(&world.colliders_aabb, player.eid)
	appearance, _ := rat.get(&world.appearances, player.eid)

	// gather input
	rightKey: f32 = raylib.IsKeyDown(.RIGHT) ? 1 : 0
	leftKey: f32 = raylib.IsKeyDown(.LEFT) ? 1 : 0
	jumpKey: bool = raylib.IsKeyDown(.Z)
	jumpKeyReleased: bool = raylib.IsKeyReleased(.Z)

	move: f32 = rightKey - leftKey

	if move != 0 do appearance.hflip = i32(move)

	cast_bbox: [2]f32 = {bbox.width * transform.scale.x, bbox.height * transform.scale.y}
	// update grounded state
	if check_tile_collision(
		level,
		tile_lib,
		transform.position + [2]f32{0.0, 1.0},
		cast_bbox,
		appearance.offset,
	) {
		player.is_grounded = true
	} else {
		player.is_grounded = false
	}

	// update hor movement
	player.hsp = move * player.speed

	// update vert movement
	if !player.is_grounded {
		player.vsp += GRAVITY

		if player.coyote_counter > 0 {
			player.coyote_counter -= 1
			if jumpKey {
				jump(player, world)
			}
		}
	} else {
		player.coyote_counter = COYOTE_MAX
	}

	if jumpKey &&
	   !check_tile_collision(
			   level,
			   tile_lib,
			   transform.position - [2]f32{0, JUMP_HEIGHT},
			   cast_bbox,
			   appearance.offset,
		   ) {
		player.buffer_counter = MAX_BUFFER
	}

	if player.buffer_counter > 0 {
		player.buffer_counter -= 1
		if player.is_grounded {
			jump(player, world)
		}
	}

	if jumpKeyReleased && player.vsp > 0 {
		player.vsp *= 0.5
	}

	//check collisions
	if player.hsp != 0 {
		one_pixel_x: f32 = math.sign_f32(player.hsp)
		if check_tile_collision(
			level,
			tile_lib,
			transform.position + [2]f32{player.hsp, 0.0},
			cast_bbox,
			appearance.offset,
		) {
			for !check_tile_collision(
				    level,
				    tile_lib,
				    transform.position + [2]f32{one_pixel_x, 0.0},
				    cast_bbox,
				    appearance.offset,
			    ) {
				transform.position.x += one_pixel_x
			}
			player.hsp = 0
		}
	}

	transform.position.x += player.hsp

	if player.vsp != 0 {
		one_pixel_y: f32 = math.sign_f32(player.vsp)
		if check_tile_collision(
			level,
			tile_lib,
			transform.position + [2]f32{0.0, player.vsp},
			cast_bbox,
			appearance.offset,
		) {
			for !check_tile_collision(
				    level,
				    tile_lib,
				    transform.position + [2]f32{0.0, one_pixel_y},
				    cast_bbox,
				    appearance.offset,
			    ) {
				transform.position.y += one_pixel_y
			}
			player.vsp = 0
		}
	}

	transform.position.y += player.vsp
}

jump :: proc(player: ^Player, world: ^rat.World) {
	transform, _ := rat.get(&world.transforms, player.eid)

	transform.scale.x = 0.7
	transform.scale.y = 1.3
	// FIX ME THIS AFFECTS ACTUAL SCALE THAT CONFLICTS WITH COLLISIONS AND NOT JUST VISUAL SCALE FIX NOW CRITICAL

	// add a timer that resets scale
	// requires a timer system at engine level
	player.vsp = -JUMP_HEIGHT
	player.buffer_counter = 0
}
