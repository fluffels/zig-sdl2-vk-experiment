const sdl = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_Vulkan.h");
});
const std = @import("std");
const vk = @import("vk");

const allocator = std.heap.c_allocator;

pub fn createDevice(gpu: vk.PhysicalDevice) anyerror!vk.Device {
    const queue = [_]vk.DeviceQueueCreateInfo{ try createQueue() };
    const createInfo = vk.DeviceCreateInfo{
        .queueCreateInfoCount = 1,
        .pQueueCreateInfos = &queue,
        .enabledExtensionCount = 0,
        .ppEnabledExtensionNames = undefined
    };
    const result = vk.CreateDevice(gpu, createInfo, null);
    return result;
}

pub fn createGPU(instance: vk.Instance) anyerror!vk.PhysicalDevice {
    const deviceCount = try vk.EnumeratePhysicalDevicesCount(instance);
    const physicalDevices = try allocator.alloc(vk.PhysicalDevice, deviceCount);
    defer allocator.free(physicalDevices);
    var result = try vk.EnumeratePhysicalDevices(instance, physicalDevices);
    return result.physicalDevices[0];
}

pub fn createInstance() anyerror!vk.Instance {
    var appInfo = vk.ApplicationInfo{
        .applicationVersion = 0,
        .engineVersion = 0,
        .apiVersion = 0,
    };
    var createInfo = vk.InstanceCreateInfo{
        .pApplicationInfo = &appInfo
    };
    var instance = try vk.CreateInstance(createInfo, null);
    return instance;
}

pub fn createQueue() anyerror!vk.DeviceQueueCreateInfo {
    const priority = [_]f32{1};
    const result = vk.DeviceQueueCreateInfo{
        .queueCount = 1,
        .queueFamilyIndex = 0,
        .pQueuePriorities = &priority
    };
    return result;
}

pub fn printVulkanVersion() anyerror!void {
    var version = try vk.EnumerateInstanceVersion();
    var major = version >> 22;
    var minor = (version >> 12) & 0x3ff;
    var patch = version & 0xfff;
    std.debug.warn("vulkan {}.{}.{}\n", .{major, minor, patch});
}

pub fn getRequiredExtensions(window: *sdl.SDL_Window) ![][*:0]u8 {
    var count: c_uint = 0;
    var success = sdl.SDL_Vulkan_GetInstanceExtensions(
        window, &count, null
    );
    if (@enumToInt(success) != sdl.SDL_TRUE) {
        std.debug.warn("could not fetch extension count", .{});
        // return;
    } else {
        std.debug.warn("requires {} extensions\n", .{ count });
    }
    var names = try allocator.alloc([*:0]u8, count);
    for (names) |*name| {
        name.* = @ptrCast([*:0]u8, try allocator.alloc(u8, 255));
    }
    success = sdl.SDL_Vulkan_GetInstanceExtensions(
        window,
        &count,
        @ptrCast([*c][*c]u8, @alignCast(8, names))
    );
    if (@enumToInt(success) != sdl.SDL_TRUE) {
        std.debug.warn("could not fetch extensions", .{});
        // return;
    } else {
        std.debug.warn("fetched {} extensions\n", .{ names.len });
    }
    for (names) |name| {
        std.debug.warn("required extension: {}\n", . { name });
    }
    return names;
}

pub fn main() anyerror!void {
    var code = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    var window = sdl.SDL_CreateWindow(
        "skybox",
        0, 0,
        640, 480,
        sdl.SDL_WINDOW_VULKAN
    ) orelse return;

    try printVulkanVersion();
    var instance = try createInstance();

    var extensions = getRequiredExtensions(window);

    var surface: sdl.VkSurfaceKHR = undefined;
    var success = sdl.SDL_Vulkan_CreateSurface(
        window,
        @ptrCast(sdl.VkInstance, &instance),
        &surface
    );
    if (@enumToInt(success) != sdl.SDL_TRUE) {
        std.debug.warn("could not create surface", .{});
        return;
    }

    var gpu = try createGPU(instance);
    var device = try createDevice(gpu);
    var queue = vk.GetDeviceQueue(device, 0, 0);

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
