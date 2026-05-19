package rat
import "vendor:raylib"

World :: struct {
	entity_manager:  EntityManager,
	transforms:      SparseSet(transform_t),
	appearances:     SparseSet(Appearance),
	colliders_aabb:  SparseSet(rectangle_t),
	colliders_circ:  SparseSet(Circle),
	sprite_lib:      SpriteLibrary,
	grid:            SpatialGrid,
	primitives_rect: SparseSet(rectangle_t),
	primitives_circ: SparseSet(Circle),
	sprite_data:     SparseSet(SpriteData),
}

create_world :: proc() -> World {
	return World {
		entity_manager = create_entity_manager(),
		transforms = create_sparse_set(transform_t, MAX_ENTITIES),
		appearances = create_sparse_set(Appearance, MAX_ENTITIES),
		colliders_aabb = create_sparse_set(rectangle_t, MAX_ENTITIES),
		colliders_circ = create_sparse_set(Circle, MAX_ENTITIES),
		sprite_lib = init_sprite_lib(),
		grid = create_spatial_grid(),
		primitives_rect = create_sparse_set(rectangle_t, MAX_ENTITIES),
		primitives_circ = create_sparse_set(Circle, MAX_ENTITIES),
		sprite_data = create_sparse_set(SpriteData, MAX_ENTITIES),
	}
}

create_object :: proc(
	world: ^World,
	transform: transform_t,
	image: ImageParams,
	bbox: Shape,
) -> Entity {
	eid, ok := entity_create(&world.entity_manager)
	assert(ok, "Failed to create entity, EntityManager is out of capacity.")

	add(&world.transforms, eid, transform)

	add(
		&world.appearances,
		eid,
		Appearance {
			tint = image.color,
			offset = image.offset,
			hflip = image.hflip,
			vflip = image.vflip,
		},
	)

	if (image.type == .Sprite) {
		add(
			&world.sprite_data,
			eid,
			SpriteData {
				sprite_name = image.sprite_name,
				image_index = image.image_index,
				frame_counter = 0,
				image_speed = image.image_speed,
			},
		)
	} else {
		switch val in image.shape {
		case [2]f32:
			add(&world.primitives_rect, eid, rectangle_t{width = val[0], height = val[1]})
		case f32:
			add(&world.primitives_circ, eid, Circle{radius = val})
		}
	}

	switch val in bbox {
	case [2]f32:
		add(&world.colliders_aabb, eid, rectangle_t{width = val[0], height = val[1]})
		break
	case f32:
		add(&world.colliders_circ, eid, Circle{radius = val})
		break
	}

	return eid
}
