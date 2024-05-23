const std = @import("std");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        const Node = struct {
            value: T,
            next: ?*Node,
        };

        /// Facilitates deinitialization.
        arena: ArenaAllocator,
        head: ?*Node,
        /// The count of elements on the stack. Should be read-only.
        length: usize,

        pub fn init(allocator: Allocator) Self {
            return .{
                .arena = ArenaAllocator.init(allocator),
                .head = null,
                .length = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            self.arena.deinit();
        }

        pub fn push(self: *Self, item: T) !void {
            const node = try self.arena.allocator().create(Node);
            node.next = self.head;
            node.value = item;

            self.head = node;
            self.length += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.head) |head| {
                const next = head.next;
                const value = head.value;
                self.head = next;
                self.length -= 1;

                self.arena.allocator().destroy(head);
                return value;
            }
            return null;
        }
    };
}

test "Stack" {
    var stack = Stack(usize).init(std.testing.allocator);
    defer stack.deinit();

    for (0..30) |i| {
        try stack.push(i);
    }
}
