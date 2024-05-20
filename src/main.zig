const std = @import("std");
const wordle = @import("wordle/wordle.zig");
const bf = @import("brainfuck/Interpreter.zig");
const date = @import("Date.zig");

pub fn main() !void {}

test "Import tests" {
    _ = wordle;
    _ = bf;
    _ = date;
}
