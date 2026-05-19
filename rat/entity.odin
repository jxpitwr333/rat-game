package rat
import "core:fmt"

Entity :: i32

MAX_ENTITIES :: 10000

EntityManager :: struct {
	free_indices: []i32,
	free_top:     i32,
	next_index:   i32,
}

create_entity_manager :: proc() -> EntityManager {
	return EntityManager {
		free_indices = make([]i32, MAX_ENTITIES),
		free_top     = -1, // flag
		next_index   = 0,
	}
}

entity_create :: proc(em: ^EntityManager) -> (Entity, bool) {
	if em.free_top >= 0 {
		id := em.free_indices[em.free_top]
		em.free_top -= 1
		return id, true
	}

	if em.next_index < MAX_ENTITIES {
		id := em.next_index
		em.next_index += 1
		return id, true
	}

	fmt.eprintln("Error: Out of entities!")
	return 0, false
}

entity_destroy :: proc(em: ^EntityManager, e: Entity) {
	em.free_top += 1
	em.free_indices[em.free_top] = i32(e)
}
