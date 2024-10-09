const std = @import("std");

const day1 = @import("days/01_trebuchet.zig");
const day2 = @import("days/02_cube_conundrum.zig");
const day3 = @import("days/03_gear_ratios.zig");
const day4 = @import("days/04_scratchcards.zig");
const day5 = @import("days/05_if_you_give_a_seed_a_fertilizer.zig");
const day6 = @import("days/06_wait_for_it.zig");
const day7 = @import("days/07_camel_cards.zig");
const day8 = @import("days/08_haunted_wasteland.zig");
const day9 = @import("days/09_mirage_maintenance.zig");
const day10 = @import("days/10_pipe_maze.zig");
const day11 = @import("days/11_cosmic_expansion.zig");
const day12 = @import("days/12_hot_springs.zig");
const day13 = @import("days/13_point_of_incidence.zig");
const day14 = @import("days/14_parabolic_reflector_dish.zig");
const day15 = @import("days/15_lens_library.zig");
const day16 = @import("days/16_the_floor_will_be_lava.zig");
const day17 = @import("days/17_clumsy_crucible.zig");
const day18 = @import("days/18_lavaduct_lagoon.zig");
const day19 = @import("days/19_aplenty.zig");
const day20 = @import("days/20_pulse_propagation.zig");
const day21 = @import("days/21_step_counter.zig");
const day22 = @import("days/22_sand_slabs.zig");
const day23 = @import("days/23_a_long_walk.zig");
const day24 = @import("days/24_never_tell_me_the_odds.zig");
const day25 = @import("days/25_snowverload.zig");

const Day = struct {
    day_number: usize,
    part1: fn (std.mem.Allocator, comptime []const u8) anyerror!u64,
    part2: fn (std.mem.Allocator, comptime []const u8) anyerror!u64,
};

const DAYS = [_]Day{
    Day{ .day_number = 1, .part1 = day1.part1, .part2 = day1.part2 },
    Day{ .day_number = 2, .part1 = day2.part1, .part2 = day2.part2 },
    Day{ .day_number = 3, .part1 = day3.part1, .part2 = day3.part2 },
    Day{ .day_number = 4, .part1 = day4.part1, .part2 = day4.part2 },
    Day{ .day_number = 5, .part1 = day5.part1, .part2 = day5.part2 },
    Day{ .day_number = 6, .part1 = day6.part1, .part2 = day6.part2 },
    Day{ .day_number = 7, .part1 = day7.part1, .part2 = day7.part2 },
    Day{ .day_number = 8, .part1 = day8.part1, .part2 = day8.part2 },
    Day{ .day_number = 9, .part1 = day9.part1, .part2 = day9.part2 },
    Day{ .day_number = 10, .part1 = day10.part1, .part2 = day10.part2 },
    Day{ .day_number = 11, .part1 = day11.part1, .part2 = day11.part2 },
    Day{ .day_number = 12, .part1 = day12.part1, .part2 = day12.part2 },
    Day{ .day_number = 13, .part1 = day13.part1, .part2 = day13.part2 },
    Day{ .day_number = 14, .part1 = day14.part1, .part2 = day14.part2 },
    Day{ .day_number = 15, .part1 = day15.part1, .part2 = day15.part2 },
    Day{ .day_number = 16, .part1 = day16.part1, .part2 = day16.part2 },
    Day{ .day_number = 17, .part1 = day17.part1, .part2 = day17.part2 },
    // Day{ .day_number = 18, .part1 = day18.part1, .part2 = day18.part2 },
    // Day{ .day_number = 19, .part1 = day19.part1, .part2 = day19.part2 },
    // Day{ .day_number = 20, .part1 = day20.part1, .part2 = day20.part2 },
    // Day{ .day_number = 21, .part1 = day21.part1, .part2 = day21.part2 },
    // Day{ .day_number = 22, .part1 = day22.part1, .part2 = day22.part2 },
    // Day{ .day_number = 23, .part1 = day23.part1, .part2 = day23.part2 },
    // Day{ .day_number = 24, .part1 = day24.part1, .part2 = day24.part2 },
    // Day{ .day_number = 25, .part1 = day25.part1, .part2 = day25.part2 },
};

const INPUTS = [_][]const u8{
    @embedFile("./inputs/01.txt"),
    @embedFile("./inputs/02.txt"),
    @embedFile("./inputs/03.txt"),
    @embedFile("./inputs/04.txt"),
    @embedFile("./inputs/05.txt"),
    @embedFile("./inputs/06.txt"),
    @embedFile("./inputs/07.txt"),
    @embedFile("./inputs/08.txt"),
    @embedFile("./inputs/09.txt"),
    @embedFile("./inputs/10.txt"),
    @embedFile("./inputs/11.txt"),
    @embedFile("./inputs/12.txt"),
    @embedFile("./inputs/13.txt"),
    @embedFile("./inputs/14.txt"),
    @embedFile("./inputs/15.txt"),
    @embedFile("./inputs/16.txt"),
    @embedFile("./inputs/17.txt"),
    // @embedFile("./inputs/18.txt"),
    // @embedFile("./inputs/19.txt"),
    // @embedFile("./inputs/20.txt"),
    // @embedFile("./inputs/21.txt"),
    // @embedFile("./inputs/22.txt"),
    // @embedFile("./inputs/23.txt"),
    // @embedFile("./inputs/24.txt"),
    // @embedFile("./inputs/25.txt"),
};

// TODO add a way to test and/or run all days
/// To run a specific day run `cmd <day> <part>`
pub fn main() !void {
    var buffer: [1 << 20]u8 = undefined; // 1 MB buffer
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var arena = std.heap.ArenaAllocator.init(fba.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try parseArgs(allocator);

    inline for (DAYS) |day| {
        if (day.day_number == args.day) {
            if (args.part == 1) {
                std.debug.print(
                    "Day {d} Part 1:\n{d}\n",
                    .{ day.day_number, try day.part1(allocator, INPUTS[day.day_number - 1]) },
                );
                return;
            } else if (args.part == 2) {
                std.debug.print(
                    "Day {d} Part 2:\n{d}\n",
                    .{ day.day_number, try day.part2(allocator, INPUTS[day.day_number - 1]) },
                );
                return;
            }
        }
    }

    std.debug.print("Day {d} Part {d} not found\n", .{ args.day, args.part });
    std.process.exit(2);
}

const Args = struct {
    /// must be 1 through 25
    day: usize,

    /// must be 1 or 2
    part: usize,
};

fn parseArgs(allocator: std.mem.Allocator) !Args {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 3) {
        std.debug.print("Usage: {s} <day> <part>\n", .{args[0]});
        return error.InvalidArguments;
    }

    const day = try std.fmt.parseInt(u8, args[1], 10);
    const part = try std.fmt.parseInt(u8, args[2], 10);

    if (day < 1 or day > 25) {
        std.debug.print("Invalid day {d}. Day must be 1-25\n", .{day});
        return error.InvalidArguments;
    }

    if (part != 1 and part != 2) {
        std.debug.print("Invalid part {d}. Part must be 1 or 2\n", .{part});
        return error.InvalidArguments;
    }

    return Args{
        .day = day,
        .part = part,
    };
}

test {
    std.testing.refAllDecls(@This());
}
