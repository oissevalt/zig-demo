//! Provide helper functions to execute [Brainfuck] programs.
//!
//! [Brainfuck]: https://en.wikipedia.org/wiki/Brainfuck

const std = @import("std");
const io = std.io;
const mem = std.mem;

const Allocator = std.mem.Allocator;

pub const Token = @import("token.zig").Token;

pub const Interpreter = @This();

pub const Environment = struct {
    /// The size of the data cell. Default is 30,000 elements.
    cell_size: usize = 30000,
    /// Whether to allow the wrapping data (e.g. 255 + 1 = 0),
    /// otherwise a `OverflowError` will be thrown. Defaults to enabled.
    wrap_overflow: bool = true,
    /// Where data is written to when the command `.` is executed.
    input_source: io.AnyReader = std.io.getStdIn().reader().any(),
    /// Where data is read from when the command `,` is executed.
    output_source: io.AnyWriter = std.io.getStdOut().writer().any(),
};

/// Error related to the commands.
pub const SyntaxError = error{
    /// '>' is executed when cell pointer is `cell_size - 1`.
    CellIndexOverflow,
    /// '<' is executed when cell pointer is 0.
    CellIndexUnderflow,
    /// '[' is not closed with ']'.
    MissingLoopEnd,
    /// ']' has no matching '['.
    MissingLoopStart,
};

pub const IOError = error{
    /// EOF is encountered in an I/O.
    EOF,
    /// Reading failed.
    Read,
    /// Writing failed.
    Write,
};

/// Error related to calculation.
pub const ArithmeticError = error{
    /// '+' is executed when cell data is 255.
    AddWithOverflow,
    /// '-' is executed when cell data is 0.
    SubtractWithUnderflow,
};

/// Executes the Brainfuck program with the provided environment configuration,
/// using `allocator` to manage memory. `ArithmeticError` will only be returned
/// when `wrap_overflow` is disabled in `environ`.
pub fn interpret(
    data: []const u8,
    environ: Environment,
    allocator: Allocator,
) (SyntaxError || ArithmeticError || IOError || Allocator.Error)!void {
    const tokens = try Token.tokenize(data, allocator);
    defer allocator.free(tokens);

    const cells = try allocator.alloc(u8, environ.cell_size);
    defer allocator.free(cells);
    @memset(cells, 0); // clear garbage data

    const jump_map = try drawJumpMap(tokens, allocator);
    defer allocator.free(jump_map);

    var cell_index: usize = 0;
    var token_index: usize = 0;

    while (token_index < tokens.len) {
        switch (tokens[token_index]) {
            .NextCell => {
                if (cell_index == cells.len - 1) {
                    return SyntaxError.CellIndexOverflow;
                }
                cell_index += 1;
            },
            .LastCell => {
                if (cell_index == 0) {
                    return SyntaxError.CellIndexUnderflow;
                }
                cell_index -= 1;
            },
            .Increment => {
                const add_result = @addWithOverflow(cells[cell_index], 1);
                if (add_result[1] != 0 and !environ.wrap_overflow) {
                    return ArithmeticError.AddWithOverflow;
                }
                cells[cell_index] = add_result[0];
            },
            .Decrement => {
                const sub_result = @subWithOverflow(cells[cell_index], 1);
                if (sub_result[1] != 0 and !environ.wrap_overflow) {
                    return ArithmeticError.SubtractWithUnderflow;
                }
                cells[cell_index] = sub_result[0];
            },
            .Input => {
                cells[cell_index] = environ.input_source.readByte() catch |err| switch (err) {
                    error.EndOfStream => return IOError.EOF,
                    else => return IOError.Read,
                };
            },
            .Output => {
                environ.output_source.writeByte(cells[cell_index]) catch |err| switch (err) {
                    error.EndOfStream => return IOError.EOF,
                    else => return IOError.Write,
                };
            },
            .JumpForward => {
                // For a JumpForward command, check if cells[cell_index] is
                // zero. If so, jump to the NEXT command of the matching JumpBackward.
                if (cells[cell_index] == 0) {
                    token_index = jump_map[token_index];
                }
            },
            .JumpBackward => {
                // For a JumpBackward command, check if cells[cell_index] is
                // NOT zero. If so, jump to the NEXT command of the matching JumpForward.
                if (cells[cell_index] != 0) {
                    token_index = jump_map[token_index];
                }
            },
        }
        token_index += 1;
    }
}

fn drawJumpMap(tokens: []const Token, allocator: Allocator) ![]const usize {
    const jump_map = try allocator.alloc(usize, tokens.len);
    @memset(jump_map, 0);

    var stack = std.ArrayList(usize).init(allocator);
    defer stack.deinit();

    for (tokens, 0..) |token, index| {
        switch (token) {
            .JumpForward => {
                try stack.append(index);
            },
            .JumpBackward => {
                const start = stack.popOrNull() orelse return SyntaxError.MissingLoopStart;
                jump_map[start] = index;
                jump_map[index] = start;
            },
            else => {},
        }
    }

    if (stack.items.len != 0) {
        return SyntaxError.MissingLoopEnd;
    }
    return jump_map;
}

test "Brainfuck 'Hello World'" {
    const testing = std.testing;

    const file = b: {
        const cwd = std.fs.cwd();
        break :b try cwd.openFile("src/brainfuck/hello_world.bf", .{});
    };
    defer file.close();

    const data = try file.reader().readAllAlloc(testing.allocator, 4096);
    defer testing.allocator.free(data);

    var output_buffer = std.ArrayList(u8).init(testing.allocator);
    defer output_buffer.deinit();

    try Interpreter.interpret(data, .{ .output_source = output_buffer.writer().any() }, testing.allocator);
    try testing.expectEqualStrings("Hello World!\n", output_buffer.items);
}
