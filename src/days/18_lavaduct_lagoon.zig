const std = @import("std");
const utils = @import("utils");

const Position = struct {
    row: isize,
    col: isize,
};

const Tile = struct {
    val: u8,
    color: [6]u8 = .{ 'F', 'F', 'F', 'F', 'F', 'F' },
};

const Grid = struct {
    allocator: std.mem.Allocator,
    grid: std.ArrayList(std.ArrayList(Tile)),
    current_pos: Position,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        var grid = std.ArrayList(std.ArrayList(Tile)).init(allocator);
        var initial_row = std.ArrayList(Tile).init(allocator);
        try initial_row.append(Tile{ .val = '@' });
        try grid.append(initial_row);

        return Self{
            .allocator = allocator,
            .grid = grid,
            .current_pos = Position{ .row = 0, .col = 0 },
        };
    }

    pub fn draw(self: *Self, inst: Instruction) !void {
        switch (inst.dir) {
            .up => {
                for (0..inst.len) |_| {
                    if (self.current_pos.row == 0) {
                        var new_row = std.ArrayList(Tile).init(self.allocator);
                        try new_row.appendNTimes(Tile{ .val = '.' }, self.grid.items[0].items.len);
                        try self.grid.insert(0, new_row);
                    } else {
                        self.current_pos.row -= 1;
                    }
                    self.grid.items[self.current_pos.row].items[self.current_pos.col] = Tile{
                        .val = '#',
                        .color = inst.color,
                    };
                }
            },
            .down => {
                for (0..inst.len) |_| {
                    if (self.current_pos.row == self.grid.items.len - 1) {
                        var new_row = std.ArrayList(Tile).init(self.allocator);
                        try new_row.appendNTimes(Tile{ .val = '.' }, self.grid.items[0].items.len);
                        try self.grid.append(new_row);
                    }
                    self.current_pos.row += 1;
                    self.grid.items[self.current_pos.row].items[self.current_pos.col] = Tile{
                        .val = '#',
                        .color = inst.color,
                    };
                }
            },
            .left => {
                for (0..inst.len) |_| {
                    if (self.current_pos.col == 0) {
                        for (self.grid.items) |*row| try row.insert(0, Tile{ .val = '.' });
                    } else {
                        self.current_pos.col -= 1;
                    }
                    self.grid.items[self.current_pos.row].items[self.current_pos.col] = Tile{
                        .val = '#',
                        .color = inst.color,
                    };
                }
            },
            .right => {
                for (0..inst.len) |_| {
                    if (self.current_pos.col == self.grid.items[0].items.len - 1) {
                        for (self.grid.items) |*row| try row.append(Tile{ .val = '.' });
                    }
                    self.current_pos.col += 1;
                    self.grid.items[self.current_pos.row].items[self.current_pos.col] = Tile{
                        .val = '#',
                        .color = inst.color,
                    };
                }
            },
        }
    }
};

const Direction = enum { up, down, left, right };

const Instruction = struct {
    dir: Direction,
    len: isize,
    color: [6]u8,

    const Self = @This();

    /// line should be in the format of `dir len (#color)` e.g. `R 6 (#70c710)`
    pub fn parse(line: []const u8) !Self {
        var line_parts = std.mem.splitScalar(u8, line, ' ');
        const dir_part = line_parts.next().?[0];
        const len_part = line_parts.next().?;
        const color_part = line_parts.next().?;

        const dir: Direction = switch (dir_part) {
            'U' => .up,
            'D' => .down,
            'L' => .left,
            'R' => .right,
            else => return error.InvalidDirection,
        };

        const len: isize = try std.fmt.parseInt(isize, len_part, 10);

        var color: [6]u8 = undefined;
        std.mem.copyForwards(u8, &color, color_part[2..8]);

        return Self{
            .dir = dir,
            .len = len,
            .color = color,
        };
    }
};

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");

    // var grid = try Grid.init(allocator);
    var perimeter: u64 = 0;
    var vertices = std.ArrayList(Position).init(allocator);
    var current_vertex = Position{ .row = 0, .col = 0 };
    try vertices.append(current_vertex);

    while (input_lines.next()) |line| {
        const inst = try Instruction.parse(line);
        switch (inst.dir) {
            .up => current_vertex.row -= inst.len,
            .down => current_vertex.row += inst.len,
            .left => current_vertex.col -= inst.len,
            .right => current_vertex.col += inst.len,
        }

        try vertices.append(current_vertex);

        perimeter += @abs(inst.len);

        // try grid.execute(inst);
    }

    // Shoelace formula https://ibmathsresources.com/2019/10/07/the-shoelace-algorithm-to-find-areas-of-polygons/
    var sum: isize = 0;
    for (1..vertices.items.len) |i| {
        sum += vertices.items[i - 1].col * vertices.items[i].row;
        sum -= vertices.items[i].col * vertices.items[i - 1].row;
    }
    const lake_size = (@abs(sum) / 2) + perimeter / 2 + 1;
    return lake_size;

    // var buf_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
    // var writer = buf_writer.writer();

    // for (grid.grid.items) |row| {
    //     for (row.items) |tile| {
    //         try writer.print("\x1b[38;2;{};{};{}m{c}\x1b[0m", .{
    //             std.fmt.parseInt(u8, tile.color[0..2], 16) catch 0,
    //             std.fmt.parseInt(u8, tile.color[2..4], 16) catch 0,
    //             std.fmt.parseInt(u8, tile.color[4..6], 16) catch 0,
    //             tile.val,
    //         });
    //     }
    //     try writer.writeByte('\n');
    // }

    // try buf_writer.flush();
}

pub fn part2(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");

    var perimeter: u64 = 0;
    var vertices = std.ArrayList(Position).init(allocator);
    var current_vertex = Position{ .row = 0, .col = 0 };
    try vertices.append(current_vertex);

    while (input_lines.next()) |line| {
        const inst = try Instruction.parse(line);
        const len = try std.fmt.parseInt(i64, inst.color[0..5], 16);
        const dir_code = try std.fmt.parseInt(u8, inst.color[5..6], 10);
        switch (dir_code) {
            3 => current_vertex.row -= len,
            1 => current_vertex.row += len,
            2 => current_vertex.col -= len,
            0 => current_vertex.col += len,
            else => unreachable,
        }

        try vertices.append(current_vertex);

        perimeter += @abs(len);
    }

    var sum: isize = 0;
    for (1..vertices.items.len) |i| {
        sum += vertices.items[i - 1].col * vertices.items[i].row;
        sum -= vertices.items[i].col * vertices.items[i - 1].row;
    }
    const lake_size = (@abs(sum) / 2) + perimeter / 2 + 1;
    return lake_size;
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // R = 6+2+2 = 10
    // L = 2+5+1+2 = 10
    // D = 5+2+2 = 9
    // U = 2+2+3+2 = 9
    const test_input =
        \\R 6 (#70c710)
        \\D 5 (#0dc571)
        \\L 2 (#5713f0)
        \\D 2 (#d2c081)
        \\R 2 (#59c680)
        \\D 2 (#411b91)
        \\L 5 (#8ceee2)
        \\U 2 (#caa173)
        \\L 1 (#1b58a2)
        \\U 2 (#caa171)
        \\R 2 (#7807d2)
        \\U 3 (#a77fa3)
        \\L 2 (#015232)
        \\U 2 (#7a21e3)
    ;

    const expected_result = 62;
    const result = try part1(allocator, test_input);

    try std.testing.expectEqual(expected_result, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_input =
        \\R 6 (#70c710)
        \\D 5 (#0dc571)
        \\L 2 (#5713f0)
        \\D 2 (#d2c081)
        \\R 2 (#59c680)
        \\D 2 (#411b91)
        \\L 5 (#8ceee2)
        \\U 2 (#caa173)
        \\L 1 (#1b58a2)
        \\U 2 (#caa171)
        \\R 2 (#7807d2)
        \\U 3 (#a77fa3)
        \\L 2 (#015232)
        \\U 2 (#7a21e3)
    ;

    const expected_result = 952408144115;
    const result = try part2(allocator, test_input);

    try std.testing.expectEqual(expected_result, result);
}
