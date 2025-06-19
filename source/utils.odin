package main

import rl "vendor:raylib"

// Pour la mise en place des tuiles.
Pivot :: enum {
    top_left,
    top_center,
    top_right,
    center_left,
    center_center,
    center_right,
    bottom_left,
    bottom_center,
    bottom_right,
}

get_pivot_offset :: proc(sprite_size: rl.Vector2, pivot: Pivot) -> rl.Vector2 {
    switch pivot {
        case .top_left:
        return {0, 0}

        case .top_center:
        return {sprite_size.x / 2, 0}

        case .top_right:
        return {sprite_size.x, 0}

        case .center_left:
        return {0, sprite_size.y / 2}

        case .center_center:
        return sprite_size / 2

        case .center_right:
        return {sprite_size.x, sprite_size.y / 2}

        case .bottom_left:
        return {0, sprite_size.y}

        case .bottom_center:
        return {sprite_size.x / 2, sprite_size.y}

        case .bottom_right:
        return sprite_size
    }

    return {0, 0}
}