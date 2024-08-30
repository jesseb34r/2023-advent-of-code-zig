const std = @import("std");
pub const utils = @import("utils");
const day_modules = @import("day_modules.zig");

pub fn main() !void {
    var arena_file = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_file.deinit();
    const arena = arena_file.allocator();

    const args = try utils.parseArgs(arena);

    const input = try std.fs.cwd().readFileAlloc(arena, args.input_filename, 1024 * 1024);
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    const output = try day_modules.runDay(arena, args.day, args.part, &input_lines);

    std.debug.print("Output: {d}", .{output});
}

test {
    std.testing.refAllDecls(@This());
}
