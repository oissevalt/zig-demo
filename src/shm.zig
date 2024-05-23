const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const mem = std.mem;
const fs = std.fs;

const PROT = std.posix.PROT;
const MAP = std.posix.MAP;
const File = std.fs.File;

pub fn intercomm(comptime T: type, comptime data: []const T) !void {
    const raw_data = try posix.mmap(
        null, // Starting address, null meaning decided by OS.
        @sizeOf(T) * data.len, // Length of bytes mapped.
        PROT.READ | PROT.WRITE, // Protection flags.
        .{ .TYPE = .SHARED, .ANONYMOUS = true }, // Behavioural flags.
        -1, // File handle, -1 meaning not a file.
        0, // Offset.
    );
    defer posix.munmap(raw_data);

    const shared: *[data.len]T = @ptrCast(raw_data);
    @memcpy(shared, data);

    std.debug.print("[MAIN] Original array: {any}\n", .{shared});

    const pid = try posix.fork();
    if (pid == 0) {
        // Child process logic.
        std.debug.print("[CHILD] Sorting array ...\n", .{});
        mem.sort(T, shared, {}, std.sort.asc(T));
        posix.exit(0);
    } else {
        // Parent process logic.
        const result = posix.waitpid(pid, 0);
        if (result.status != 0) {
            return error.ChildError;
        }

        std.debug.print("[MAIN] Sorted array: {any}\n", .{shared});
    }
}

test "Interprocess Communication" {
    const array = comptime [_]u8{ 3, 9, 2, 8, 7, 4, 0, 7, 10, 5 };
    try intercomm(u8, &array);
}
