const std = @import("std");
const utils = @import("utils");

pub fn part1(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    var sum: i64 = 0;

    while (input_lines.next()) |line| {
        var value_iter = std.mem.tokenizeSequence(u8, line, " ");

        var value_arrays = std.ArrayList(std.ArrayList(i64)).init(allocator);

        try value_arrays.append(std.ArrayList(i64).init(allocator));
        while (value_iter.next()) |value| {
            try value_arrays.items[0].append(try std.fmt.parseInt(i64, value, 10));
        }
        value_iter.reset();

        var current_array: usize = 0;
        while (true) : (current_array += 1) {
            var i: usize = 0;
            try value_arrays.append(std.ArrayList(i64).init(allocator));
            while (i < value_arrays.items[current_array].items.len - 1) : (i += 1) {
                try value_arrays.items[current_array + 1].append(value_arrays.items[current_array].items[i + 1] - value_arrays.items[current_array].items[i]);
            }

            const all_zeros = for (value_arrays.items[current_array + 1].items) |value| {
                if (value != 0) break false;
            } else true;

            if (all_zeros) {
                try value_arrays.items[current_array + 1].append(0);
                current_array += 1;
                while (current_array > 0) : (current_array -= 1) {
                    try value_arrays.items[current_array - 1].append(value_arrays.items[current_array - 1].getLast() + value_arrays.items[current_array].getLast());
                }
                sum += value_arrays.items[0].getLast();
                break;
            }
        }

        // for (value_arrays.items, 0..) |array, index| {
        //     // Print leading spaces for triangular shape
        //     for (0..index) |_| {
        //         std.debug.print("  ", .{});
        //     }
        //     // Print the array contents
        //     for (array.items) |value| {
        //         std.debug.print("{d:4} ", .{@abs(value)});
        //     }
        //     std.debug.print("\n", .{});
        // }
        // std.debug.print("\n", .{});
    }

    return @abs(sum);
}

pub fn part2(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    var sum: i64 = 0;

    while (input_lines.next()) |line| {
        var value_iter = std.mem.tokenizeSequence(u8, line, " ");

        var value_arrays = std.ArrayList(std.ArrayList(i64)).init(allocator);

        try value_arrays.append(std.ArrayList(i64).init(allocator));
        while (value_iter.next()) |value| {
            try value_arrays.items[0].append(try std.fmt.parseInt(i64, value, 10));
        }
        value_iter.reset();

        var current_array: usize = 0;
        while (true) : (current_array += 1) {
            var i: usize = 0;
            try value_arrays.append(std.ArrayList(i64).init(allocator));
            while (i < value_arrays.items[current_array].items.len - 1) : (i += 1) {
                try value_arrays.items[current_array + 1].append(value_arrays.items[current_array].items[i + 1] - value_arrays.items[current_array].items[i]);
            }

            const all_zeros = for (value_arrays.items[current_array + 1].items) |value| {
                if (value != 0) break false;
            } else true;

            if (all_zeros) {
                try value_arrays.items[current_array + 1].insert(0, 0);
                current_array += 1;
                while (current_array > 0) : (current_array -= 1) {
                    try value_arrays.items[current_array - 1].insert(0, value_arrays.items[current_array - 1].items[0] - value_arrays.items[current_array].items[0]);
                }
                sum += value_arrays.items[0].items[0];
                break;
            }
        }

        // for (value_arrays.items, 0..) |array, index| {
        //     // Print leading spaces for triangular shape
        //     for (0..index) |_| {
        //         std.debug.print("  ", .{});
        //     }
        //     // Print the array contents
        //     for (array.items) |value| {
        //         std.debug.print("{d:4} ", .{@abs(value)});
        //     }
        //     std.debug.print("\n", .{});
        // }
        // std.debug.print("\n", .{});
    }

    return @abs(sum);
}

test "part1" {
    const input =
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
    ;
    const expected_result = 114;
    try utils.testPart(input, part1, expected_result);
}

test "part2" {
    const input =
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
    ;
    const expected_result = 2;
    try utils.testPart(input, part2, expected_result);
}
