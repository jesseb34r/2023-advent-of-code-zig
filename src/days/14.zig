const std = @import("std");
const utils = @import("utils");

fn firstIndexOf(arr: []u8, char: u8) ?usize {
    for (arr, 0..) |item, i| if (item == char) return i;
    return null;
}

pub fn part1(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");

    var cols_arr = std.ArrayList([]u8).init(allocator);
    for (0..input_lines.peek().?.len) |col_index| {
        var col_builder = std.ArrayList(u8).init(allocator);

        while (input_lines.next()) |line| {
            try col_builder.append(line[col_index]);
        }
        try cols_arr.append(try col_builder.toOwnedSlice());

        input_lines.reset();
    }

    // std.debug.print("Columns before tilting north:\n", .{});
    // for (cols_arr.items) |col| {
    //     std.debug.print("{s}\n", .{col});
    // }

    // tilt board north, moving all 'O's as far north as possible
    columns: for (0..cols_arr.items.len) |col_index| {
        var farthest_open_index = firstIndexOf(cols_arr.items[col_index], '.');

        positions: for (0..cols_arr.items[col_index].len) |pos_index| {
            // std.debug.print(
            //     "Pos index: {d}, Farthest open index: {?d}\n",
            //     .{ pos_index, farthest_open_index },
            // );
            if (farthest_open_index == null) continue :columns;
            if (pos_index <= farthest_open_index.?) continue :positions;

            switch (cols_arr.items[col_index][pos_index]) {
                'O' => {
                    cols_arr.items[col_index][farthest_open_index.?] = 'O';
                    cols_arr.items[col_index][pos_index] = '.';
                    const next_open_index = firstIndexOf(
                        cols_arr.items[col_index][(farthest_open_index.? + 1)..],
                        '.',
                    );
                    farthest_open_index = if (next_open_index == null) null else next_open_index.? + farthest_open_index.? + 1;
                },
                '#' => {
                    const next_open_index = firstIndexOf(
                        cols_arr.items[col_index][(pos_index + 1)..],
                        '.',
                    );
                    farthest_open_index = if (next_open_index == null) null else next_open_index.? + pos_index + 1;
                },
                '.' => continue :positions,
                else => return error.InvalidCharacter,
            }
        }
    }

    // std.debug.print("Columns after tilting north:\n", .{});
    // for (cols_arr.items) |col| {
    //     std.debug.print("{s}\n", .{col});
    // }

    var sum: u64 = 0;
    for (cols_arr.items) |col| {
        for (col, 0..) |pos, i| {
            if (pos == 'O') sum += col.len - i;
        }
    }

    return sum;
}

pub fn part2(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    _ = allocator;
    var sum: u64 = 0;

    while (input_lines.next()) |line| {
        _ = line;
    }
    sum += 0;

    return sum;
}

test "part1" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const input =
        \\O....#....
        \\O.OO#....#
        \\.....##...
        \\OO.#O....O
        \\.O.....O#.
        \\O.#..O.#.#
        \\..O..#O..O
        \\.......O..
        \\#....###..
        \\#OO..#....
    ;

    const mutable = try arena.alloc(u8, input.len);
    std.mem.copyForwards(u8, mutable, input);

    const expected_result = 136;
    const result = try part1(arena, mutable);
    try std.testing.expectEqual(expected_result, result);
}

test "part2" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const input =
        \\O....#....
        \\O.OO#....#
        \\.....##...
        \\OO.#O....O
        \\.O.....O#.
        \\O.#..O.#.#
        \\..O..#O..O
        \\.......O..
        \\#....###..
        \\#OO..#....
    ;
    const mutable = try arena.alloc(u8, input.len);
    std.mem.copyForwards(u8, mutable, input);

    const expected_result = 0;
    const result = try part2(arena, mutable);
    try std.testing.expectEqual(expected_result, result);
}
