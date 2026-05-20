package platformer

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import "rat"
import "vendor:raylib"

TileType :: enum {
	Decorative,
	Solid,
	Metadata,
}

Tile :: struct {
	type:     TileType,
	texture:  raylib.Texture2D,
	metadata: string,
}

TileSource :: struct {
	type:     string,
	path:     string,
	metadata: string,
}

TileLib :: struct {
	tiles: [dynamic]Tile,
	names: map[string]i32,
}

Level :: struct {
	width:     i32,
	height:    i32,
	tile_size: i32,
	tiles:     []i32, // id
}

str2ttype :: proc(input: string) -> TileType {
	switch input {
	case "Solid":
		return .Solid
	case "Decorative":
		return .Decorative
	case "Metadata":
		return .Metadata
	case:
		fmt.printfln("Unknown tile type: ", input)
		return .Decorative
	}
}

load_tile_lib :: proc(manifest_path: string) -> TileLib {
	file, ok := os.read_entire_file_from_path(manifest_path, context.temp_allocator)

	if ok != nil {
		fmt.eprintln("Tile manifest loading failed!")
		return {}
	}

	//defer delete(file)

	manifest: map[string]TileSource
	err := json.unmarshal(file, &manifest)
	if err != nil {
		fmt.eprintln("JSON Error: ", err)
		return {}
	}

	tile_lib: TileLib = {
		tiles = make([dynamic]Tile),
		names = make(map[string]i32),
	}

	for name, source in manifest {
		c_path := strings.clone_to_cstring(source.path, context.temp_allocator)
		tex := raylib.LoadTexture(c_path)

		t := Tile {
			type     = str2ttype(source.type),
			metadata = strings.clone(source.metadata),
			texture  = tex,
		}

		id := i32(len(tile_lib.tiles))
		append(&tile_lib.tiles, t)

		tile_lib.names[strings.clone(name)] = id
	}

	return tile_lib
}

load_level :: proc(tile_lib: ^TileLib, level_path: string) -> (level: Level, ok: bool) {
	data, read_ok := os.read_entire_file_from_path(level_path, context.temp_allocator)
	if read_ok != nil {
		fmt.eprintln("Error while attempting to read file ", level_path)
		return {}, false
	}

	err := json.unmarshal(data, &level)
	if err != nil {
		fmt.eprintfln("Level JSON Error:", err)
		return {}, false
	}

	return level, true
}

draw_level :: proc(level: Level, tile_lib: TileLib) {

	for id, i in level.tiles {
		if id == -1 do continue

		x := f32(i % int(level.width)) * f32(level.tile_size)
		y := f32(i / int(level.width)) * f32(level.tile_size)

		tile := tile_lib.tiles[id]
		raylib.DrawTextureEx(tile.texture, {x, y}, 0, 1, raylib.WHITE)
	}
}

get_tile_id :: proc(level: ^Level, tile_lib: ^TileLib, position: [2]i32) -> i32 {
	if position.x < 0 || position.x >= level.width || position.y < 0 || position.y >= level.height do return -1 //invalid!
	return level.tiles[position.y * level.width + position.x]
}

is_tile_solid :: proc(tile_lib: ^TileLib, id: i32) -> bool {
	return tile_lib.tiles[id].type == TileType.Solid
}

// single tile query
check_tile_collision :: proc(
	level: ^Level,
	tile_lib: ^TileLib,
	position: [2]f32,
	bbox: rat.Shape,
	/* shape is either an [2]f32 for width and height (rect) or f32 for radius (circle)*/
) -> bool {

	tile_sizef := f32(level.tile_size)

	switch val in bbox {
	case [2]f32:
		start_x: i32 = i32(position.x / tile_sizef)
		start_y: i32 = i32(position.y / tile_sizef)
		end_x: i32 = i32((position.x + val.x - 0.1) / tile_sizef)
		end_y: i32 = i32((position.y + val.y - 0.1) / tile_sizef)

		for y := start_y; y <= end_y; y += 1 {
			for x := start_x; x <= end_x; x += 1 {
				type := get_tile_id(level, tile_lib, {x, y})
				if type != -1 && is_tile_solid(tile_lib, type) do return true
			}
		}
	case f32:
		// Circle collision with tiles is more complex,
		// but for a simple grid we can check the bounding box or the center.
		// For now, let's treat it as a square bounding box.
		start_x: i32 = i32((position.x - val) / tile_sizef)
		start_y: i32 = i32((position.y - val) / tile_sizef)
		end_x: i32 = i32((position.x + val - 0.1) / tile_sizef)
		end_y: i32 = i32((position.y + val - 0.1) / tile_sizef)

		for y := start_y; y <= end_y; y += 1 {
			for x := start_x; x <= end_x; x += 1 {
				type := get_tile_id(level, tile_lib, {x, y})
				if type != -1 && is_tile_solid(tile_lib, type) do return true
			}
		}
	}

	return false
}
