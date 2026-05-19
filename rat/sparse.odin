package rat

import "core:slice"

// FIXME: the asserts in this file are particularly lazy and should be fixed.

SparseSet :: struct($T: typeid) {
	sparse: []i32,
	dense:  []i32,
	data:   #soa[]T,
	count:  i32,
}

create_sparse_set :: proc($T: typeid, max: i32) -> SparseSet(T) {
	s := SparseSet(T) {
		sparse = make([]i32, max),
		dense  = make([]i32, max),
		data   = make(#soa[]T, max),
		count  = 0,
	}

	// memset
	slice.fill(s.sparse, -1)
	return s
}

add :: proc(set: ^SparseSet($T), eid: i32, value: T) {
	is_valid := int(set.count) < len(set.dense) && int(eid) < len(set.sparse)
	assert(is_valid, "SparseSet: Out of bounds or capacity reached")

	set.sparse[eid] = set.count
	set.dense[set.count] = eid
	set.data[set.count] = value
	set.count += 1
}

remove :: proc(set: ^SparseSet($T), eid: i32) {
	assert(int(eid) < len(set.sparse), "SparseSet: ID out of Range.")

	idx := set.sparse[eid]
	if idx == -1 do return

	last_idx := set.count - 1
	last_eid := set.dense[last_idx]

	//swap
	set.data[idx] = set.data[last_idx]
	set.dense[idx] = set.dense[last_idx]

	//update sparse
	set.sparse[last_eid] = idx
	set.sparse[eid] = -1

	//pop
	set.count -= 1
}

get :: proc(set: ^SparseSet($T), eid: i32) -> (T, bool) {
	assert((int(eid) < len(set.sparse)), "Sparse Set: ID out of range.")

	idx := set.sparse[eid]
	if idx == -1 || idx >= set.count do return {}, false

	return set.data[idx], true
}
