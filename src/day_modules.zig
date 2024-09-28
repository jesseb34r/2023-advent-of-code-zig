const std = @import("std");
const day1 = @import("days/1.zig");
const day2 = @import("days/2.zig");
const day3 = @import("days/3.zig");
const day4 = @import("days/4.zig");
const day5 = @import("days/5.zig");
const day6 = @import("days/6.zig");
const day7 = @import("days/7.zig");
const day8 = @import("days/8.zig");
const day9 = @import("days/9.zig");
const day10 = @import("days/10.zig");
const day11 = @import("days/11.zig");
const day12 = @import("days/12.zig");
const day13 = @import("days/13.zig");
const day14 = @import("days/14.zig");
const day15 = @import("days/15.zig");
const day16 = @import("days/16.zig");
const day17 = @import("days/17.zig");
const day18 = @import("days/18.zig");
const day19 = @import("days/19.zig");
const day20 = @import("days/20.zig");
const day21 = @import("days/21.zig");
const day22 = @import("days/22.zig");
const day23 = @import("days/23.zig");
const day24 = @import("days/24.zig");
const day25 = @import("days/25.zig");

const DayModules = struct {
    @"1": day1,
    @"2": day2,
    @"3": day3,
    @"4": day4,
    @"5": day5,
    @"6": day6,
    @"7": day7,
    @"8": day8,
    @"9": day9,
    @"10": day10,
    @"11": day11,
    @"12": day12,
    @"13": day13,
    @"14": day14,
    @"15": day15,
    @"16": day16,
    @"17": day17,
    @"18": day18,
    @"19": day19,
    @"20": day20,
    @"21": day21,
    @"22": day22,
    @"23": day23,
    @"24": day24,
    @"25": day25,
};

pub fn runDay(allocator: std.mem.Allocator, day: u8, part: u8, input: []u8) !u64 {
    return switch (day) {
        1 => runPart(allocator, day1, part, input),
        2 => runPart(allocator, day2, part, input),
        3 => runPart(allocator, day3, part, input),
        4 => runPart(allocator, day4, part, input),
        5 => runPart(allocator, day5, part, input),
        6 => runPart(allocator, day6, part, input),
        7 => runPart(allocator, day7, part, input),
        8 => runPart(allocator, day8, part, input),
        9 => runPart(allocator, day9, part, input),
        10 => runPart(allocator, day10, part, input),
        11 => runPart(allocator, day11, part, input),
        12 => runPart(allocator, day12, part, input),
        13 => runPart(allocator, day13, part, input),
        14 => runPart(allocator, day14, part, input),
        15 => runPart(allocator, day15, part, input),
        16 => runPart(allocator, day16, part, input),
        17 => runPart(allocator, day17, part, input),
        18 => runPart(allocator, day18, part, input),
        19 => runPart(allocator, day19, part, input),
        20 => runPart(allocator, day20, part, input),
        21 => runPart(allocator, day21, part, input),
        22 => runPart(allocator, day22, part, input),
        23 => runPart(allocator, day23, part, input),
        24 => runPart(allocator, day24, part, input),
        25 => runPart(allocator, day25, part, input),
        else => {
            std.debug.print("Invalid day number. Must be between 1 and 25.\n", .{});
            return error.InvalidDay;
        },
    };
}

fn runPart(allocator: std.mem.Allocator, day_module: anytype, part: u8, input: []u8) !u64 {
    return switch (part) {
        1 => try day_module.part1(allocator, input),
        2 => try day_module.part2(allocator, input),
        else => {
            std.debug.print("Invalid part number. Must be 1 or 2.\n", .{});
            return error.InvalidPart;
        },
    };
}
