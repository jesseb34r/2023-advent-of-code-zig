const std = @import("std");
const utils = @import("utils");

fn quadraticFormula(a: f64, b: f64, c: f64) struct { x1: f64, x2: f64 } {
    const discriminant = b * b - 4 * a * c;
    const x1 = (-b + @sqrt(discriminant)) / (2 * a);
    const x2 = (-b - @sqrt(discriminant)) / (2 * a);
    return .{ .x1 = x1, .x2 = x2 };
}

const Race = struct {
    time: u64,
    distance: u64,

    const Self = @This();

    pub fn findWaitTime(total_time: u64, distance: u64) f64 {
        const a: f64 = 1;
        const b: f64 = -@as(f64, @floatFromInt(total_time));
        const c: f64 = @as(f64, @floatFromInt(distance));

        const discriminant = b * b - 4 * a * c;

        // roots will always both be real. This is the smaller root
        const r2 = (-b - std.math.sqrt(discriminant)) / (2 * a);
        return r2;
    }

    pub fn getNumWinningSolutions(self: *const Self) u64 {
        const time_held_to_beat = findWaitTime(self.time, self.distance);
        // holding more wins until the other side of the curve. So subtract both sides
        const min_losing_time = @as(u64, @intFromFloat(@floor(time_held_to_beat)));
        const losing_solutions = (min_losing_time) * 2 + 1; // add 1 for 0 solution
        const winning_solutions = self.time - losing_solutions;
        return winning_solutions;
    }
};

pub fn part1(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    const race_times_str = input_lines.next().?;
    var race_times_itr = std.mem.tokenizeSequence(u8, race_times_str, " ");
    _ = race_times_itr.next();

    const distances_str = input_lines.next().?;
    var distances_itr = std.mem.tokenizeSequence(u8, distances_str, " ");
    _ = distances_itr.next();

    var races = std.ArrayList(Race).init(allocator);

    while (race_times_itr.next()) |time_str| {
        const time = try std.fmt.parseInt(u64, time_str, 10);
        const distance = try std.fmt.parseInt(u64, distances_itr.next().?, 10);

        try races.append(Race{ .time = time, .distance = distance });
    }

    var product: u64 = 1;

    for (races.items) |race| {
        product *= race.getNumWinningSolutions();
    }

    return product;
}

pub fn part2(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    const race_time_part = std.mem.trimLeft(u8, input_lines.next().?, "Time:");
    const race_time_str = try std.mem.replaceOwned(u8, allocator, race_time_part, " ", "");
    const race_time = try std.fmt.parseInt(u64, race_time_str, 10);

    const distance_part = std.mem.trimLeft(u8, input_lines.next().?, "Distance:");
    const distance_str = try std.mem.replaceOwned(u8, allocator, distance_part, " ", "");
    const distance = try std.fmt.parseInt(u64, distance_str, 10);

    const race = Race{ .time = race_time, .distance = distance };
    return race.getNumWinningSolutions();
}

test "part1" {
    const input =
        \\Time:      7  15   30
        \\Distance:  9  40  200
    ;
    const expected_result = 288;
    try utils.testPart(input, part1, expected_result);
}

test "part2" {
    const input =
        \\Time:      7  15   30
        \\Distance:  9  40  200
    ;
    const expected_result = 71503;
    try utils.testPart(input, part2, expected_result);
}
