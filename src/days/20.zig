const std = @import("std");
const utils = @import("../utils.zig");

pub fn part1(input_lines: *std.mem.TokenIterator(u8, .sequence)) !u64 {
    var sum: u64 = 0;

    _ = input_lines;
    sum += 1;

    return sum;
}

pub fn part2(input_lines: *std.mem.TokenIterator(u8, .sequence)) !u64 {
    var sum: u64 = 0;

    _ = input_lines;
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
