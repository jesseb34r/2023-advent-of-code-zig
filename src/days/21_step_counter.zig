const std = @import("std");

const Position = struct {
    row: usize,
    col: usize,
};

const InfPosition = struct {
    row: isize,
    col: isize,
};

const Map = struct {
    allocator: std.mem.Allocator,
    map: std.ArrayList([]const u8),
    starting_pos: Position,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        // parse map
        var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
        var map = std.ArrayList([]const u8).init(allocator);
        while (input_lines.next()) |line| {
            try map.append(line);
        }

        // find starting position
        var starting_pos: Position = undefined;
        for (map.items, 0..) |row, r| {
            if (std.mem.indexOf(u8, row, "S")) |c| {
                starting_pos = Position{ .row = r, .col = c };
                break;
            }
        }

        return Self{
            .allocator = allocator,
            .map = map,
            .starting_pos = starting_pos,
        };
    }

    pub fn findPossibleTiles(self: *Self, steps: u64) !u64 {
        var visited = std.AutoHashMap(Position, void).init(self.allocator);
        var possible = std.AutoHashMap(Position, void).init(self.allocator);

        var current_positions = std.ArrayList(Position).init(self.allocator);
        try current_positions.append(self.starting_pos);

        // add tiles to possible when stepping to them, not after stepping on them
        // start with starting position
        try possible.put(self.starting_pos, {});

        // take max steps
        for (0..steps) |i| {
            // iterate over possible max distances from starting_pos
            var next_positions = std.ArrayList(Position).init(self.allocator);

            for (current_positions.items) |pos| {
                // check cardinal directions for valid moves (within bounds, is plot, not visited)
                // if is valid move and current step (i + 1) is even than it's possible
                const directions = [_]Position{
                    .{ .row = pos.row -| 1, .col = pos.col },
                    .{ .row = pos.row + 1, .col = pos.col },
                    .{ .row = pos.row, .col = pos.col -| 1 },
                    .{ .row = pos.row, .col = pos.col + 1 },
                };

                for (directions) |new_pos| {
                    // check in bounds
                    if (new_pos.row <= 0 or new_pos.row >= self.map.items.len - 1 or
                        new_pos.col <= 0 or new_pos.col >= self.map.items[0].len) continue;

                    // check is plot
                    if (self.map.items[new_pos.row][new_pos.col] != '.') continue;

                    // check visited
                    // if not visited, getOrPut adds to visited
                    const res = try visited.getOrPut(new_pos);
                    if (res.found_existing) continue;

                    // valid and not visited
                    try next_positions.append(new_pos);

                    // if current_step (i + 1) is even then add to possible tiles
                    if ((i + 1) % 2 == 0) try possible.put(new_pos, {});
                }
            }

            current_positions.clearAndFree();
            try current_positions.appendSlice(next_positions.items);
            next_positions.clearAndFree();
        }

        // return number of possible tiles
        return @as(u64, possible.count());
    }

    pub fn findPossibleTilesInfinite(self: *Self, steps: u64) !u64 {
        var visited = std.AutoHashMap(InfPosition, void).init(self.allocator);
        var possible = std.AutoHashMap(InfPosition, void).init(self.allocator);

        const map_height: isize = @intCast(self.map.items.len);
        const map_width: isize = @intCast(self.map.items[0].len);

        var current_positions = std.ArrayList(InfPosition).init(self.allocator);
        const inf_starting_pos = InfPosition{
            .row = @intCast(self.starting_pos.row),
            .col = @intCast(self.starting_pos.col),
        };
        try current_positions.append(inf_starting_pos);

        // add tiles to possible when stepping to them, not after stepping on them
        // start with starting position
        try possible.put(inf_starting_pos, {});

        // take max steps
        for (0..steps) |i| {
            // iterate over possible max distances from starting_pos
            var next_positions = std.ArrayList(InfPosition).init(self.allocator);

            for (current_positions.items) |pos| {
                // check cardinal directions for valid moves (is plot, not visited)
                // shift indexes to current slice frame at some point
                // if is valid move and current step (i + 1) is same even/odd as
                // steps than it's possible
                const directions = [_]InfPosition{
                    .{ .row = pos.row - 1, .col = pos.col },
                    .{ .row = pos.row + 1, .col = pos.col },
                    .{ .row = pos.row, .col = pos.col - 1 },
                    .{ .row = pos.row, .col = pos.col + 1 },
                };

                for (directions) |new_pos| {
                    // check is plot
                    // first shift pos to infinite frame
                    var shifted_row = @mod(new_pos.row, map_height);
                    var shifted_col = @mod(new_pos.col, map_width);
                    // if index is negative, access in reverse
                    if (shifted_row < 0) shifted_row = map_height + shifted_row;
                    if (shifted_col < 0) shifted_col = map_width + shifted_col;

                    const shifted_pos = Position{
                        .row = @intCast(shifted_row),
                        .col = @intCast(shifted_col),
                    };

                    // check shifted position
                    if (self.map.items[shifted_pos.row][shifted_pos.col] != '.') continue;

                    // check visited
                    // if not visited, getOrPut adds to visited
                    const res = try visited.getOrPut(new_pos);
                    if (res.found_existing) continue;

                    // valid and not visited
                    try next_positions.append(new_pos);

                    // if current_step (i + 1) is same even/odd as steps then add to possible tiles
                    if ((i + 1) % 2 == steps % 2) try possible.put(new_pos, {});
                }
            }

            current_positions.clearAndFree();
            try current_positions.appendSlice(next_positions.items);
            next_positions.clearAndFree();
        }

        // return number of possible tiles
        return @as(u64, possible.count());
    }
};

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var map = try Map.parse(allocator, input);
    return try map.findPossibleTiles(64);
}

pub fn part2(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var map = try Map.parse(allocator, input);
    return try map.findPossibleTilesInfinite(26501365);
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_input =
        \\
        \\
        \\
        \\
    ;

    const expected_result = 0;
    const result = try part1(allocator, test_input);

    try std.testing.expectEqual(expected_result, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_input =
        \\
        \\
        \\
        \\
    ;

    const expected_result = 0;
    const result = try part2(allocator, test_input);

    try std.testing.expectEqual(expected_result, result);
}
