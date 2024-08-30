const std = @import("std");

pub fn part1(input_lines: *std.mem.TokenIterator(u8, .sequence)) !u64 {
    var sum: u64 = 0;

    while (input_lines.*.next()) |line| {
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

test "day1 part1" {
    const input =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;

    const result = try part1(input);
    try std.testing.expectEqual(@as(u64, 142), result);
}
