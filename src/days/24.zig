const std = @import("std");
const utils = @import("utils");

pub fn part1(allocator: std.mem.Allocator, input_lines: *std.mem.TokenIterator(u8, .sequence)) !u64 {
    _ = allocator;
    var sum: u64 = 0;

    while (input_lines.next()) |line| {
        _ = line;
    }
    sum += 0;

    return sum;
}

pub fn part2(allocator: std.mem.Allocator, input_lines: *std.mem.TokenIterator(u8, .sequence)) !u64 {
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
