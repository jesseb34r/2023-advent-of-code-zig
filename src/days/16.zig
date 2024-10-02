const std = @import("std");
const utils = @import("utils");

const Position = struct { row: usize, col: usize };

const Direction = enum { north, south, east, west };

const Vector = struct { pos: Position, dir: Direction };

const Tile = struct { tile: u8, energized: bool = false };

const Contraption = struct {
    grid: [][]Tile,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, input: []u8) !Self {
        var grid_builder = std.ArrayList([]Tile).init(allocator);
        var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
        while (input_lines.next()) |line| {
            var tile_row = try allocator.alloc(Tile, line.len);
            for (line, 0..) |char, i| {
                tile_row[i] = Tile{ .tile = char };
            }
            try grid_builder.append(tile_row);
        }

        return Self{ .grid = try grid_builder.toOwnedSlice(), .allocator = allocator };
    }

    fn energize(
        self: *const Self,
        start_pos: Position,
        direction: Direction,
        visited: *std.AutoHashMap(Vector, void),
    ) !void {
        var current_pos = start_pos;
        var current_dir = direction;

        while (true) {
            const key = Vector{ .pos = current_pos, .dir = current_dir };
            if (visited.contains(key)) break;
            try visited.put(key, {});

            self.grid[current_pos.row][current_pos.col].energized = true;
            const current_tile = self.grid[current_pos.row][current_pos.col].tile;

            // branch
            if (current_tile == '-' and
                (current_dir == Direction.north or current_dir == Direction.south))
            {
                try self.energize(current_pos, Direction.west, visited);
                try self.energize(current_pos, Direction.east, visited);
                break;
            }

            if (current_tile == '|' and
                (current_dir == Direction.east or current_dir == Direction.west))
            {
                try self.energize(current_pos, Direction.north, visited);
                try self.energize(current_pos, Direction.south, visited);
                break;
            }

            // update dir
            if (current_tile == '/') {
                current_dir = switch (current_dir) {
                    .north => Direction.east,
                    .east => Direction.north,
                    .south => Direction.west,
                    .west => Direction.south,
                };
            }

            if (current_tile == '\\') {
                current_dir = switch (current_dir) {
                    .north => Direction.west,
                    .west => Direction.north,
                    .south => Direction.east,
                    .east => Direction.south,
                };
            }

            // update pos
            switch (current_dir) {
                .north => {
                    if (current_pos.row > 0) current_pos.row -= 1 else break;
                },
                .south => {
                    if (current_pos.row < self.grid.len - 1) current_pos.row += 1 else break;
                },
                .east => {
                    if (current_pos.col < self.grid[0].len - 1) current_pos.col += 1 else break;
                },
                .west => {
                    if (current_pos.col > 0) current_pos.col -= 1 else break;
                },
            }
        }
    }

    pub fn calculateNumEnergizedTiles(self: *Self) !u64 {
        var visited = std.AutoHashMap(
            Vector,
            void,
        ).init(self.allocator);

        try self.energize(
            Position{ .col = 0, .row = 0 },
            Direction.east,
            &visited,
        );

        var sum: u64 = 0;
        for (self.grid) |row| {
            for (row) |tile| {
                if (tile.energized) sum += 1;
            }
        }
        return sum;
    }
};

pub fn part1(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    var contraption = try Contraption.init(allocator, input);
    return try contraption.calculateNumEnergizedTiles();
}

pub fn part2(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
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
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const input =
        \\.|...\....
        \\|.-.\.....
        \\.....|-...
        \\........|.
        \\..........
        \\.........\
        \\..../.\\..
        \\.-.-/..|..
        \\.|....-|.\
        \\..//.|....
    ;
    const mutable = try arena.alloc(u8, input.len);
    std.mem.copyForwards(u8, mutable, input);

    const expected_result = 46;
    const result = try part1(arena, mutable);
    try std.testing.expectEqual(expected_result, result);
}

test "part2" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const input =
        \\.|...\....
        \\|.-.\.....
        \\.....|-...
        \\........|.
        \\..........
        \\.........\
        \\..../.\\..
        \\.-.-/..|..
        \\.|....-|.\
        \\..//.|....
    ;
    const mutable = try arena.alloc(u8, input.len);
    std.mem.copyForwards(u8, mutable, input);

    const expected_result = 0;
    const result = try part2(arena, mutable);
    try std.testing.expectEqual(expected_result, result);
}
