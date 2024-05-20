const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Token = enum(u8) {
    NextCell = '>',
    LastCell = '<',
    Increment = '+',
    Decrement = '-',
    Input = ',',
    Output = '.',
    JumpForward = '[',
    JumpBackward = ']',

    /// Transforms the input data into tokens, using `allocator` to allocate the token slice.
    pub fn tokenize(data: []const u8, allocator: Allocator) Allocator.Error![]const Token {
        var buffer = std.ArrayList(Token).init(allocator);
        for (data) |char| try buffer.append(switch (char) {
            '>' => .NextCell,
            '<' => .LastCell,
            '+' => .Increment,
            '-' => .Decrement,
            ',' => .Input,
            '.' => .Output,
            '[' => .JumpForward,
            ']' => .JumpBackward,
            else => continue,
        });
        return try buffer.toOwnedSlice();
    }
};

test "Tokenization" {
    const input = ">>,.<hhh+[..]..++,-";
    const tokens = try Token.tokenize(input, std.testing.allocator);
    defer std.testing.allocator.free(tokens);
    std.debug.print("{any}\n", .{tokens});
}
