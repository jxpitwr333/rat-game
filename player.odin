package platformer

import "core:math"
import "rat"
import "vendor:raylib"

Player :: struct {
	speed:       f32,
	health:      i32,
	is_grounded: bool,
	hsp:         f32,
	vsp:         f32,
	eid:         rat.Entity,
}

create_player :: proc(world: ^rat.World) -> Player {
	base_size: f32 = 8
	scaled_size := base_size * RENDER_SCALE

	return Player {
		speed = 5,
		health = 3,
		is_grounded = false,
		eid = rat.create_object(
			world,
			rat.transform_t {
				position = {256, 256},
				rotation = 0,
				scale = {RENDER_SCALE, RENDER_SCALE},
			},
			rat.ImageParams {
				type = .Sprite,
				sprite_name = "rat",
				image_index = 0,
				image_speed = 0.1,
				offset = {0, 0},
				color = raylib.WHITE,
				hflip = 1,
				vflip = 1,
			},
			[2]f32{scaled_size, scaled_size},
		),
	}
}

GRAVITY: f32 : 0.3

update_player :: proc(player: ^Player, world: ^rat.World, level: ^Level, tile_lib: ^TileLib) {
	// get components
	transform := &world.transforms.data[player.eid]
	bbox := &world.colliders_aabb.data[player.eid]
	appearance := &world.appearances.data[player.eid]

	// gather input
	rightKey: f32 = raylib.IsKeyDown(.RIGHT) ? 1 : 0
	leftKey: f32 = raylib.IsKeyDown(.LEFT) ? 1 : 0
	move: f32 = rightKey - leftKey

	// update grounded state
	cast_bbox: [2]f32 = {bbox.width, bbox.height}
	if check_tile_collision(level, tile_lib, transform.position + [2]f32{0.0, 0.1}, cast_bbox) {
		player.is_grounded = true
	} else {
		player.is_grounded = false
	}

	// update hor movement
	player.hsp = move * player.speed

	// update vert movement
	if !player.is_grounded {
		player.vsp += GRAVITY
	}

	//check collisions
	if player.hsp != 0 {
		one_pixel_x: f32 = math.sign_f32(player.hsp)
		if check_tile_collision(
			level,
			tile_lib,
			transform.position + [2]f32{player.hsp, 0.0},
			cast_bbox,
		) {
			for !check_tile_collision(
				    level,
				    tile_lib,
				    transform.position + [2]f32{one_pixel_x, 0.0},
				    cast_bbox,
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
		) {
			for !check_tile_collision(
				    level,
				    tile_lib,
				    transform.position + [2]f32{0.0, one_pixel_y},
				    cast_bbox,
			    ) {
				transform.position.y += one_pixel_y
			}
			player.vsp = 0
		}
	}

	transform.position.y += player.vsp
}
