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
        vector: Vector,
        visited: *std.AutoHashMap(Vector, void),
    ) !void {
        var current_vector = vector;

        while (true) {
            if (visited.contains(current_vector)) break;
            try visited.put(current_vector, {});

            self.grid[current_vector.pos.row][current_vector.pos.col].energized = true;
            const current_tile = self.grid[current_vector.pos.row][current_vector.pos.col].tile;

            // branch
            if (current_tile == '-' and
                (current_vector.dir == Direction.north or current_vector.dir == Direction.south))
            {
                try self.energize(
                    Vector{ .pos = current_vector.pos, .dir = Direction.west },
                    visited,
                );
                try self.energize(
                    Vector{ .pos = current_vector.pos, .dir = Direction.east },
                    visited,
                );
                break;
            }

            if (current_tile == '|' and
                (current_vector.dir == Direction.east or current_vector.dir == Direction.west))
            {
                try self.energize(
                    Vector{ .pos = current_vector.pos, .dir = Direction.north },
                    visited,
                );
                try self.energize(
                    Vector{ .pos = current_vector.pos, .dir = Direction.south },
                    visited,
                );
                break;
            }

            // update dir
            if (current_tile == '/') {
                current_vector.dir = switch (current_vector.dir) {
                    .north => Direction.east,
                    .east => Direction.north,
                    .south => Direction.west,
                    .west => Direction.south,
                };
            }

            if (current_tile == '\\') {
                current_vector.dir = switch (current_vector.dir) {
                    .north => Direction.west,
                    .west => Direction.north,
                    .south => Direction.east,
                    .east => Direction.south,
                };
            }

            // update pos
            switch (current_vector.dir) {
                .north => {
                    if (current_vector.pos.row > 0) current_vector.pos.row -= 1 else break;
                },
                .south => {
                    if (current_vector.pos.row < self.grid.len - 1) current_vector.pos.row += 1 else break;
                },
                .east => {
                    if (current_vector.pos.col < self.grid[0].len - 1) current_vector.pos.col += 1 else break;
                },
                .west => {
                    if (current_vector.pos.col > 0) current_vector.pos.col -= 1 else break;
                },
            }
        }
    }

    pub fn calculateNumEnergizedTiles(self: *Self, starting_vector: Vector) !u64 {
        var visited = std.AutoHashMap(
            Vector,
            void,
        ).init(self.allocator);

        try self.energize(
            starting_vector,
            &visited,
        );

        var sum: u64 = 0;
        for (0..self.grid.len) |i| {
            for (0..self.grid[0].len) |j| {
                if (self.grid[i][j].energized) {
                    sum += 1;
                    self.grid[i][j].energized = false;
                }
            }
        }

        // std.debug.print("{d} with starting vector {any}\n", .{ sum, starting_vector });
        return sum;
    }
};

pub fn part1(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    var contraption = try Contraption.init(allocator, input);
    return try contraption.calculateNumEnergizedTiles(Vector{
        .pos = Position{ .col = 0, .row = 0 },
        .dir = Direction.east,
    });
}

pub fn part2(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    var contraption = try Contraption.init(allocator, input);

    var max_energized: u64 = 0;
    for (0..contraption.grid.len) |i| {
        max_energized = @max(
            @max(
                max_energized,
                try contraption.calculateNumEnergizedTiles(Vector{
                    .pos = Position{ .col = i, .row = 0 },
                    .dir = Direction.south,
                }),
            ),
            @max(
                max_energized,
                try contraption.calculateNumEnergizedTiles(Vector{
                    .pos = Position{ .col = i, .row = contraption.grid.len - 1 },
                    .dir = Direction.north,
                }),
            ),
        );
    }

    for (0..contraption.grid[0].len) |j| {
        max_energized = @max(
            @max(
                max_energized,
                try contraption.calculateNumEnergizedTiles(Vector{
                    .pos = Position{ .col = 0, .row = j },
                    .dir = Direction.west,
                }),
            ),
            @max(
                max_energized,
                try contraption.calculateNumEnergizedTiles(Vector{
                    .pos = Position{ .col = contraption.grid[0].len - 1, .row = j },
                    .dir = Direction.east,
                }),
            ),
        );
    }

    return max_energized;
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

    const expected_result = 51;
    const result = try part2(arena, mutable);
    try std.testing.expectEqual(expected_result, result);
}
