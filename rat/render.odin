package rat

render_system :: proc(world: ^World) {
	render_sprites(world)
	render_primitive_rects(world)
	render_primitive_circs(world)
}
