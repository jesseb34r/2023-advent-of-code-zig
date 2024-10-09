const std = @import("std");

const Point = struct {
    y: usize,
    x: usize,
};

const Map = struct {
    map: [][]const u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, input: *std.mem.TokenIterator(u8, .sequence)) !Self {
        var map = std.ArrayList([]const u8).init(allocator);
        while (input.next()) |line| {
            try map.append(line);
        }

        return Self{ .map = try map.toOwnedSlice(), .allocator = allocator };
    }

    pub fn getGalaxyPoints(self: *const Self) ![]Point {
        var galaxies = std.ArrayList(Point).init(self.allocator);

        for (self.map, 0..) |row, y| {
            for (row, 0..) |point, x| {
                if (point == '#') try galaxies.append(Point{ .y = y, .x = x });
            }
        }

        return try galaxies.toOwnedSlice();
    }
};

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    var map = try Map.init(allocator, &input_lines);
    const galaxy_points = try map.getGalaxyPoints();

    var empty_rows = try allocator.alloc(bool, map.map.len);
    @memset(empty_rows, true);
    var empty_cols = try allocator.alloc(bool, map.map[0].len);
    @memset(empty_cols, true);

    for (galaxy_points) |point| {
        empty_rows[point.y] = false;
        empty_cols[point.x] = false;
    }

    var sum: u64 = 0;
    for (0..(galaxy_points.len - 1)) |i| {
        for ((i + 1)..galaxy_points.len) |j| {
            const p1 = galaxy_points[i];
            const p2 = galaxy_points[j];
            const min_y = @min(p1.y, p2.y);
            const max_y = @max(p1.y, p2.y);
            const min_x = @min(p1.x, p2.x);
            const max_x = @max(p1.x, p2.x);

            var distance: u64 = 0;
            for (min_y..max_y) |y| {
                distance += if (empty_rows[y]) 2 else 1;
            }
            for (min_x..max_x) |x| {
                distance += if (empty_cols[x]) 2 else 1;
            }
            sum += distance;
        }
    }

    return sum;
}

pub fn part2(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    var map = try Map.init(allocator, &input_lines);
    const galaxy_points = try map.getGalaxyPoints();

    var empty_rows = try allocator.alloc(bool, map.map.len);
    @memset(empty_rows, true);
    var empty_cols = try allocator.alloc(bool, map.map[0].len);
    @memset(empty_cols, true);

    for (galaxy_points) |point| {
        empty_rows[point.y] = false;
        empty_cols[point.x] = false;
    }

    var sum: u64 = 0;
    for (0..(galaxy_points.len - 1)) |i| {
        for ((i + 1)..galaxy_points.len) |j| {
            const p1 = galaxy_points[i];
            const p2 = galaxy_points[j];
            const min_y = @min(p1.y, p2.y);
            const max_y = @max(p1.y, p2.y);
            const min_x = @min(p1.x, p2.x);
            const max_x = @max(p1.x, p2.x);

            var distance: u64 = 0;
            for (min_y..max_y) |y| {
                distance += if (empty_rows[y]) 1000000 else 1;
            }
            for (min_x..max_x) |x| {
                distance += if (empty_cols[x]) 1000000 else 1;
            }
            sum += distance;
        }
    }

    return sum;
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_input =
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    ;

    const expected_result = 374;
    const result = try part1(allocator, test_input);

    try std.testing.expectEqual(expected_result, result);
}
