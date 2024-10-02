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

            std.debug.print("Current position: ({d}, {d}) '{c}' {}=> ", .{
                current_pos.col,
                current_pos.row,
                self.grid[current_pos.row][current_pos.col].tile,
                self.grid[current_pos.row][current_pos.col].energized,
            });

            switch (current_dir) {
                .north => {
                    std.debug.print("Current direction: North\n", .{});
                    if (current_pos.row == 0) break else current_pos.row -= 1;

                    switch (self.grid[current_pos.row][current_pos.col].tile) {
                        '/' => current_dir = Direction.east,
                        '\\' => current_dir = Direction.west,
                        '.', '|' => {},
                        '-' => {
                            std.debug.print("\nbranching\n", .{});
                            // left branch
                            if (current_pos.col != 0) {
                                try self.energize(current_pos, Direction.west, visited);
                            }
                            // right branch
                            if (current_pos.col != self.grid[0].len - 1) {
                                try self.energize(current_pos, Direction.east, visited);
                            }
                        },
                        else => return error.InvalidCharacter,
                    }
                },
                .south => {
                    std.debug.print("Current direction: South\n", .{});
                    if (current_pos.row >= self.grid.len - 1) break else current_pos.row += 1;

                    switch (self.grid[current_pos.row][current_pos.col].tile) {
                        '/' => current_dir = Direction.west,
                        '\\' => current_dir = Direction.east,
                        '.', '|' => {},
                        '-' => {
                            std.debug.print("\nbranching\n", .{});
                            // left branch
                            if (current_pos.col != 0) {
                                try self.energize(current_pos, Direction.west, visited);
                            }
                            // right branch
                            if (current_pos.col != self.grid[0].len - 1) {
                                try self.energize(current_pos, Direction.east, visited);
                            }
                        },
                        else => return error.InvalidCharacter,
                    }
                },
                .east => {
                    std.debug.print("Current direction: East\n", .{});
                    if (current_pos.col >= self.grid[0].len - 1) break else current_pos.col += 1;

                    switch (self.grid[current_pos.row][current_pos.col].tile) {
                        '/' => current_dir = Direction.north,
                        '\\' => current_dir = Direction.south,
                        '.', '-' => {},
                        '|' => {
                            std.debug.print("\nbranching\n", .{});
                            // north branch
                            if (current_pos.row != 0) {
                                try self.energize(current_pos, Direction.north, visited);
                            }
                            // south branch
                            if (current_pos.row < self.grid[0].len - 1) {
                                try self.energize(current_pos, Direction.south, visited);
                            }
                        },
                        else => return error.InvalidCharacter,
                    }
                },
                .west => {
                    std.debug.print("Current direction: West\n", .{});
                    if (current_pos.col == 0) break else current_pos.col -= 1;

                    switch (self.grid[current_pos.row][current_pos.col].tile) {
                        '/' => current_dir = Direction.south,
                        '\\' => current_dir = Direction.north,
                        '.', '-' => {},
                        '|' => {
                            std.debug.print("\nbranching\n", .{});
                            // north branch
                            if (current_pos.row != 0) {
                                try self.energize(current_pos, Direction.north, visited);
                            }
                            // south branch
                            if (current_pos.row < self.grid[0].len - 1) {
                                try self.energize(current_pos, Direction.south, visited);
                            }
                        },
                        else => return error.InvalidCharacter,
                    }
                },
            }
        }
        std.debug.print("## ending at pos ({d}, {d}) {any} ##\n\n", .{
            current_pos.col,
            current_pos.row,
            current_dir,
        });
    }

    pub fn calculateNumEnergizedTiles(self: *Self) !u64 {
        var visited = std.AutoHashMap(
            Vector,
            void,
        ).init(self.allocator);

        std.debug.print("Energized Tiles:\n", .{});

        try self.energize(
            Position{ .col = 0, .row = 0 },
            Direction.east,
            &visited,
        );

        var sum: u64 = 0;
        for (self.grid) |row| {
            for (row) |tile| {
                if (tile.energized) {
                    std.debug.print("#", .{});
                    sum += 1;
                } else {
                    std.debug.print(".", .{});
                }
            }
            std.debug.print("\n", .{});
        }
        return sum;
    }
};

pub fn part1(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    var contraption = try Contraption.init(allocator, input);
    std.debug.print("Input:\n{s}\n", .{input});
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
