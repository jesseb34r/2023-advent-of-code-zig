const std = @import("std");

pub const Args = struct {
    input_filename: []const u8,
    day: u8,
    part: u8,
};

pub fn parseArgs(allocator: std.mem.Allocator) !Args {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 4) {
        std.debug.print("Usage: {s} <day> <part> <input_filename>\n", .{args[0]});
        return error.InvalidArguments;
    }

    const day = try std.fmt.parseInt(u8, args[1], 10);
    const part = try std.fmt.parseInt(u8, args[2], 10);
    const input_filename = try allocator.dupe(u8, args[3]);

    return Args{
        .input_filename = input_filename,
        .day = day,
        .part = part,
    };
}

pub fn testPart(
    input: []const u8,
    part_fn: fn (
        allocator: std.mem.Allocator,
        input_lines: *std.mem.TokenIterator(u8, .sequence),
    ) anyerror!u64,
    expected_result: u64,
) !void {
    var arena_file = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_file.deinit();
    const arena = arena_file.allocator();

    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    const result = try part_fn(arena, &input_lines);
    try std.testing.expectEqual(expected_result, result);
}
