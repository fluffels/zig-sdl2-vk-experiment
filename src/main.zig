const c = @import("c.zig");
const std = @import("std");
const vk = @import("vk");

const panic = std.debug.panic;
const warn = std.debug.warn;

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

pub fn createInstance(extensions: [][*:0]u8) anyerror!vk.Instance {
    var appInfo = vk.ApplicationInfo{
        .applicationVersion = 0,
        .engineVersion = 0,
        .apiVersion = 0,
    };
    var createInfo = vk.InstanceCreateInfo{
        .pApplicationInfo = &appInfo,
        .enabledExtensionCount = @intCast(u32, extensions.len),
        .ppEnabledExtensionNames = @ptrCast([*]const [*:0]const u8, extensions)
    };
    warn("count: {}\n", .{ createInfo.enabledExtensionCount });
    warn("required extension: {}\n", . { extensions[0] });
    warn("required extension: {}\n", . { extensions[1] });
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
    warn("vulkan {}.{}.{}\n", .{major, minor, patch});
}

pub fn getRequiredExtensions(window: *c.SDL_Window) ![][*:0]u8 {
    var count: c_uint = 0;
    var success = c.SDL_Vulkan_GetInstanceExtensions(
        window, &count, null
    );
    if (@enumToInt(success) != c.SDL_TRUE) {
        warn("could not fetch extension count", .{});
        // return;
    } else {
        warn("requires {} extensions\n", .{ count });
    }
    var names = try allocator.alloc([*:0]u8, count);
    for (names) |*name| {
        name.* = @ptrCast([*:0]u8, try allocator.alloc(u8, 255));
    }
    success = c.SDL_Vulkan_GetInstanceExtensions(
        window,
        &count,
        @ptrCast([*c][*c]u8, @alignCast(8, names))
    );
    if (@enumToInt(success) != c.SDL_TRUE) {
        warn("could not fetch extensions", .{});
        // return;
    } else {
        warn("fetched {} extensions\n", .{ names.len });
    }
    return names;
}

pub fn main() anyerror!void {
    var code = c.SDL_Init(c.SDL_INIT_VIDEO);
    var window = c.SDL_CreateWindow(
        "skybox",
        0, 0,
        640, 480,
        c.SDL_WINDOW_VULKAN
    ) orelse return;

    try printVulkanVersion();

    var extensions = getRequiredExtensions(window)
        catch panic("could not get extensions: {}", .{ c.SDL_GetError() });
    var instance = try createInstance(extensions);

    var surface: c.VkSurfaceKHR = undefined;
    var success = c.SDL_Vulkan_CreateSurface(
        window,
        @ptrCast(c.VkInstance, &instance),
        &surface
    );
    if (@enumToInt(success) != c.SDL_TRUE) {
        panic("could not create surface: {}", .{ @ptrCast([*:0]const u8, c.SDL_GetError()) });
    }

    var gpu = try createGPU(instance);
    var device = try createDevice(gpu);
    var queue = vk.GetDeviceQueue(device, 0, 0);

    var done = false;
    while (!done) {
        c.SDL_PumpEvents();
        var keyCount: i32 = 0;
        var keys = c.SDL_GetKeyboardState(&keyCount);
        if (keys[c.SDL_SCANCODE_ESCAPE] == 1) {
            done = true;
        }
    }

    c.SDL_DestroyWindow(window);
    c.SDL_Quit();
}
