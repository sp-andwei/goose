const std = @import("std");
const core = @import("core.zig");
// Circular dependency handled by Zig lazy evaluation of pointers/structs
const Connection = @import("connection.zig").Connection;

/// Represents a handler for a D-Bus signal.
pub const SignalHandler = struct {
    interface: []const u8,
    member: []const u8,
    callback: *const fn (ctx: ?*anyopaque, msg: core.Message) void,
    ctx: ?*anyopaque,
};

pub const InterfaceWrapper = struct {
    instance: *anyopaque,
    dispatch: *const fn (wrapper: *const InterfaceWrapper, conn: *Connection, msg: core.Message) anyerror!void,
    destroy: *const fn (wrapper: *const InterfaceWrapper, allocator: std.mem.Allocator) void,
    interface_name: [:0]const u8,
    path: [:0]const u8,
    intro_xml: [:0]const u8,
    /// Name of the Zig type registered at this handle, obtained via `@typeName`.
    /// Used by `getRegisteredObject` to guard against handle/type mismatches.
    type_name: []const u8,
};
