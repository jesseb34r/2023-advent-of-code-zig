const std = @import("std");

const Map = struct {
    grid: [][]u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, input: []const u8) !Self {
        var grid_builder = std.ArrayList([]u8).init(allocator);
        var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
        while (input_lines.next()) |line| {
            var row = try allocator.alloc(u8, line.len);
            for (line, 0..) |val, i| {
                row[i] = val;
            }
            try grid_builder.append(row);
        }

        return Self{ .grid = try grid_builder.toOwnedSlice(), .allocator = allocator };
    }
};

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    const map = try Map.init(allocator, input);

    for (map.grid) |row| {
        std.debug.print("{s}\n", .{row});
    }

    return 0;
}

pub fn part2(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    _ = allocator;
    var sum: u64 = 0;

    while (input_lines.next()) |line| {
        _ = line;
    }
    sum += 0;

    return sum;
}

test "part1" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const test_input =
        \\2413432311323
        \\3215453535623
        \\3255245654254
        \\3446585845452
        \\4546657867536
        \\1438598798454
        \\4457876987766
        \\3637877979653
        \\4654967986887
        \\4564679986453
        \\1224686865563
        \\2546548887735
        \\4322674655533
    ;

    const expected_result = 102;
    const result = try part1(arena, test_input);
    try std.testing.expectEqual(expected_result, result);
}

test "part2" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const test_input =
        \\2413432311323
        \\3215453535623
        \\3255245654254
        \\3446585845452
        \\4546657867536
        \\1438598798454
        \\4457876987766
        \\3637877979653
        \\4654967986887
        \\4564679986453
        \\1224686865563
        \\2546548887735
        \\4322674655533
    ;

    const expected_result = 0;
    const result = try part2(arena, test_input);
    try std.testing.expectEqual(expected_result, result);
}
