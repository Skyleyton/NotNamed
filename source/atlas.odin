package main

import stbi "vendor:stb/image"
import rl "vendor:raylib"

import "core:strings"
import "core:log"
import "core:fmt"
import "core:os"

// Return an array of []u8
get_image_data_array :: proc(filenames: ..string) -> [][^]u8 {
    images_array: [dynamic][^]u8

    for file in filenames {
        cstr_filename := strings.unsafe_string_to_cstring(file)
        width: i32; height: i32
        image_data := stbi.load(cstr_filename, &width, &height, nil, 0)
    
        append(&images_array, image_data)
    }

    return images_array[:]
}

// The images we need to load
ImagesNeeded :: enum {
    foundry,
    herb,
    rock0,
}

load_images :: proc() -> []rl.Texture {
    image_dir := "assets/images/"
    textures_array: [dynamic]rl.Texture
    
    for img in ImagesNeeded {
        img_path := fmt.aprintf("%s%s.png", image_dir, img, allocator=context.temp_allocator)
        if os.exists(img_path) && os.is_file(img_path) {
            texture := rl.LoadTexture(strings.unsafe_string_to_cstring(img_path))
            append(&textures_array, texture)
        }
        else {
            log.debugf("Image \"%s.png\" not found", img)
        }
    }

    free_all(context.temp_allocator)

    return textures_array[:]
}