const std = @import("std");

pub fn part1(
    allocator: std.mem.Allocator,
    input: []u8,
) !u64 {
    _ = allocator;
    var input_sequences = std.mem.tokenizeSequence(u8, input, ",");

    var sum: u64 = 0;
    while (input_sequences.next()) |seq| {
        var hash: u64 = 0;
        for (seq) |char| hash = ((hash + char) * 17) % 256;
        // std.debug.print("{s} {d}\n", .{ seq, hash });
        sum += hash;
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

    const input = "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7";
    const mutable = try arena.alloc(u8, input.len);
    std.mem.copyForwards(u8, mutable, input);

    const expected_result = 1320;
    const result = try part1(arena, mutable);
    try std.testing.expectEqual(expected_result, result);
}

test "part2" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const input = "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7";
    const mutable = try arena.alloc(u8, input.len);
    std.mem.copyForwards(u8, mutable, input);

    const expected_result = 0;
    const result = try part2(arena, mutable);
    try std.testing.expectEqual(expected_result, result);
}
