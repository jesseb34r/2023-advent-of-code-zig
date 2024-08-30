const std = @import("std");

pub const Args = struct {
    input_filename: []const u8,
    day: u8,
    part: u8,
};

pub fn parseArgs(arena: std.mem.Allocator) !Args {
    const args = try std.process.argsAlloc(arena);
    defer std.process.argsFree(arena, args);

    if (args.len != 4) {
        std.debug.print("Usage: {s} <input_filename> <day> <part>\n", .{args[0]});
        return error.InvalidArguments;
    }

    const input_filename = try arena.dupe(u8, args[1]);
    const day = try std.fmt.parseInt(u8, args[2], 10);
    const part = try std.fmt.parseInt(u8, args[3], 10);

    return Args{
        .input_filename = input_filename,
        .day = day,
        .part = part,
    };
}
