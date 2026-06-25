const std = @import("std");
const goose = @import("goose");
const Connection = goose.Connection;
const signal = goose.signal;
const GStr = goose.core.value.GStr;

const MyInterface = struct {
    conn: *Connection,
    ThisIsAProps: goose.Property(i32, .ReadWrite) = goose.property(i32, .ReadWrite, 43),
    ThisIsASignal: goose.Signal(GStr) = signal("ThisIsASignal", GStr),

    pub const INTERFACE_NAME = "dev.myinterface.test";

    pub fn init(conn: *Connection, _: void) @This() {
        return MyInterface{
            .conn = conn,
        };
    }

    pub fn Testing(self: *MyInterface) !GStr {
        std.debug.print("MyInterface.Testing called!\n", .{});
        std.debug.print("Prop value: {d}\n", .{self.ThisIsAProps.value});
        try self.ThisIsASignal.trigger(self.conn, GStr.new("from the random Signal"));
        return GStr.new("Hello");
    }
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    std.debug.print("Initializing connection...\n", .{});
    // NOTE: This requires a running DBus session bus.
    var conn = try Connection.init(allocator, .Session, init.io, init.environ_map);
    defer conn.close();

    std.debug.print("Registering interface {s}...\n", .{MyInterface.INTERFACE_NAME});
    const handle = try conn.registerObject(MyInterface, "dev.myinterface.test", "/dev/myinterface/test", {});

    // Retrieve a typed pointer to the registered object so we can access it
    // from outside a method handler — for example to emit signals on demand.
    const obj: *MyInterface = try conn.getRegisteredObject(MyInterface, handle);
    std.debug.print("Service registered. Handle: {d}, obj ptr: {*}\n", .{ handle, obj });
    std.debug.print("Ready to serve requests.\n", .{});

    // Demonstrate dispatchOnce: run a finite number of iterations so the
    // test binary can exit cleanly.  In a real application you would either
    // loop indefinitely with dispatchOnce (to interleave other work) or use
    // the simpler waitOnHandle.
    //
    // To run the blocking loop instead, replace the for-loop with:
    //   try conn.waitOnHandle(handle);

    // Example: trigger the signal once from outside any method handler before
    // entering the dispatch loop.  triggerSignal (used internally by
    // Signal.trigger) is protected by send_mutex, so this is safe even when
    // another task might be dispatching concurrently.
    try obj.ThisIsASignal.trigger(&conn, GStr.new("startup signal"));

    // Dispatch up to 64 messages then exit (for non-interactive testing).
    // Production code would run this loop forever or until a stop flag is set.
    var i: usize = 0;
    while (i < 64) : (i += 1) {
        conn.dispatchOnce(handle) catch |err| {
            // EndOfStream / ConnectionReset mean the bus went away.
            std.debug.print("dispatchOnce error: {s}\n", .{@errorName(err)});
            break;
        };
    }
}
