package main

import "core:fmt"

import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:mem"

import rl "vendor:raylib"

/*
TODO:
    -- Automatiser le processus de chargement des textures dans le tableau.
    -- Mettre en place une bounding box sur les entités pour check si ma souris est dedans (pour les entités plus grandes) au lieu de check la tile.
    -- Mettre en place du Hot Code Reloading -> Moyennement urgent pour mon bien être lol.
    -- Réfléchir à comment implémenter des éléments qui utilisent plusieurs tiles en même temps (comme des gros rochers).

    - Réfléchir à un système de chunking, un chunk ferait 24 en largeur et 32 en longueur, à voir.

    - Faire en sorte qu'on ne place pas deux entités sur une tuile déjà occupé dans la fonction d'ajout d'entités.
    - Mettre en place une sorte de swapping d'entité quand une entité meurt.
*/

/*
IN THE WORK:
    - Appliquer le GAME_SCALE à tous les éléments du jeu.
    - Revoir le calcul des rectangles pour les hitboxes
*/

/*
DONE:
    - Mapper les objets/entités sur les tuiles.
    - Affichage du type de l'entité sous la souris.
    - Affichage tiles occupé en bleu quand on est en mode debug.
    - Mettre en place un système de santé pour les éléments du jeu et donc le système de destruction.
    - Changer les flags des tiles de booléen a bit_set.
    - Ajouter un champ de flags aux entités pour l'hover de la souris par exemple.
*/

WINDOW_W: i32 : 1280
WINDOW_H: i32 : 720

// Distance de frappe
MAX_DIST :: 1

// Le nombre de tiles dans le monde pour l'instant.
NUM_TILES_X :: 32
NUM_TILES_Y :: 32

// La taille d'une tile en pixels.
GAME_SCALE :: 1
TILE_LENGHT_IN_PIXELS :: 16
TILE_LENGTH :: TILE_LENGHT_IN_PIXELS * GAME_SCALE

// Nombre max d'entités dans le monde.
MAX_ENTITY :: 32

// On va essayer de faire en sorte que ça respecte le nom des fichiers.
Texture_type :: enum {
    null,
    herb,
    player,
    rock0,
    tree0,

    // Items
    wood,
    small_rock,
    big_rock,    
    // TOTAL_TEXTURE_TYPE,
}

Entity_type :: enum {
    null,
    player,
    rock0,
    tree0,

    item, // When something is an item
    // TOTAL_ENTITY_TYPE,
}

Item_Type :: enum {
    item_wood,
    item_small_rock,
    item_big_rock
}

Item :: struct {
    type: Item_Type,
    count: u32
}

Entity_flags :: enum {
    hovered,
    has_inventory,
}

Entity :: struct {
    pos: rl.Vector2,
    tile_pos: Vec2i,
    vel: rl.Vector2,
    type: Entity_type,
    health: f32,
    alive: bool,
    rect: Rect,
    texture: rl.Texture2D,
    flags: bit_set[Entity_flags],
    pos_origin: rl.Vector2, // Pour des animations lorsqu'on casse des textures.

    // items
    item: Item
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

Tile_type :: enum {
    null,
    herb,
    // TOTAL_TILE_TYPE,
}

Tile_flags :: enum {
    prepared, // Préparé à accueillir une graine.
    occuped, // Occupé par un objet par dessus.
}

Tile :: struct {
    type: Tile_type,
    texture: rl.Texture,
    flags: bit_set[Tile_flags],

    entity_on_top: Entity_type, // Je sais pas si ça va vraiment servir
}

Game :: struct {
    entities: [MAX_ENTITY]Entity,
    current_entity_number: u32,
    tiles: [NUM_TILES_X * NUM_TILES_Y]Tile,
}

// Tableau de textures pour l'instant.
// TODO: automatiser plus tard, vu que ça sera le même nom que les fichiers, voir fmt.tprint().
// TODO: Se renseigner sur les atlas de textures.
textures: [Texture_type]rl.Texture // Détecte tout seul le nombre max d'éléments.
game: Game

// Dessine une texture avec son origine à son centre
draw_sprite :: proc(texture: rl.Texture, pos: Vec2f, rotation:f32=0, scale:f32=1, pivot:Pivot=.center_center, tint:=rl.WHITE) {
    pivot := get_pivot_value(pivot)
    
    rl.DrawTexturePro(texture,
        {0, 0, f32(texture.width), f32(texture.height)},
        {pos.x, pos.y, f32(texture.width) * scale, f32(texture.height) * scale},
        {(f32(texture.width) * pivot[0]) * scale, (f32(texture.height) * pivot[1]) * scale},
        rotation,
        tint
    )
}


// Retourne true si réussi, sinon false.
// WORKING
game_create_n_number_of_entity :: proc(game: ^Game, number: u32, en_type: Entity_type) -> bool {
    if (game.current_entity_number + number) > MAX_ENTITY {
        fmt.println("! Impossible de rajouter ce nombre d'entités !")

        return false
    }

    textures_array: [Texture_type]rl.Texture

    textures_array[.herb] = rl.LoadTexture("assets/images/herb.png")
    textures_array[.player] = rl.LoadTexture("assets/images/player.png")
    textures_array[.rock0] = rl.LoadTexture("assets/images/rock0.png")
    textures_array[.tree0] = rl.LoadTexture("assets/images/tree0.png")

    for i in game.current_entity_number..<(number+game.current_entity_number) {
        #partial switch en_type {
            // On mets tout au hasard, on changera plus tard.
            case .player:
            pos: rl.Vector2 = {rand.float32_range(0.0, f32(NUM_TILES_X * (TILE_LENGTH-1))), rand.float32_range(0.0, f32(NUM_TILES_Y * (TILE_LENGTH-1)))} // Random pos in the game world.
            game.entities[i] = Entity {
                pos = pos,
                vel = {0.0, 0.0},
                type = en_type,
                alive = true,
                health = 20.0, // à changer plus tard
                flags = {.has_inventory},
                texture = textures_array[.player],
                rect = {
                    {pos.x, pos.y},
                    f32(textures_array[.player].width),
                    f32(textures_array[.player].height)
                }
            }

            case .tree0:
            pos: rl.Vector2 = {rand.float32_range(0.0, f32(NUM_TILES_X * (TILE_LENGTH-1))), rand.float32_range(0.0, f32(NUM_TILES_Y * (TILE_LENGTH-1)))} // Random pos in the game world.
            game.entities[i] = Entity {
                pos = pos,
                vel = {0.0, 0.0},
                type = en_type,
                alive = true,
                health = 20.0, // à changer plus tard
                flags = {},
                texture = textures_array[.tree0],
                rect = {
                    {pos.x, pos.y},
                    f32(textures_array[.tree0].width),
                    f32(textures_array[.tree0].height)
                }         
            }

            case .rock0:
            pos: rl.Vector2 = {rand.float32_range(0.0, f32(NUM_TILES_X * (TILE_LENGTH-1))), rand.float32_range(0.0, f32(NUM_TILES_Y * (TILE_LENGTH-1)))} // Random pos in the game world.
            game.entities[i] = Entity {
                pos = pos,
                vel = {0.0, 0.0},
                type = en_type,
                alive = true,
                health = 20.0,
                flags = {},
                texture = textures_array[.rock0],
                rect = {
                    {pos.x, pos.y},
                    f32(textures_array[.rock0].width),
                    f32(textures_array[.rock0].height)
                }
            }
        }
        // On pose ça là, comme ça l'entité est créée.
        game.entities[i].tile_pos = {int(game.entities[i].pos.x) / TILE_LENGTH, int(game.entities[i].pos.y) / TILE_LENGTH}
        game.entities[i].pos_origin = game.entities[i].pos
    }

    // On rajoute le nombre d'entités ajoutés.
    game.current_entity_number += number

    return true
}


game_create_n_number_of_item_from_entity :: proc(game: ^Game, number: u32, number_of_items: u32, item_type: Item_Type, from_entity: Entity) -> bool {
    if (game.current_entity_number + number) > MAX_ENTITY {
        fmt.println("! Impossible de rajouter ce nombre d'entités !")

        return false
    }

    textures_array: [Texture_type]rl.Texture
    textures_array[.wood] = rl.LoadTexture("assets/images/item_tree0.png")
    textures_array[.small_rock] = rl.LoadTexture("assets/images/item_small_rock0.png")

    for i in game.current_entity_number..<(number+game.current_entity_number) {
        #partial switch item_type {
            case .item_wood:
            game.entities[i] = Entity {
                pos = from_entity.pos,
                vel = {0.0, 0.0},
                type = .item,
                item = {
                    type = item_type,
                    count = number_of_items
                },
                alive = true,
                texture = textures_array[.wood],
                rect = {
                    {from_entity.pos.x, from_entity.pos.y},
                    f32(textures_array[.wood].width),
                    f32(textures_array[.wood].height)
                }
            }
            
            case .item_small_rock:
            game.entities[i] = Entity {
                pos = from_entity.pos,
                vel = {0.0, 0.0},
                type = .item,
                item = {
                    type = item_type,
                    count = number_of_items
                },
                alive = true,
                texture = textures_array[.small_rock],
                rect = {
                    {from_entity.pos.x, from_entity.pos.y},
                    f32(textures_array[.small_rock].width),
                    f32(textures_array[.small_rock].height)
                }
            }
        }
        // On pose ça là, comme ça l'entité est créée.
        game.entities[i].tile_pos = {int(game.entities[i].pos.x) / TILE_LENGTH, int(game.entities[i].pos.y) / TILE_LENGTH}
        game.entities[i].pos_origin = game.entities[i].pos
    }

    // On rajoute le nombre d'entités ajoutés.
    game.current_entity_number += number

    return true
}
// WORKING
game_put_entity_to_tiles :: proc(game: ^Game) {
    for &en in game.entities {
        en.pos.x = math.floor_f32(math.round_f32(en.pos.x / TILE_LENGTH) * TILE_LENGTH)
        en.pos.y = math.floor_f32(math.round_f32(en.pos.y / TILE_LENGTH) * TILE_LENGTH)
        en.pos_origin = en.pos
        en.tile_pos = {int(en.pos.x) / TILE_LENGTH, int(en.pos.y) / TILE_LENGTH}
    }
}

// WORKING
// Pour créer les tiles dans le monde, pour l'instant ne sert à rien car Odin mets déjà les valeurs par défaut, à voir pour plus tard.
game_create_tiles :: proc(game: ^Game) {
    textures_array: [Texture_type]rl.Texture
    textures_array[.herb] = rl.LoadTexture("assets/images/herb.png")
    
    for &tile in game.tiles {
        tile.type = .herb
        tile.texture = textures_array[.herb]
        tile.flags = {}
        // tile.prepared = false
        // tile.occuped = false
    }
}

// WORKING
game_check_tiles_occuped :: proc(game: ^Game) {
    for &tile in game.tiles {
        tile.flags -= { .occuped } // J'enlève le fait qu'il soit occupé par quelque chose au dessus.
    }

    // for en in game.entities {
    //     if en.type == .rock0 {
    //         if (en.tile_pos.x >= 0 && en.tile_pos.x < NUM_TILES_X) && (en.tile_pos.y >= 0 && en.tile_pos.y < NUM_TILES_Y) {
    //             index: int = en.tile_pos.x * NUM_TILES_Y + en.tile_pos.y
    //             game.tiles[index].flags += { .occuped }
    //         }
    //         else {
    //             fmt.println("Entity out of bounds: pos =", en.tile_pos)
    //         }
    //     }
    // }

    for &en in game.entities {
        if en.type != .player {
            if en.alive {
                index: int = en.tile_pos.x * NUM_TILES_Y + en.tile_pos.y
                game.tiles[index].flags += { .occuped }
                game.tiles[index].entity_on_top = en.type
            }
        }
    }
}

// WORKING
game_get_entity_below_mouse :: proc(game: ^Game, mouse_tile_pos: Vec2i) -> ^Entity {
    for &en in game.entities {
        if en.tile_pos == mouse_tile_pos {
            en.flags += {.hovered}
            return &en
        }
        en.flags -= {.hovered}
    }

    return nil
}

game_get_entity_below_mouse_aabb :: proc(game: ^Game, mouse_pos: Vec2f) -> ^Entity {
    for &en in game.entities {
        if rect_contains(en.rect, mouse_pos) {
            en.flags += {.hovered}
            return &en
        }
        en.flags -= {.hovered}
    }

    return nil
}

// WORKING
game_is_entity_below_mouse :: proc(game: ^Game, mouse_tile_pos: Vec2i, en: Entity) -> bool {
    if mouse_tile_pos == en.tile_pos {
        return true
    }
    return false
}

// WORKING
game_ui_show_entity_type_below_mouse :: proc(game: ^Game, en: ^Entity) {
    if en != nil {
        text: cstring = fmt.ctprint(en.type)
        text_font_size: i32 = 32

        rl.DrawRectangle((WINDOW_W / 2) - 30, (75 / 2) - 5, 105, 40, rl.GRAY)
        rl.DrawText(text, (WINDOW_W / 2) - 25, 75 / 2, text_font_size, rl.BLACK)
    }
}

// WORKING
ui_show_fps :: proc(color: rl.Color) {
    text_fps: cstring = fmt.ctprint("FPS: ", rl.GetFPS())
    text_font_size: i32 = 32

    rl.DrawText(text_fps, 20, 20, text_font_size, color)
}

// Pour get les positions dans le monde, et les positions en fonction des tiles.
// WORKING
game_get_world_pos :: proc(position: rl.Vector2, camera2D: rl.Camera2D) -> rl.Vector2 {
    return rl.GetScreenToWorld2D(position, camera2D)
}

// WORKING
game_get_tile_from_world_pos :: proc(position: rl.Vector2, camera2D: rl.Camera2D) -> Vec2i {
    tile_pos: Vec2i
    tile_pos.x = int(math.floor(game_get_world_pos(position, camera2D).x) / TILE_LENGTH) * GAME_SCALE
    tile_pos.y = int(math.floor(game_get_world_pos(position, camera2D).y) / TILE_LENGTH) * GAME_SCALE

    return tile_pos
}

// WORKING
game_init :: proc(game: ^Game) {
    game_create_tiles(game)
    game_create_n_number_of_entity(game, 1, .player)
    game_create_n_number_of_entity(game, 15, .rock0)
    game_create_n_number_of_entity(game, 12, .tree0)
    game_put_entity_to_tiles(game)
    game_check_tiles_occuped(game)
}

// WORKING
game_quit :: proc(game: ^Game) {
}

// WORKING
get_delta_time :: proc() -> f32 {
    return rl.GetFrameTime()
}

// WORKING
almost_equals :: proc(a: f32, b: f32, epsilon: f32) -> bool {
    return abs(a - b) <= epsilon
}

// WORKING
animate_f32_to_target :: proc(value: ^f32, target: f32, delta_time: f32, rate: f32) -> bool {
    value^ += (target - value^) * (1.0 - math.pow(2.0, -rate * delta_time))
    if almost_equals(value^, target, 0.001) {
        value^ = target
        return true
    }

    return false
}

// WORKING
animate_vector2_to_target :: proc(value: ^rl.Vector2, target: rl.Vector2, delta_time: f32, rate: f32) {
    animate_f32_to_target(&value.x, target.x, delta_time, rate)
    animate_f32_to_target(&value.y, target.y, delta_time, rate)
}

main :: proc() {
    fmt.println("Raylib init !")
    rl.InitWindow(WINDOW_W, WINDOW_H, "Broken Lands"); defer rl.CloseWindow()
    rl.SetConfigFlags({.WINDOW_RESIZABLE})
    rl.SetTargetFPS(240)

    game_init(&game); defer game_quit(&game)

    // Pour déplacer le joueur.
    player_pointer: ^Entity

    // Put it in game loop ?
    // Find player to map to pointer.
    if player_pointer == nil {
        for &en in game.entities {
            if en.type == .player {
                player_pointer = &en
                break // On sort de la boucle
            }
        }
    }

    player_camera: rl.Camera2D = {
        offset = {f32(WINDOW_W / 2), f32(WINDOW_H / 2)}, // Centered to screen
        target = player_pointer.pos, // Player position
        rotation = 0.0,
        zoom = 2.5
    }

    for !rl.WindowShouldClose() {
        rl.BeginDrawing(); defer rl.EndDrawing()
        // rl.ClearBackground({64, 155, 145, 255})
        rl.ClearBackground(rl.BLACK)

        dt := get_delta_time()

        rl.BeginMode2D(player_camera)

        // The true mouse position in world space.
        mouse_world_pos := game_get_world_pos(rl.GetMousePosition(), player_camera)

        // The mouse position on tile in the world space.
        mouse_tile_pos := game_get_tile_from_world_pos(rl.GetMousePosition(), player_camera)
        // fmt.println(mouse_world_pos, mouse_tile_pos)

        // On va check à chaque fois qu'on casse un truc dans le jeu.
        entity_below_mouse := game_get_entity_below_mouse_aabb(&game, mouse_world_pos)

        // Input
        if rl.IsKeyPressed(.F11) {
            rl.ToggleFullscreen()
        }

        // Player mouse
        if rl.IsMouseButtonPressed(.LEFT) {
            // On gère le cas où il n'y a pas d'entité sous la souris, sinon ça cause un crash.
            if entity_below_mouse != nil && entity_below_mouse.type != .player && entity_below_mouse.type != .item {
                entity_below_mouse.health -= 5.0
                if entity_below_mouse.health <= 0.0 {
                    // Create new entity based on the entity destroyed
                    #partial switch entity_below_mouse.type {
                        case .tree0:
                        game_create_n_number_of_item_from_entity (&game, 1, 1, .item_wood, entity_below_mouse^)

                        case .rock0:
                        game_create_n_number_of_item_from_entity(&game, 1, 1, .item_small_rock, entity_below_mouse^)
                    }
                    game.current_entity_number -= 1
                    mem.set(entity_below_mouse, 0, size_of(Entity)) // On erase l'entity comme ça pour l'instant
                }
            }
        }
        else if rl.IsMouseButtonPressed(.RIGHT) {
            if entity_below_mouse != nil {
                fmt.println(entity_below_mouse.health)
                fmt.println(entity_below_mouse.alive)
            }
        }

        // Player deplacement
        if rl.IsKeyDown(.S) {
            player_pointer.vel.y = 100.0
        }
        else if rl.IsKeyDown(.W) {
            player_pointer.vel.y = -100.0
        }
        else {
            player_pointer.vel.y = 0.0
        }

        if rl.IsKeyDown(.A) {
            player_pointer.vel.x = -100.0
        }
        else if rl.IsKeyDown(.D) {
            player_pointer.vel.x = 100.0
        }
        else {
            player_pointer.vel.x = 0.0
        }

        player_pointer.pos += linalg.normalize0(player_pointer.vel) * dt * 100 // Normalisation du vecteur
        player_pointer.tile_pos = {int(player_pointer.pos.x) / TILE_LENGTH, int(player_pointer.pos.y) / TILE_LENGTH}

        animate_vector2_to_target(&player_camera.target, player_pointer.pos, dt, 20.0) // Anime la caméra vers le joueur

        game_check_tiles_occuped(&game)

        // Rect setting
        for &en in game.entities {
            if en.alive {
                scaled_width: f32 = f32(en.texture.width) * GAME_SCALE
                scaled_height: f32 = f32(en.texture.height) * GAME_SCALE

                en.rect.x = en.pos.x - scaled_width / 2.0

                if en.type == .tree0 {
                    en.rect.y = en.pos.y - scaled_height // tree0 is rendered from .bottom_center
                }
                else {
                    en.rect.y = en.pos.y - scaled_height / 2.0
                }

                en.rect.width = scaled_width
                en.rect.height = scaled_height
            }
        }

        // Tiles rendering
        for x in 0..<NUM_TILES_X {
            for y in 0..<NUM_TILES_Y {
                tile := game.tiles[x * NUM_TILES_Y + y]
                #partial switch tile.type {
                    case .herb:
                    // if int(mouse_tile_pos.x) == x && int(mouse_tile_pos.y) == y {
                    //     rl.DrawTextureV(game.textures_array[.herb], {f32(x) * TILE_LENGTH, f32(y) * TILE_LENGTH}, rl.RED) // Need to multiply by TILE_LENGTH
                    // }
                    // Permets d'appliquer un scaling.

                    draw_sprite(tile.texture, {f32(x) * TILE_LENGTH, f32(y) * TILE_LENGTH}, rotation=0, scale=GAME_SCALE)
                    // rl.DrawTextureEx(tile.texture, {f32(x) * TILE_LENGTH, f32(y) * TILE_LENGTH}, rotation=0, scale=GAME_SCALE, tint=rl.WHITE) // Need to multiply by TILE_LENGTH
                    when ODIN_DEBUG { // En cas de débugage.
                        if .occuped in tile.flags {
                            // rl.DrawTextureEx(tile.texture, {f32(x) * TILE_LENGTH, f32(y) * TILE_LENGTH}, rotation=0, scale=GAME_SCALE, tint=rl.BLUE) // Need to multiply by TILE_LENGTH
                            draw_sprite(tile.texture, {f32(x) * TILE_LENGTH, f32(y) * TILE_LENGTH}, rotation=0, scale=GAME_SCALE, tint=rl.BLUE)
                        }
                    }
                }
            }
        }

        // Entities rendering
        for &en in game.entities {
            if !en.alive { // On skip si l'entité n'est plus là, pas besoin de la render.
                continue
            }

            #partial switch en.type {
                case .player:
                    // rl.DrawTextureV(en.texture, {en.pos.x, en.pos.y + f32(y_offset)}, rl.WHITE)
                    draw_sprite(en.texture, {en.pos.x, en.pos.y}, rotation=0, scale=GAME_SCALE)
                    // when ODIN_DEBUG do rl.DrawRectangleLines(i32(en.pos.x) - i32(en.texture.width / 2), i32(en.pos.y) - i32(en.texture.height / 2), i32(en.texture.width), i32(en.texture.height), rl.RED)
                    when ODIN_DEBUG do rl.DrawRectangleLines(i32(en.rect.pos.x), i32(en.rect.pos.y), i32(en.texture.width), i32(en.texture.height), rl.RED)

                case .rock0:
                    if .hovered in en.flags {
                        draw_sprite(en.texture, {en.pos.x, en.pos.y}, rotation=0, scale=GAME_SCALE, tint=rl.GRAY)
                        // rl.DrawTextureV(en.texture, {en.pos.x, en.pos.y + f32(y_offset)}, rl.GRAY)
                    }
                    else {
                        // rl.DrawTextureV(en.texture, {en.pos.x, en.pos.y + f32(y_offset)}, rl.WHITE)
                        draw_sprite(en.texture, {en.pos.x, en.pos.y}, rotation=0, scale=GAME_SCALE)
                        when ODIN_DEBUG do rl.DrawRectangleLines(i32(en.rect.pos.x), i32(en.rect.pos.y), i32(en.texture.width), i32(en.texture.height), rl.RED)
                        // when ODIN_DEBUG do rl.DrawRectangleLines(i32(en.pos.x) - i32(en.texture.width / 2), i32(en.pos.y) - i32(en.texture.height / 2), i32(en.texture.width), i32(en.texture.height), rl.RED)
                    }

                case .tree0:
                    if .hovered in en.flags {
                        // rl.DrawTextureV(en.texture, {en.pos.x, en.pos.y + f32(y_offset)}, rl.GRAY)
                        draw_sprite(en.texture, {en.pos.x, en.pos.y}, rotation=0, scale=GAME_SCALE, pivot=.bottom_center,tint=rl.GRAY)
                    }
                    else {
                        // rl.DrawTextureV(en.texture, {en.pos.x, en.pos.y + f32(y_offset)}, rl.WHITE)
                        draw_sprite(en.texture, {en.pos.x, en.pos.y}, rotation=0, scale=GAME_SCALE, pivot=.bottom_center)
                        when ODIN_DEBUG do rl.DrawRectangleLines(i32(en.rect.pos.x), i32(en.rect.pos.y), i32(en.texture.width), i32(en.texture.height), rl.RED)
                        // when ODIN_DEBUG do rl.DrawRectangleLines(i32(en.pos.x) - i32(en.texture.width / 2), i32(en.pos.y) - i32(en.texture.height / 2), i32(en.texture.width), i32(en.texture.height), rl.RED)
                    }

                case .item:
                    draw_sprite(en.texture, {en.pos.x, en.pos.y}, rotation=0, scale=GAME_SCALE)
            }
        }

        rl.EndMode2D() // On arrête le rendering avec la caméra car les choses ci-dessous devront être rendu sans prendre en compte la caméra.

        // Infos rendering
        game_ui_show_entity_type_below_mouse(&game, entity_below_mouse) // On mets ça en dehors pour que ça se base sur l'écran, et non par rapport à la caméra.
        ui_show_fps(rl.WHITE)
    }
}
