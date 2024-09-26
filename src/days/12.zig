const std = @import("std");
const utils = @import("utils");

fn parseKeys(allocator: std.mem.Allocator, key_str: []const u8) ![]usize {
    var iter = std.mem.splitScalar(u8, key_str, ',');
    var num_arr = std.ArrayList(usize).init(allocator);

    while (iter.next()) |num_str| {
        try num_arr.append(try std.fmt.parseInt(usize, num_str, 10));
    }

    return try num_arr.toOwnedSlice();
}

fn getNumValidCases(map: []const u8, keys: []usize) u64 {
    if (map.len == 0) return if (keys.len == 0) 1 else 0;
    if (keys.len == 0) return if (std.mem.indexOfScalar(u8, map, '#') != null) 0 else 1;

    // keys not all used, not end of map:

    var cases: u64 = 0;

    if (map[0] == '.' or map[0] == '?') {
        cases += getNumValidCases(if (map.len < 2) &[0]u8{} else map[1..], keys);
    }

    if (map[0] == '#' or map[0] == '?') {
        if (keys[0] <= map.len and std.mem.indexOfScalar(u8, map[0..keys[0]], '.') == null and (keys[0] == map.len or map[keys[0]] != '#')) {
            cases += getNumValidCases(
                if (map.len < keys[0] + 1) &[0]u8{} else map[(keys[0] + 1)..],
                if (keys.len < 2) &[0]usize{} else keys[1..],
            );
        }
    }

    return cases;
}

pub fn part1(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    var sum: u64 = 0;
    while (input_lines.next()) |line| {
        var line_parts = std.mem.splitSequence(u8, line, " ");
        const map_str = line_parts.next().?;
        const key_str = line_parts.next().?;
        const keys = try parseKeys(allocator, key_str);

        sum += getNumValidCases(map_str, keys);
    }
    return sum;
}

pub fn part2(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    _ = allocator;
    var sum: u64 = 0;

    while (input_lines.next()) |line| {
        _ = line;
    }
    sum += 0;

    return sum;
}

test "line by line" {
    const line1_map = "???.### 1,1,3";
    const line1_expected_cases = 1;
    try utils.testPart(line1_map, part1, line1_expected_cases);

    const line2_map = ".??..??...?##. 1,1,3";
    const line2_expected_cases = 4;
    try utils.testPart(line2_map, part1, line2_expected_cases);

    const line3_map = "?#?#?#?#?#?#?#? 1,3,1,6";
    const line3_expected_cases = 1;
    try utils.testPart(line3_map, part1, line3_expected_cases);

    const line4_map = "????.#...#... 4,1,1";
    const line4_expected_cases = 1;
    try utils.testPart(line4_map, part1, line4_expected_cases);

    const line5_map = "????.######..#####. 1,6,5";
    const line5_expected_cases = 4;
    try utils.testPart(line5_map, part1, line5_expected_cases);

    const line6_map = "?###???????? 3,2,1";
    const line6_expected_cases = 10;
    try utils.testPart(line6_map, part1, line6_expected_cases);
}

test "part1" {
    const input =
        \\???.### 1,1,3
        \\.??..??...?##. 1,1,3
        \\?#?#?#?#?#?#?#? 1,3,1,6
        \\????.#...#... 4,1,1
        \\????.######..#####. 1,6,5
        \\?###???????? 3,2,1
    ;
    const expected_result = 21;
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
