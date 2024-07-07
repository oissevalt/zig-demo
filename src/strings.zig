const std = @import("std");

const Allocator = std.mem.Allocator;

/// Fills the left side of `str` with `pad`, until the resulting string's
/// length reaches `len`. If the length of `str` is already no less than
/// `len`, `null` is returned. If the return value is not null, the caller
/// is responsible to deallocate the new string.
pub fn padLeftAlloc(
    allocator: Allocator,
    str: []const u8,
    len: usize,
    pad: u8,
) Allocator.Error!?[]u8 {
    if (str.len >= len) {
        return null;
    }
    const buf = try allocator.alloc(u8, len);
    padLeftHelper(buf, str, len - str.len, len, pad);
    return buf;
}

pub fn padLeftBuf(buf: []u8, str: []const u8, len: usize, pad: u8) error{ShortBuffer}!void {
    if (buf.len < len) {
        return error.ShortBuffer;
    }
    if (str.len >= len) {
        @memcpy(buf, str);
        return;
    }
    padLeftHelper(buf, str, len - str.len, len, pad);
}

pub fn padRightAlloc(
    allocator: Allocator,
    str: []const u8,
    len: usize,
    pad: u8,
) Allocator.Error!?[]u8 {
    if (str.len >= len) {
        return null;
    }
    const buf = try allocator.alloc(u8, len);
    padRightHelper(buf, str, len - str.len, len, pad);
    return buf;
}

pub fn padRightBuf(buf: []u8, str: []const u8, len: usize, pad: u8) error{ShortBuffer}!void {
    if (buf.len < len) {
        return error.ShortBuffer;
    }
    if (str.len >= len) {
        @memcpy(buf, str);
        return;
    }
    padRightHelper(buf, str, len - str.len, len, pad);
}

fn padLeftHelper(
    buf: []u8,
    str: []const u8,
    pad_len: usize,
    cap: usize,
    pad: u8,
) void {
    for (0..pad_len) |i| {
        buf[i] = pad;
    }
    @memcpy(buf[pad_len..cap], str);
}

fn padRightHelper(
    buf: []u8,
    str: []const u8,
    pad_len: usize,
    cap: usize,
    pad: u8,
) void {
    @memcpy(buf[0..pad_len], str);
    for (pad_len..cap) |i| {
        buf[i] = pad;
    }
}

test "pad" {
    const str: []const u8 = "14";

    const result = try padLeftAlloc(std.testing.allocator, str, 4, '0');
    defer if (result) |r| {
        std.testing.allocator.free(r);
    };
    std.debug.print("padLeftAlloc: {?s}\n", .{result});

    var buf = std.mem.zeroes([4]u8);
    try padLeftBuf(&buf, str, 4, '0');
    std.debug.print("padLeftBuf: {s}\n", .{buf});

    const result2 = try padRightAlloc(std.testing.allocator, str, 4, '0');
    defer if (result2) |r| {
        std.testing.allocator.free(r);
    };
    std.debug.print("padRightAlloc: {?s}\n", .{result2});

    var buf2 = std.mem.zeroes([4]u8);
    try padRightBuf(&buf2, str, 4, '0');
    std.debug.print("padRightBuf: {s}\n", .{buf2});
}
