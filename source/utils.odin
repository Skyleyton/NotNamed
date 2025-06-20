package main

import rl "vendor:raylib"

Vec2 :: [2]f32
Vec3 :: [3]f32

Pivot :: enum {
	top_left,
	top_center,
	top_right,
	center_left,
	center_center,
	center_right,
	bottom_left,
	bottom_center,
	bottom_right
}

get_pivot_value :: proc(pivot: Pivot) -> Vec2 {
	#partial switch pivot {
		case .top_left:
		return {0.0, 0.0}
		
		case .top_center:
		return {0.5, 0.0}

		case .top_right:
		return {1.0, 0.0}


		case .center_left:
		return {0.0, 0.5}

		case .center_center:
		return {0.5, 0.5}

		case .center_right:
		return {1.0, 0.5}


		case .bottom_left:
		return {0.0, 1.0}

		case .bottom_center:
		return {0.5, 1.0}

		case .bottom_right:
		return {1.0, 1.0}
	}

	return {0.0, 0.0}
}
