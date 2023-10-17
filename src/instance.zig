const c = @import("c.zig").c;
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const InstanceError = error{
    FailedToCreateInstance,
    FailedToCreateAppInfo,
    FailedToCreateCreationInfo,
    ValidationLayerEnumerationFailed,
    ValidationLayersNotFound,
    OutOfMemory,
};

const AppInfo = struct { validation: bool };
const validation_layers = [_][*:0]const u8{"VK_LAYER_LUNARG_standard_validation"};

pub const Instance = struct {
    handle: c.VkInstance,

    const Self = @This();

    pub fn create(info: AppInfo, allocator: std.mem.Allocator) InstanceError!Self {
        if (info.validation) {
            if (!(try check_validation_support(allocator)))
                return error.ValidationLayersNotFound;
        } else {
            std.log.default.info("Validation supported!\n", .{});
        }
        var instance: c.VkInstance = undefined;
        var app_info = c.VkApplicationInfo{
            .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
            .pApplicationName = "Zinc App",
            .applicationVersion = c.VK_MAKE_VERSION(1, 0, 0),
            .pEngineName = "Zinc Engine",
            .engineVersion = c.VK_MAKE_VERSION(1, 0, 0),
            .apiVersion = c.VK_API_VERSION_1_3,
            .pNext = null,
        };
        var glfwExtensionCount: u32 = 0;
        // var glfwExtensions: c_uint = 0;
        var glfwExtensions: [*c]const [*c]const u8 = c.glfwGetRequiredInstanceExtensions(&glfwExtensionCount);
        // glfwExtensions = c.glfwGetRequiredInstanceExtensions(&glfwExtensionCount);

        var create_info = c.VkInstanceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .pApplicationInfo = &app_info,
            .enabledExtensionCount = glfwExtensionCount,
            .ppEnabledExtensionNames = glfwExtensions,
            .enabledLayerCount = 0,
            .flags = 0,
            .ppEnabledLayerNames = null,
            .pNext = null,
        };
        if (c.vkCreateInstance(&create_info, null, &instance) != c.VK_SUCCESS) {
            return error.FailedToCreateInstance;
        }
        return Self{
            .handle = instance,
        };
    }
    fn check_validation_support(allocator: std.mem.Allocator) !bool {
        var layer_count: u32 = 0;

        if (c.vkEnumerateInstanceLayerProperties(&layer_count, null) != c.VK_SUCCESS) {
            return error.ValidationLayerEnumerationFailed;
        }

        var available_layers = try allocator.alloc(c.VkLayerProperties, layer_count);
        defer allocator.free(available_layers);

        if (c.vkEnumerateInstanceLayerProperties(&layer_count, available_layers.ptr) != c.VK_SUCCESS) {
            return error.ValidationLayerEnumerationFailed;
        }
        std.log.debug("Enumeration completed!", .{});

        for (validation_layers) |layerName| {
            const layer_found = for (available_layers) |layerProperties| {
                if (std.mem.orderZ(u8, layerName, @as([*:0]const u8, @ptrCast(&layerProperties.layerName))) == .eq) {
                    break true;
                }
            } else false;

            std.log.debug("Found no layers!", .{});
            if (!layer_found) return false;
        }
        return true;
    }

    pub fn destroy(self: *Self) void {
        c.vkDestroyInstance(self.handle, null);
    }
};
