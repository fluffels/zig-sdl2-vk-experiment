const sdl = @cImport(@cInclude("SDL.h"));
const std = @import("std");
const vk = @import("vk");

const allocator = std.heap.c_allocator;

pub fn createInstance() anyerror!vk.Instance {
    var appInfo = vk.ApplicationInfo{
        .applicationVersion = 0,
        .engineVersion = 0,
        .apiVersion = 0
    };
    var createInfo = vk.InstanceCreateInfo{
        .pApplicationInfo = &appInfo
    };
    var instance = try vk.CreateInstance(createInfo, null);
    return instance;
}

pub fn printVulkanVersion() anyerror!void {
    var version = try vk.EnumerateInstanceVersion();
    var major = version >> 22;
    var minor = (version >> 12) & 0x3ff;
    var patch = version & 0xfff;
    std.debug.warn("vulkan {}.{}.{}", .{major, minor, patch});
}

pub fn main() anyerror!void {
    var code = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    var window = sdl.SDL_CreateWindow(
        "skybox",
        0, 0,
        640, 480,
        0
    );
    try printVulkanVersion();
    var instance = try createInstance();

    const deviceCount = try vk.EnumeratePhysicalDevicesCount(instance);
    const physicalDevices = try allocator.alloc(vk.PhysicalDevice, deviceCount);
    defer allocator.free(physicalDevices);
    var vkResult = try vk.EnumeratePhysicalDevices(instance, physicalDevices);

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
