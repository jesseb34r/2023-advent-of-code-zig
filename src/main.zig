const std = @import("std");
const utils = @import("utils.zig");
const day1 = @import("days/day1.zig");

pub fn main() !void {
    var arena_file = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_file.deinit();
    const arena = arena_file.allocator();

    const args = try utils.parseArgs(arena);

    const input = try std.fs.cwd().readFileAlloc(arena, args.input_filename, 1024 * 1024);
    const output = try day1.part1(input);

    std.debug.print("Output: {d}", .{output});
}
