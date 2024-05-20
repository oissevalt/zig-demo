const std = @import("std");
const rand = @import("random.zig");
const term = @import("input.zig");

const String = std.ArrayList(u8);
const Allocator = std.mem.Allocator;

pub const Wordle = @This();

pub const WordleConfig = struct {
    word_length: usize = 5,
    max_attempts: usize = 6,
};

pub fn newGame(config: WordleConfig, allocator: Allocator) !void {
    var term_attr = try term.TerminalAttributes.init(allocator);
    defer term_attr.deinit();

    try disableEchoAndCanon(&term_attr);
    defer term_attr.restoreAttributes() catch |err| {
        std.debug.panic("Restoring terminal attributes failed: {?}\n", .{err});
    };

    const secret = try allocator.alloc(u8, config.word_length);
    defer allocator.free(secret);
    rand.fillBuffer(u8, secret, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");

    std.debug.print("Secret: \x1b[33m{s}\x1b[0m\n", .{secret});

    var attempt: usize = 0;
    while (attempt < config.max_attempts) : (attempt += 1) {
        const input = try term.readInput(attempt + 1, config.word_length, allocator);
        defer allocator.free(input);

        const writer = std.io.getStdOut().writer();
        const colors = try colourInput(input, secret, allocator);
        defer allocator.free(colors);

        try writer.print("\r[{d}] ", .{attempt + 1});
        for (0..(colors.len)) |index| {
            try writer.print("\x1b[{d}m{c}\x1b[0m", .{ colors[index], input[index] });
            if (index != colors.len - 1) {
                try writer.print(" ", .{});
            }
        }

        if (std.mem.eql(u8, input, secret)) {
            try writer.print("\nYou won!\n", .{});
            return;
        }
        try writer.print("\n", .{});
    }

    const writer = std.io.getStdOut().writer();
    try writer.print("You lost. Secret: {s}\n", .{secret});
}

fn colourInput(input: []const u8, secret: []const u8, allocator: Allocator) ![]const u8 {
    var colors = try allocator.alloc(u8, input.len);
    var color_map = std.AutoHashMap(u8, u8).init(allocator);
    defer color_map.deinit();

    for (secret) |char| {
        const result = try color_map.getOrPut(char);
        if (result.found_existing) {
            result.value_ptr.* += 1;
        } else {
            result.value_ptr.* = 1;
        }
    }

    for (0..(secret.len)) |index| {
        if (input[index] == secret[index]) {
            colors[index] = 32;
            if (color_map.getEntry(input[index])) |entry| {
                entry.value_ptr.* -= 1;
            }
        }
    }

    for (0..(secret.len)) |index| {
        if (colors[index] == 32) {
            continue;
        }
        const count = color_map.get(input[index]);
        if (count == null or count.? == 0) {
            colors[index] = 2;
        } else {
            colors[index] = 33;
            if (color_map.getEntry(input[index])) |entry| {
                entry.value_ptr.* -= 1;
            }
        }
    }

    return colors;
}

fn disableEchoAndCanon(attr: *term.TerminalAttributes) !void {
    try attr.getAttributes();
    attr.termios.lflag.ECHO = false;
    attr.termios.lflag.ICANON = false;
    try attr.setAttributes(attr.termios);
}

test "Wordle" {
    try newGame(.{}, std.testing.allocator);
}
