const c = @import("c.zig").c;
const std = @import("std");

const GLFWError = error{ FailedToCreateWindow, FailedToInit };

pub const Window = struct {
    handle: *c.GLFWwindow,

    const Self = @This();

    pub fn create(width: u32, height: u32, app_name: [*:0]const u8) GLFWError!Self {
        var result = c.glfwInit();
        if (result != c.GLFW_TRUE) return GLFWError.FailedToInit;

        c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);
        c.glfwWindowHint(c.GLFW_RESIZABLE, c.GLFW_FALSE);

        const handle = c.glfwCreateWindow(@intCast(width), @intCast(height), app_name, null, null) orelse {
            c.glfwTerminate();
            return GLFWError.FailedToCreateWindow;
        };

        return Self{
            .handle = handle,
        };
    }

    pub fn loop(self: *const Self) void {
        _ = self;
        c.glfwPollEvents();
    }

    pub fn shouldClose(self: *const Self) bool {
        return (c.glfwWindowShouldClose(self.handle) == c.GLFW_TRUE);
    }

    pub fn destroy(self: *const Self) void {
        c.glfwDestroyWindow(self.handle);
        c.glfwTerminate();
    }
};
