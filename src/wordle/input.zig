const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn readInput(
    attempt: usize,
    length: usize,
    allocator: Allocator,
) ![]const u8 {
    var buffer = std.ArrayList(u8).init(allocator);
    const reader = std.io.getStdIn().reader();

    try printInput(attempt, length, buffer.items, allocator);

    while (true) {
        const byte = try reader.readByte();
        switch (byte) {
            '\n' => {
                if (buffer.items.len == length) {
                    // Do not print '\n' here; the input should be coloured and displayed.
                    break;
                }
            },
            127 => { // backspace
                if (buffer.items.len != 0) {
                    _ = buffer.pop();
                }
            },
            65...90 => { // upper case
                if (buffer.items.len == length) {
                    continue;
                }
                try buffer.append(byte);
            },
            97...122 => { // lower case
                if (buffer.items.len == length) {
                    continue;
                }
                try buffer.append(byte - 32);
            },
            else => {}, // ignored
        }

        try printInput(attempt, length, buffer.items, allocator);
    }

    // Avoid returning buffer.items; unused capacity may leak.
    return try buffer.toOwnedSlice();
}

fn printInput(
    attempt: usize,
    length: usize,
    buffer: []const u8,
    allocator: Allocator,
) !void {
    var output_buffer = std.ArrayList(u8).init(allocator);
    defer output_buffer.deinit();

    for (0..length) |index| {
        const item = if (index < buffer.len) buffer[index] else '_';
        try output_buffer.append(item);
    }

    const writer = std.io.getStdOut().writer().any();
    try writer.print("\r[{d}] ", .{attempt});
    for (0..(output_buffer.items.len)) |index| {
        try writer.print("{c}", .{output_buffer.items[index]});
        if (index != output_buffer.items.len - 1) {
            try writer.print(" ", .{});
        }
    }
}

pub const TerminalAttributes = struct {
    pub const TerminalError = error{
        /// The operation is interrupted. (errno 4)
        Interrupted,
        /// Invalid file descriptor. (errno 9)
        BadFileDescriptor,
        /// Operation not supported by device. (errno 19)
        UnsupportedOperation,
        /// Invalid action, likely a wrong TCSA. (errno 22)
        InvalidAction,
        /// The file is not a terminal. (errno 25)
        NotTerminal,

        Unexpected,
    };

    allocator: Allocator,
    /// The file descriptor that `getAttributes` and `setAttributes` interact with.
    descriptor: i32 = 0,
    /// The termios obtained by the most recent `getAttributes` call.
    termios: *std.c.termios,
    /// The termios before the most recent `setAttributes` call.
    backup: ?std.c.termios = null,

    pub fn init(allocator: Allocator) !TerminalAttributes {
        const termios = try allocator.create(std.c.termios);
        return TerminalAttributes{
            .allocator = allocator,
            .termios = termios,
        };
    }

    pub fn deinit(self: TerminalAttributes) void {
        self.allocator.destroy(self.termios);
    }

    pub fn getAttributes(self: TerminalAttributes) TerminalError!void {
        if (std.c.tcgetattr(self.descriptor, self.termios) == 0) {
            return;
        }
        return getErrno();
    }

    pub fn setAttributes(self: *TerminalAttributes, termios: *std.c.termios) TerminalError!void {
        if (self.backup == null or &self.backup.? != termios) {
            self.backup = termios.*;
        }
        if (std.c.tcsetattr(self.descriptor, std.c.TCSA.FLUSH, termios) == 0) {
            return;
        }
        return getErrno();
    }

    /// Sets the terminal attributes to `self.last_backup`, if present.
    pub fn restoreAttributes(self: *TerminalAttributes) TerminalError!void {
        if (self.backup) |*backup| {
            return self.setAttributes(backup);
        }
    }

    fn getErrno() TerminalError {
        return switch (std.c._errno().*) {
            4 => TerminalError.Interrupted,
            9 => TerminalError.BadFileDescriptor,
            19 => TerminalError.UnsupportedOperation,
            22 => TerminalError.InvalidAction,
            25 => TerminalError.NotTerminal,
            else => TerminalError.Unexpected,
        };
    }
};
