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

pub fn runDay(day: u8, part: u8, input_lines: *std.mem.TokenIterator(u8, .sequence)) !u64 {
    return switch (day) {
        1 => runPart(day1, part, input_lines),
        2 => runPart(day2, part, input_lines),
        3 => runPart(day3, part, input_lines),
        4 => runPart(day4, part, input_lines),
        5 => runPart(day5, part, input_lines),
        6 => runPart(day6, part, input_lines),
        7 => runPart(day7, part, input_lines),
        8 => runPart(day8, part, input_lines),
        9 => runPart(day9, part, input_lines),
        10 => runPart(day10, part, input_lines),
        11 => runPart(day11, part, input_lines),
        12 => runPart(day12, part, input_lines),
        13 => runPart(day13, part, input_lines),
        14 => runPart(day14, part, input_lines),
        15 => runPart(day15, part, input_lines),
        16 => runPart(day16, part, input_lines),
        17 => runPart(day17, part, input_lines),
        18 => runPart(day18, part, input_lines),
        19 => runPart(day19, part, input_lines),
        20 => runPart(day20, part, input_lines),
        21 => runPart(day21, part, input_lines),
        22 => runPart(day22, part, input_lines),
        23 => runPart(day23, part, input_lines),
        24 => runPart(day24, part, input_lines),
        25 => runPart(day25, part, input_lines),
        else => {
            std.debug.print("Invalid day number. Must be between 1 and 25.\n", .{});
            return error.InvalidDay;
        },
    };
}

fn runPart(day_module: anytype, part: u8, input_lines: *std.mem.TokenIterator(u8, .sequence)) !u64 {
    return switch (part) {
        1 => try day_module.part1(input_lines),
        2 => try day_module.part2(input_lines),
        else => {
            std.debug.print("Invalid part number. Must be 1 or 2.\n", .{});
            return error.InvalidPart;
        },
    };
}
