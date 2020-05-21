const sdl = @cImport(@cInclude("SDL.h"));
const std = @import("std");

pub fn main() anyerror!void {
    var code = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    var window = sdl.SDL_CreateWindow(
        "skybox",
        0, 0,
        640, 480,
        0
    );

    var done = false;
    while (!done) {
        sdl.SDL_PumpEvents();
        var keyCount: i32 = 0;
        var keys = sdl.SDL_GetKeyboardState(&keyCount);
        if (keys[sdl.SDL_SCANCODE_ESCAPE] == 1) {
            done = true;
        }
    }

    sdl.SDL_DestroyWindow(window);
    sdl.SDL_Quit();
}
