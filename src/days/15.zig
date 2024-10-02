const std = @import("std");

pub fn part1(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    _ = allocator;
    var input_sequences = std.mem.tokenizeSequence(u8, input, ",");

    var sum: u64 = 0;
    while (input_sequences.next()) |seq| {
        var hash: u64 = 0;
        for (seq) |c| hash = ((hash + c) * 17) % 256;
        sum += hash;
    }

    return sum;
}

const Lens = struct {
    label: []const u8,
    focal_length: u8,
};

const Map = struct {
    boxes: [256]std.ArrayList(Lens),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .boxes = undefined,
            .allocator = allocator,
        };
        for (&self.boxes) |*box| {
            box.* = std.ArrayList(Lens).init(allocator);
        }
        return self;
    }

    fn hash(seq: []const u8) u64 {
        var h: u64 = 0;
        for (seq) |char| h = ((h + char) * 17) % 256;
        return h;
    }

    pub fn dash(self: *Self, label: []const u8) void {
        const box_index = hash(label);
        for (self.boxes[box_index].items, 0..) |lens, i| {
            if (std.mem.eql(u8, lens.label, label)) {
                _ = self.boxes[box_index].orderedRemove(i);
                return;
            }
        }
    }

    pub fn equals(self: *Self, label: []const u8, focal_length: u8) !void {
        const box_index = hash(label);
        for (self.boxes[box_index].items, 0..) |lens, i| {
            if (std.mem.eql(u8, lens.label, label)) {
                _ = self.boxes[box_index].orderedRemove(i);
                try self.boxes[box_index].insert(
                    i,
                    Lens{
                        .label = label,
                        .focal_length = focal_length,
                    },
                );
                return;
            }
        }
        try self.boxes[box_index].append(Lens{
            .label = label,
            .focal_length = focal_length,
        });
    }

    pub fn getFocusingPower(self: *const Self) u64 {
        var sum: u64 = 0;
        for (self.boxes, 1..) |box, box_index| {
            for (box.items, 1..) |lens, lens_index| {
                // std.debug.print(
                //     "{d} * {d} * {d} = {d}\n",
                //     .{
                //         box_index,
                //         lens_index,
                //         lens.focal_length,
                //         box_index * lens_index * lens.focal_length,
                //     },
                // );
                sum += box_index * lens_index * lens.focal_length;
            }
        }
        return sum;
    }

    pub fn print(self: *const Self) !void {
        for (self.boxes, 0..) |box, i| {
            if (box.items.len > 0) {
                std.debug.print("Box {d}: ", .{i});
                for (box.items) |lens| {
                    std.debug.print("[{s} {d}] ", .{ lens.label, lens.focal_length });
                }
                std.debug.print("\n", .{});
            }
        }
        std.debug.print("\n", .{});
    }
};

pub fn part2(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    var input_sequences = std.mem.tokenizeSequence(u8, input, ",");

    var map = Map.init(allocator);

    while (input_sequences.next()) |seq| {
        for (seq, 0..) |char, i| {
            if (char == '-') {
                map.dash(seq[0..i]);
                break;
            }
            if (char == '=') {
                try map.equals(seq[0..i], seq[i + 1] - '0');
                break;
            }
        }
        // std.debug.print("After \"{s}\":\n", .{seq});
        // try map.print();
    }

    return map.getFocusingPower();
}

test "part1" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const input = "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7";
    const mutable = try arena.alloc(u8, input.len);
    std.mem.copyForwards(u8, mutable, input);

    const expected_result = 1320;
    const result = try part1(arena, mutable);
    try std.testing.expectEqual(expected_result, result);
}

test "part2" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const input = "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7";
    const mutable = try arena.alloc(u8, input.len);
    std.mem.copyForwards(u8, mutable, input);

    const expected_result = 145;
    const result = try part2(arena, mutable);
    try std.testing.expectEqual(expected_result, result);
}
