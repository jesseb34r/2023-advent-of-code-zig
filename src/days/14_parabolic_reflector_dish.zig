const std = @import("std");

fn firstIndexOf(arr: []u8, char: u8) ?usize {
    for (arr, 0..) |item, i| if (item == char) return i;
    return null;
}

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var platform = try Platform.init(allocator, input);
    platform.shiftNorth();
    return platform.calcLoad();
}

const Platform = struct {
    allocator: std.mem.Allocator,
    rows: [][]u8,
    width: usize,
    height: usize,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, input: []const u8) !Self {
        var input_lines = std.mem.tokenizeSequence(u8, input, "\n");

        var rows_arr = std.ArrayList([]u8).init(allocator);
        while (input_lines.next()) |line| try rows_arr.append(@constCast(line));
        const rows = try rows_arr.toOwnedSlice();

        return Self{
            .allocator = allocator,
            .rows = rows,
            .width = rows[0].len,
            .height = rows.len,
        };
    }

    pub fn calcLoad(self: *const Self) u64 {
        var sum: u64 = 0;
        for (0..self.width) |col_index| {
            for (0..self.height) |row_index| {
                if (self.rows[row_index][col_index] == 'O') sum += self.height - row_index;
            }
        }
        return sum;
    }

    pub fn hash(self: *const Self) u64 {
        var hasher = std.hash.Wyhash.init(0);
        for (self.rows) |row| {
            hasher.update(row);
        }
        return hasher.final();
    }

    pub fn shiftNorth(self: *Self) void {
        columns: for (0..self.width) |current_col| {
            var next_open_index: usize = 0;
            for (0..self.height) |i| {
                if (i >= self.height - 1) continue :columns;
                if (self.rows[i][current_col] == '.') {
                    next_open_index = i;
                    break;
                }
            }

            // use while loop to allow jumping indexes
            var current_row: usize = next_open_index + 1;
            while (current_row < self.height) {
                switch (self.rows[current_row][current_col]) {
                    '.' => current_row += 1,
                    'O' => {
                        self.rows[next_open_index][current_col] = 'O';
                        self.rows[current_row][current_col] = '.';
                        next_open_index += 1;
                        current_row += 1;
                    },
                    '#' => {
                        if (current_row >= self.height - 1) continue :columns;
                        for ((current_row + 1)..self.height) |i| {
                            if (i >= self.height - 1) continue :columns;
                            if (self.rows[i][current_col] == '.') {
                                next_open_index = i;
                                current_row = i + 1;
                                break;
                            }
                        }
                    },
                    else => unreachable,
                }
            }
        }
    }

    pub fn shiftSouth(self: *Self) void {
        columns: for (0..self.width) |current_col| {
            var next_open_index: usize = self.height - 1;
            for (0..self.height) |i| {
                const reverse = self.height - 1 - i;
                if (reverse == 0) continue :columns;
                if (self.rows[reverse][current_col] == '.') {
                    next_open_index = reverse;
                    break;
                }
            }

            // use while loop to allow jumping indexes
            var current_row: usize = next_open_index - 1;
            while (current_row >= 0) {
                // std.debug.print("(col, row) = ({d}, {d})\n", .{ current_col, current_row });
                switch (self.rows[current_row][current_col]) {
                    '.' => {
                        if (current_row == 0) continue :columns;
                        current_row -= 1;
                    },
                    'O' => {
                        self.rows[next_open_index][current_col] = 'O';
                        self.rows[current_row][current_col] = '.';
                        if (current_row == 0) continue :columns;
                        next_open_index -= 1;
                        current_row -= 1;
                    },
                    '#' => {
                        if (current_row == 0) continue :columns;
                        for (0..current_row) |i| {
                            const reverse = current_row - 1 - i;
                            if (reverse == 0) continue :columns;
                            if (self.rows[reverse][current_col] == '.') {
                                next_open_index = reverse;
                                current_row = reverse - 1;
                                break;
                            }
                        }
                    },
                    else => unreachable,
                }
            }
        }
    }

    pub fn shiftWest(self: *Self) void {
        rows: for (0..self.height) |current_row| {
            var next_open_index: usize = 0;
            for (0..self.width) |j| {
                if (j >= self.width - 1) continue :rows;
                if (self.rows[current_row][j] == '.') {
                    next_open_index = j;
                    break;
                }
            }

            // use while loop to allow jumping indexes
            var current_col: usize = next_open_index + 1;
            while (current_col < self.width) {
                switch (self.rows[current_row][current_col]) {
                    '.' => current_col += 1,
                    'O' => {
                        self.rows[current_row][next_open_index] = 'O';
                        self.rows[current_row][current_col] = '.';
                        next_open_index += 1;
                        current_col += 1;
                    },
                    '#' => {
                        if (current_col >= self.width - 1) continue :rows;
                        for ((current_col + 1)..self.width) |j| {
                            if (j >= self.width - 1) continue :rows;
                            if (self.rows[current_row][j] == '.') {
                                next_open_index = j;
                                current_col = j + 1;
                                break;
                            }
                        }
                    },
                    else => unreachable,
                }
            }
        }
    }

    pub fn shiftEast(self: *Self) void {
        rows: for (0..self.height) |current_row| {
            var next_open_index: usize = self.width - 1;
            for (0..self.width) |j| {
                const reverse = self.width - 1 - j;
                if (reverse == 0) continue :rows;
                if (self.rows[current_row][reverse] == '.') {
                    next_open_index = reverse;
                    break;
                }
            }

            // use while loop to allow jumping indexes
            var current_col: usize = next_open_index - 1;
            while (current_row >= 0) {
                switch (self.rows[current_row][current_col]) {
                    '.' => {
                        if (current_col == 0) continue :rows;
                        current_col -= 1;
                    },
                    'O' => {
                        self.rows[current_row][next_open_index] = 'O';
                        self.rows[current_row][current_col] = '.';
                        if (current_col == 0) continue :rows;
                        next_open_index -= 1;
                        current_col -= 1;
                    },
                    '#' => {
                        if (current_col == 0) continue :rows;
                        for (0..current_col) |j| {
                            const reverse = current_col - 1 - j;
                            if (reverse == 0) continue :rows;
                            if (self.rows[current_row][reverse] == '.') {
                                next_open_index = reverse;
                                current_col = reverse - 1;
                                break;
                            }
                        }
                    },
                    else => unreachable,
                }
            }
        }
    }

    pub fn cycle(self: *Self) void {
        self.shiftNorth();
        self.shiftWest();
        self.shiftSouth();
        self.shiftEast();
    }
};

pub fn part2(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var platform = try Platform.init(allocator, input);

    var cycle: usize = 0;
    var hash_list = std.ArrayList(u64).init(allocator);
    outer: while (cycle < 1000000000) : (cycle += 1) {
        platform.cycle();
        const hash = platform.hash();
        // std.debug.print("{d} {d}\n", .{ hash, platform.calcLoad() });
        for (0..hash_list.items.len) |i| {
            const reverse = hash_list.items.len - 1 - i;
            if (hash == hash_list.items[reverse]) {
                const pattern_length = i + 1;
                const remaining_cycles = ((1000000000 - cycle) % pattern_length) - 1;
                // std.debug.print("\nPattern found!! Length = {d}, cycles to final value: {d}\n", .{ pattern_length, remaining_cycles });
                // pattern length = i + 1
                var end_cycle: usize = 0;
                while (end_cycle < remaining_cycles) : (end_cycle += 1) {
                    platform.cycle();
                    // std.debug.print("{d} {d}\n", .{ platform.hash(), platform.calcLoad() });
                }
                break :outer;
            }
        }
        try hash_list.append(hash);
    }

    return platform.calcLoad();
}

// TODO fix this step

// test "part1" {
//     var arena_allocator = std.heap.ArenaAllocator.init(std.testing.allocator);
//     defer arena_allocator.deinit();
//     const arena = arena_allocator.allocator();

//     const test_input =
//         \\O....#....
//         \\O.OO#....#
//         \\.....##...
//         \\OO.#O....O
//         \\.O.....O#.
//         \\O.#..O.#.#
//         \\..O..#O..O
//         \\.......O..
//         \\#....###..
//         \\#OO..#....
//     ;

//     const expected_result = 136;
//     const result = try part1(arena, test_input);
//     try std.testing.expectEqual(expected_result, result);
// }

// test "part2" {
//     var arena_allocator = std.heap.ArenaAllocator.init(std.testing.allocator);
//     defer arena_allocator.deinit();
//     const arena = arena_allocator.allocator();

//     const test_input =
//         \\O....#....
//         \\O.OO#....#
//         \\.....##...
//         \\OO.#O....O
//         \\.O.....O#.
//         \\O.#..O.#.#
//         \\..O..#O..O
//         \\.......O..
//         \\#....###..
//         \\#OO..#....
//     ;

//     const expected_result = 64;
//     const result = try part2(arena, test_input);
//     try std.testing.expectEqual(expected_result, result);
// }
