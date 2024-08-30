const std = @import("std");
const utils = @import("../utils.zig");

pub fn part1(arena: std.mem.Allocator, input_lines: *std.mem.TokenIterator(u8, .sequence)) !u64 {
    var sum: u64 = 0;

    const Set = struct {
        red: u32 = 0,
        green: u32 = 0,
        blue: u32 = 0,
    };

    const Game = struct {
        id: u32,
        sets: []Set,

        pub fn parseGame(line: []const u8) !Game {
            var game_parts = std.mem.splitScalar([]const u8, line, ":");
            const id_part = try game_parts.next() orelse return error.InvalidInput;
            const sets_part = try game_parts.next() orelse return error.InvalidInput;

            const id = try std.fmt.parseInt(u32, id_part[5..], 10);

            const sets = std.ArrayList(Set).init();

            const sets_iter = std.mem.splitScalar([]const u8, sets_part, ";");
        }
    };

    while (input_lines.next()) |line| {}
    sum += 1;

    return sum;
}

pub fn part2(arena: std.mem.Allocator, input_lines: *std.mem.TokenIterator(u8, .sequence)) !u64 {
    _ = arena;
    var sum: u64 = 0;

    while (input_lines.next()) |line| {
        _ = line;
    }

    sum += 1;

    return sum;
}

test "part1" {
    const input =
        \\
        \\
        \\
        \\
    ;
    const expected_result = 0;
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
