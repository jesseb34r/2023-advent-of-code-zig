const std = @import("std");
const utils = @import("utils");

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

    pub fn findMirrorIndex(self: *const Self) !u64 {
        for (1..self.rows.len) |row_index| {
            if (try self.rows[row_index].eql(self.rows[row_index - 1])) return row_index;
        }

        for (1..self.columns.len) |col_index| {
            if (try self.columns[col_index].eql(self.columns[col_index - 1])) return col_index * 100;
        }

        return error.noMirrorFound;
    }
};

pub fn part1(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    var sum: u64 = 0;

    var pattern_builder = std.ArrayList([]const u8).init(allocator);
    while (input_lines.next()) |line| {
        std.debug.print("{s}\n", .{line});
        if (line.len > 0 and !std.mem.eql(u8, line, "\n")) {
            try pattern_builder.append(line);
        } else {
            const pattern = try Pattern.init(allocator, try pattern_builder.toOwnedSlice());
            sum += try pattern.findMirrorIndex();
            pattern_builder.clearRetainingCapacity();
            std.debug.print("Pattern rows:\n", .{});
            for (pattern.rows) |row| {
                std.debug.print("{s}\n", .{row.line});
            }
        }
    }

    return sum;
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
    const input =
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
    ;
    const expected_result = 405;
    try utils.testPart(input, part1, expected_result);
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
