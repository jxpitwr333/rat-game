package rat

CallbackAction :: proc(_: rawptr)

Timer :: struct {
	frame_target: i32,
	counter:      i32,
	completed:    bool,
	onComplete:   CallbackAction,
}

UpdateTimers :: proc(timers: ^[dynamic]Timer) {
	for i := len(timers); i > 0; i -= 1 {
		timer := &timers[i]

		if timer.completed do return

		if timer.counter < timer.frame_target {
			timer.counter += 1
		}

		if timer.completed {
			timer.onComplete()
			unordered_remove(&timers, i)
		}
	}
}
