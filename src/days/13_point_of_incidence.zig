const std = @import("std");

const Line = struct {
    line: []const u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, line: []const u8) Self {
        return Self{ .line = line, .allocator = allocator };
    }

    pub fn eql(self: Self, other: Self) !bool {
        if (self.line.len != other.line.len) return error.LineLengthMismatch;

        for (self.line, other.line) |a, b| {
            if (a != b) return false;
        }

        return true;
    }
};

const Pattern = struct {
    rows: []Line,
    columns: []Line,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, input_lines: [][]const u8) !Self {
        var rows_arr = std.ArrayList(Line).init(allocator);
        for (input_lines) |line| try rows_arr.append(Line.init(allocator, line));
        const rows = try rows_arr.toOwnedSlice();

        var cols_arr = std.ArrayList(Line).init(allocator);
        for (0..input_lines[0].len) |col_index| {
            var col_builder = std.ArrayList(u8).init(allocator);

            for (input_lines) |row| {
                try col_builder.append(row[col_index]);
            }

            try cols_arr.append(Line.init(allocator, try col_builder.toOwnedSlice()));
        }
        const columns = try cols_arr.toOwnedSlice();

        return Self{
            .rows = rows,
            .columns = columns,
            .allocator = allocator,
        };
    }

    // mirror_row_index is the index after the mirror
    // if the mirror is inbetween 5 and 6, index is 6
    fn isMirroredRows(self: *const Self, mirror_row_index: usize) !bool {
        var forward_index = mirror_row_index;
        var back_index = mirror_row_index - 1;

        if (!(try self.rows[forward_index].eql(self.rows[back_index]))) return error.NoMirrorAtIndex;

        while (true) {
            if (forward_index == self.rows.len - 1 or back_index == 0) return true;
            forward_index += 1;
            back_index -= 1;

            if (!(try self.rows[forward_index].eql(self.rows[back_index]))) return false;
        }
    }

    fn isMirroredColumns(self: *const Self, mirror_col_index: usize) !bool {
        var forward_index = mirror_col_index;
        var back_index = mirror_col_index - 1;

        if (!(try self.columns[forward_index].eql(self.columns[back_index]))) return error.NoMirrorAtIndex;

        while (true) {
            if (forward_index == self.columns.len - 1 or back_index == 0) return true;
            forward_index += 1;
            back_index -= 1;

            if (!(try self.columns[forward_index].eql(self.columns[back_index]))) return false;
        }
    }

    pub fn findMirrorIndex(self: *const Self) !u64 {
        for (1..self.rows.len) |row_index| {
            if (try self.rows[row_index].eql(self.rows[row_index - 1])) {
                if (try isMirroredRows(self, row_index)) return row_index * 100;
            }
        }

        for (1..self.columns.len) |col_index| {
            if (try self.columns[col_index].eql(self.columns[col_index - 1])) {
                if (try isMirroredColumns(self, col_index)) return col_index;
            }
        }

        return error.NoMirrorFound;
    }

    fn scoreLines(a: Line, b: Line) !u64 {
        if (a.line.len != b.line.len) return error.UnequalLineLength;

        var score: u64 = 0;
        for (0..a.line.len) |i| {
            if (a.line[i] != b.line[i]) score += 1;
        }
        return score;
    }

    pub fn findSmudgedMirrorIndex(self: *const Self) !u64 {
        for (1..self.rows.len) |row_index| {
            var forward_index = row_index;
            var back_index = row_index - 1;

            var score: u64 = 0;
            while (true) {
                score += try scoreLines(self.rows[forward_index], self.rows[back_index]);

                if (forward_index == self.rows.len - 1 or back_index == 0) break;
                forward_index += 1;
                back_index -= 1;
            }

            if (score == 1) return row_index * 100;
        }

        for (1..self.columns.len) |col_index| {
            var forward_index = col_index;
            var back_index = col_index - 1;

            var score: u64 = 0;
            while (true) {
                score += try scoreLines(self.columns[forward_index], self.columns[back_index]);

                if (forward_index == self.columns.len - 1 or back_index == 0) break;
                forward_index += 1;
                back_index -= 1;
            }

            if (score == 1) return col_index;
        }

        return error.NoSmudgedMirrorFound;
    }
};

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_lines = std.mem.splitSequence(u8, input, "\n");
    var sum: u64 = 0;

    var pattern_builder = std.ArrayList([]const u8).init(allocator);
    while (input_lines.next()) |line| {
        // std.debug.print("{s}\n", .{line});

        if (line.len > 0 and !std.mem.eql(u8, line, "\n")) {
            try pattern_builder.append(line);
        } else {
            const pattern = try Pattern.init(allocator, try pattern_builder.toOwnedSlice());
            // const result = try pattern.findMirrorIndex();
            // sum += result;
            sum += try pattern.findMirrorIndex();
            pattern_builder.clearRetainingCapacity();

            // std.debug.print("Pattern rows:\n", .{});
            // for (pattern.rows) |row| {
            //     std.debug.print("{s}\n", .{row.line});
            // }
            // std.debug.print("Mirror Index: {d}\n\n", .{result});
        }
    }

    return sum;
}

pub fn part2(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_lines = std.mem.splitSequence(u8, input, "\n");
    var sum: u64 = 0;

    var pattern_builder = std.ArrayList([]const u8).init(allocator);
    while (input_lines.next()) |line| {
        // std.debug.print("{s}\n", .{line});

        if (line.len > 0 and !std.mem.eql(u8, line, "\n")) {
            try pattern_builder.append(line);
        } else {
            const pattern = try Pattern.init(allocator, try pattern_builder.toOwnedSlice());
            // const result = try pattern.findMirrorIndex();
            // sum += result;
            sum += try pattern.findSmudgedMirrorIndex();
            pattern_builder.clearRetainingCapacity();

            // std.debug.print("Pattern rows:\n", .{});
            // for (pattern.rows) |row| {
            //     std.debug.print("{s}\n", .{row.line});
            // }
            // std.debug.print("Mirror Index: {d}\n\n", .{result});
        }
    }

    return sum;
}

test "part1" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const test_input =
        \\#.##..##.
        \\..#.##.#.
        \\##......#
        \\##......#
        \\..#.##.#.
        \\..##..##.
        \\#.#.##.#.
        \\
        \\#...##..#
        \\#....#..#
        \\..##..###
        \\#####.##.
        \\#####.##.
        \\..##..###
        \\#....#..#
        \\
    ;

    const expected_result = 405;
    const result = try part1(arena, test_input);
    try std.testing.expectEqual(expected_result, result);
}

test "part2" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const test_input =
        \\#.##..##.
        \\..#.##.#.
        \\##......#
        \\##......#
        \\..#.##.#.
        \\..##..##.
        \\#.#.##.#.
        \\
        \\#...##..#
        \\#....#..#
        \\..##..###
        \\#####.##.
        \\#####.##.
        \\..##..###
        \\#....#..#
        \\
    ;

    const expected_result = 400;
    const result = try part2(arena, test_input);
    try std.testing.expectEqual(expected_result, result);
}
