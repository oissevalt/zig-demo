const std = @import("std");

var prng: ?std.Random.DefaultPrng = null;

fn getOrInitRandom() std.Random {
    if (prng == null) {
        initRandom();
    }
    return prng.?.random();
}

fn initRandom() void {
    const seed = blk: {
        var buffer: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&buffer)) catch |err| {
            std.debug.print("Failed to get random: {?}\n", .{err});
        };
        break :blk buffer;
    };
    prng = std.Random.DefaultPrng.init(seed);
}

/// Fill the buffer with random characters from the set. The PRNG algorithm
/// will be that used by `std.Random.DefaultPrng`, which is currently Xoshiro256++.
pub fn fillBuffer(comptime T: type, buf: []T, set: []const T) void {
    const rand = getOrInitRandom();
    for (0..(buf.len)) |index| {
        const n = rand.uintLessThan(usize, set.len);
        buf[index] = set[n];
    }
}
