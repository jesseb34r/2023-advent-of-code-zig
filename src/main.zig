const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {
    var arena_file = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_file.deinit();
    const arena = arena_file.allocator();

    const args = try utils.parseArgs(arena);

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("Running day {d} part {d} with input file: \"{s}\"", .{ args.day, args.part, args.input_filename });
}
