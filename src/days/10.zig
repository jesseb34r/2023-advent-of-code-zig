const std = @import("std");
const utils = @import("utils");

// point system is y then x
// (0,0) is top left
const Point = struct {
    y: usize,
    x: usize,

    const Self = @This();

    pub fn eql(self: *const Self, other: Point) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Map = struct {
    tiles: [][]const u8,
    start: Point,
    allocator: std.mem.Allocator,

    const Self = @This();

    // a column of rows
    pub fn init(allocator: std.mem.Allocator, lines: *std.mem.TokenIterator(u8, .sequence)) !Self {
        var tiles = std.ArrayList([]const u8).init(allocator);
        while (lines.next()) |line| {
            try tiles.append(line);
        }

        const start = outer: for (tiles.items, 0..) |row, y| {
            for (row, 0..) |tile, x| {
                if (tile == 'S') {
                    // std.debug.print("Start ({c}) found at point: (y: {d}, x: {d})S\n", .{ tile, y, x });
                    break :outer Point{ .y = y, .x = x };
                }
            }
        } else return error.NoStartFound;

        return Self{
            .tiles = try tiles.toOwnedSlice(),
            .start = start,
            .allocator = allocator,
        };
    }

    pub fn findFarthestDistance(self: *const Self) !u64 {
        var visited = std.AutoHashMap(Point, void).init(self.allocator);
        defer visited.deinit();

        var queue = std.ArrayList(struct { point: Point, distance: u64 }).init(self.allocator);
        defer queue.deinit();

        try queue.append(.{ .point = self.start, .distance = 0 });
        try visited.put(self.start, {});

        var max_distance: u64 = 0;

        while (queue.items.len > 0) {
            const current = queue.orderedRemove(0);
            if (current.distance > max_distance) {
                max_distance = current.distance;
            }

            const connectedPoints = try self.findConnectedPoints(current.point);
            for (connectedPoints) |next_point| {
                if (!visited.contains(next_point)) {
                    try visited.put(next_point, {});
                    try queue.append(.{ .point = next_point, .distance = current.distance + 1 });
                }
            }
        }

        return max_distance;
    }

    // F   |   7
    //     N
    // - W . E -
    //     S
    // L   |   J
    pub fn findConnectedPoints(self: *const Self, point: Point) ![]Point {
        var connected = std.ArrayList(Point).init(self.allocator);

        if (point.y > 0) {
            switch (self.tiles[point.y - 1][point.x]) {
                'F', '|', '7', 'S' => try connected.append(Point{ .y = point.y - 1, .x = point.x }),
                else => {},
            }
        }

        if (point.x > 0) {
            switch (self.tiles[point.y][point.x - 1]) {
                'L', '-', 'F', 'S' => try connected.append(Point{ .y = point.y, .x = point.x - 1 }),
                else => {},
            }
        }

        if (point.x < self.tiles[0].len - 1) {
            switch (self.tiles[point.y][point.x + 1]) {
                '7', '-', 'J', 'S' => try connected.append(Point{ .y = point.y, .x = point.x + 1 }),
                else => {},
            }
        }

        if (point.y < self.tiles.len - 1) {
            switch (self.tiles[point.y + 1][point.x]) {
                'J', '|', 'L', 'S' => try connected.append(Point{ .y = point.y + 1, .x = point.x }),
                else => {},
            }
        }

        return try connected.toOwnedSlice();
    }
};

pub fn part1(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    const map = try Map.init(allocator, input_lines);
    return map.findFarthestDistance();
}

pub fn part2(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    _ = allocator;
    var sum: u64 = 0;

    while (input_lines.next()) |line| {
        _ = line;
    }
    sum += 0;

    return sum;
}

test "part1" {
    const input =
        \\.....
        \\.S-7.
        \\.|.|.
        \\.L-J.
        \\.....
    ;
    const expected_result = 4;
    try utils.testPart(input, part1, expected_result);

    const input_2 =
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    ;
    const expected_result_2 = 8;
    try utils.testPart(input_2, part1, expected_result_2);
}

test "part2" {
    const input =
        \\
        \\
        \\
        \\
    ;
    const expected_result = 0;
    try utils.testPart(input, part2, expected_result);
}
