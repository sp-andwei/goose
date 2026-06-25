const std = @import("std");
const core = @import("core.zig");
const message = @import("message_utils.zig");
const Connection = @import("connection.zig").Connection;

/// Signal definition helper.
/// Returns a type that represents a signal carrying a payload of type T.
pub fn Signal(comptime T: type) type {
    return struct {
        name: [:0]const u8,
        interface: ?[:0]const u8 = null,
        path: ?[:0]const u8 = null,
        // Marker to identify this struct
        pub const __is_goose_signal = true;
        pub const PayloadType = T;

        /// Triggers a signal.
        /// `conn`: The connection to send the signal on.
        /// `payload`: The payload matching the signal's type.
        ///
        /// Thread-safe: delegates to `Connection.triggerSignal` which
        /// serializes serial allocation and the socket write via an internal
        /// mutex.  It is therefore safe to call this from a task other than
        /// the one running the dispatch loop.
        pub fn trigger(self: *@This(), conn: *Connection, payload: T) !void {
            const interface = self.interface orelse return error.SignalNotBound;
            const path = self.path orelse return error.SignalNotBound;

            var encoder = try message.BodyEncoder.encode(conn.__allocator, payload);
            defer encoder.deinit();

            try conn.triggerSignal(interface, path, self.name, encoder);
        }
    };
}

/// Creates a new signal definition.
pub fn signal(name: [:0]const u8, comptime T: type) Signal(T) {
    return .{ .name = name };
}

/// Defines the access permissions for a property.
pub const Access = enum { Read, Write, ReadWrite };

/// Property definition helper.
pub fn Property(comptime T: type, comptime access_mode: Access) type {
    return struct {
        value: T,
        pub const __is_goose_property = true;
        pub const DataType = T;
        pub const AccessMode = access_mode;
    };
}

/// Creates a new property with initial value and access.
pub fn property(comptime T: type, comptime access: Access, value: T) Property(T, access) {
    return .{ .value = value };
}
