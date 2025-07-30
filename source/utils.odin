package main

import "core:math"

Vec2f :: [2]f32
Vec2i :: [2]int

Vec3f :: [3]f32
Vec3i :: [3]int

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

get_pivot_value :: proc(pivot: Pivot) -> Vec2f {
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

sin_breath :: proc(time: f32, rate: f32) -> f32 {
	return math.sin(time * 2.0) * rate
}

// A REVOIR
Rect :: struct {
    using pos: Vec2f,
    width, height: f32,
}

rect_contains :: proc(rect: Rect, point: [2]f32) -> bool {
    return (rect.pos.x <= point.x) && (rect.pos.y <= point.y) &&
    (rect.pos.x + rect.width >= point.x) && (rect.pos.y + rect.height >= point.y) 
}