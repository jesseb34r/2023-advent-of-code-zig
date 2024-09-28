const std = @import("std");
const utils = @import("utils");

pub fn part1(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    _ = allocator;
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    var sum: u64 = 0;

    while (input_lines.next()) |line| {
        var parsed_digits: [2]u8 = undefined;

        for (line) |c| {
            if (std.ascii.isDigit(c)) {
                parsed_digits[0] = c;
                break;
            }
        }

        for (0..line.len) |i| {
            const c = line[line.len - 1 - i];
            if (std.ascii.isDigit(c)) {
                parsed_digits[1] = c;
                break;
            }
        }

        sum += try std.fmt.parseInt(u64, &parsed_digits, 10);
    }

    return sum;
}

pub fn part2(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    _ = allocator;
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    var sum: u64 = 0;

    const digit_map = [_]struct { name: []const u8, value: u8 }{
        .{ .name = "one", .value = '1' },
        .{ .name = "two", .value = '2' },
        .{ .name = "three", .value = '3' },
        .{ .name = "four", .value = '4' },
        .{ .name = "five", .value = '5' },
        .{ .name = "six", .value = '6' },
        .{ .name = "seven", .value = '7' },
        .{ .name = "eight", .value = '8' },
        .{ .name = "nine", .value = '9' },
    };

    const check_for_spelled_digit = struct {
        fn f(slice: []const u8) ?u8 {
            for (digit_map) |entry| {
                if (std.mem.startsWith(u8, slice, entry.name)) {
                    return entry.value;
                }
            }
            return null;
        }
    }.f;

    while (input_lines.next()) |line| {
        var parsed_digits: [2]u8 = undefined;

        for (0..line.len) |i| {
            if (std.ascii.isDigit(line[i])) {
                parsed_digits[0] = line[i];
                break;
            }
            if (check_for_spelled_digit(line[i..])) |c| {
                parsed_digits[0] = c;
                break;
            }
        }

        for (0..line.len) |i| {
            const reverse_index = line.len - 1 - i;
            if (std.ascii.isDigit(line[reverse_index])) {
                parsed_digits[1] = line[reverse_index];
                break;
            }
            if (check_for_spelled_digit(line[reverse_index..])) |d| {
                parsed_digits[1] = d;
                break;
            }
        }

        sum += (parsed_digits[0] - '0') * 10 + (parsed_digits[1] - '0');
    }

    return sum;
}

test "part1" {
    const input =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;

    try utils.testPart(input, part1, 142);
}

test "part2" {
    const input =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;

    try utils.testPart(input, part2, 281);
}
