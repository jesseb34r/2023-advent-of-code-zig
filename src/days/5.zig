const std = @import("std");
const utils = @import("utils");

const Range = struct {
    start: usize,
    length: usize,
};

const MapRange = struct {
    from_range_start: usize,
    to_range_start: usize,
    range_length: u64,
};

const Map = struct {
    ranges: []MapRange,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, lines: *std.mem.SplitIterator(u8, .sequence)) !Self {
        _ = lines.next(); // Skip the header line

        var ranges = std.ArrayList(MapRange).init(allocator);
        defer ranges.deinit();

        while (lines.next()) |line| {
            if (line.len == 0) break;
            var numbers = std.mem.splitSequence(u8, line, " ");
            const to_start = try std.fmt.parseInt(usize, numbers.next() orelse return error.InvalidInput, 10);
            const from_start = try std.fmt.parseInt(usize, numbers.next() orelse return error.InvalidInput, 10);
            const range_length = try std.fmt.parseInt(u64, numbers.next() orelse return error.InvalidInput, 10);

            try ranges.append(MapRange{
                .from_range_start = from_start,
                .to_range_start = to_start,
                .range_length = range_length,
            });
        }

        return Self{
            .ranges = try ranges.toOwnedSlice(),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.ranges);
    }

    pub fn mapRange(self: *const Self, input: Range) ![]Range {
        var from_ranges = std.ArrayList(Range).init(self.allocator);
        defer from_ranges.deinit();
        try from_ranges.append(input);

        var mapped = std.ArrayList(Range).init(self.allocator);
        defer mapped.deinit();

        for (self.ranges) |map_range| {
            for (from_ranges.items, 0..) |from, i| {
                const from_left = from.start;
                const from_right = from.start + from.length - 1;
                const map_from_left = map_range.from_range_start;
                const map_from_right = map_range.from_range_start + map_range.range_length - 1;
                const map_to_left = map_range.to_range_start;
                // cases:
                // (1) from.start < map_range.from_range_start
                //     (a) no overlap => continue
                //     (b) overlap no overflow => one unmapped, one mapped
                //     (c) overflow => one unmapped, one mapped, one unmapped
                // (2) from.start >= map_range.from_range_start
                //     (a) no overlap => continue
                //     (b) overlap => one mapped, one unmapped
                //     (c) fully overlap => one mapped
                if (from_left < map_from_left) {
                    if (from_right < map_from_left) {
                        continue;
                    } else {
                        from_ranges.items[i].length = map_from_left - from_left;
                        if (from_right <= map_from_right) {
                            try mapped.append(Range{
                                .start = map_to_left,
                                .length = from_right - map_from_left + 1,
                            });
                        } else {
                            try mapped.append(Range{
                                .start = map_to_left,
                                .length = map_range.range_length,
                            });
                            try from_ranges.append(Range{
                                .start = map_from_right + 1,
                                .length = from_right - map_from_right,
                            });
                        }
                    }
                } else {
                    if (from_left > map_from_right) {
                        continue;
                    } else {
                        if (from_right > map_from_right) {
                            from_ranges.items[i].start = map_from_right + 1;
                            from_ranges.items[i].length = from_right - map_from_right;
                            try mapped.append(Range{
                                .start = map_to_left + (from_left - map_from_left),
                                .length = map_from_right - from_left + 1,
                            });
                        } else {
                            try mapped.append(Range{
                                .start = map_to_left + (from_left - map_from_left),
                                .length = from.length,
                            });
                            _ = from_ranges.orderedRemove(i);
                        }
                    }
                }
            }
        }

        for (from_ranges.items) |range| try mapped.append(range);
        return try mapped.toOwnedSlice();
    }
};

const Almanac = struct {
    seed_ranges: []Range,
    maps: []Map,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        var lines = std.mem.splitSequence(u8, input, "\n");

        // Parse seed ranges
        const seeds_line = lines.next() orelse return error.InvalidInput;
        var seed_ranges = std.ArrayList(Range).init(allocator);
        defer seed_ranges.deinit();

        var seeds_iter = std.mem.splitSequence(u8, seeds_line[7..], " ");
        while (seeds_iter.next()) |start_str| {
            const start = try std.fmt.parseInt(usize, start_str, 10);
            const length_str = seeds_iter.next() orelse return error.InvalidInput;
            const length = try std.fmt.parseInt(usize, length_str, 10);
            try seed_ranges.append(Range{ .start = start, .length = length });
        }

        // Skip empty line
        _ = lines.next();

        // Parse maps
        var maps = std.ArrayList(Map).init(allocator);
        defer maps.deinit();

        while (lines.next()) |line| {
            if (line.len == 0) continue;
            if (std.mem.indexOf(u8, line, "map:") != null) {
                const map = try Map.parse(allocator, &lines);
                try maps.append(map);
            }
        }

        return Self{
            .seed_ranges = try seed_ranges.toOwnedSlice(),
            .maps = try maps.toOwnedSlice(),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *const Self) void {
        self.allocator.free(self.seed_ranges);
        for (self.maps) |*map| {
            map.deinit();
        }
        self.allocator.free(self.maps);
    }

    // pub fn getLocationRanges(self: *Self) ![]Range {
    //     var to_map = std.ArrayList(Range).init(self.allocator);
    //     for (self.seed_ranges) |range| try to_map.append(range);

    //     for (self.maps) |map| {
    //         var mapped = std.ArrayList(Range).init(self.allocator);

    //         for (to_map) |range| {}
    //     }
    // }

    pub fn getLocation(self: *const Self, seed: usize) usize {
        const current_index = seed;
        _ = self;
        // for (self.maps) |*map| {
        //     current_index = map.mapFrom(current_index);
        // }
        return current_index;
    }
};

pub fn part1(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    const almanac = try Almanac.parse(allocator, input_lines.rest());
    defer almanac.deinit();

    const lowest_location: u64 = 0;

    // for (almanac.seeds, 0..) |seed, i| {
    //     const location = almanac.getLocation(seed);
    //     if (i == 0 or location < lowest_location) {
    //         lowest_location = location;
    //     }
    // }

    return lowest_location;
}

pub fn part2(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    std.debug.print("Parsing almanac...\n", .{});
    const almanac = try Almanac.parse(allocator, input_lines.rest());
    defer almanac.deinit();

    std.debug.print("Almanac parsed. Number of seed ranges: {}, Number of maps: {}\n", .{ almanac.seed_ranges.len, almanac.maps.len });

    var lowest_location: u64 = std.math.maxInt(u64);

    std.debug.print("Processing seed ranges...\n", .{});
    for (almanac.seed_ranges, 0..) |range, i| {
        std.debug.print("Processing range {}: start = {}, length = {}\n", .{ i, range.start, range.length });
        var seed = range.start;
        const end = seed +| range.length;
        while (seed < end) : (seed += 1) {
            if (seed % 1_000_000 == 0) {
                std.debug.print("Processed {} seeds in range {}\n", .{ seed - range.start, i });
            }
            const location = almanac.getLocation(seed);
            lowest_location = @min(lowest_location, location);
        }
    }

    std.debug.print("All seed ranges processed.\n", .{});
    return lowest_location;
}

test "map range" {
    var arena_file = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_file.deinit();
    const arena = arena_file.allocator();

    var map_ranges = std.ArrayList(MapRange).init(arena);
    try map_ranges.append(MapRange{ .from_range_start = 10, .to_range_start = 100, .range_length = 10 });
    const map = Map{
        .allocator = arena,
        .ranges = try map_ranges.toOwnedSlice(),
    };

    // cases:
    // (1) from.start < map_range.from_range_start
    //     (a) no overlap => continue
    //     (b) overlap no overflow => one unmapped, one mapped
    //     (c) overflow => one unmapped, one mapped, one unmapped
    // (2) from.start >= map_range.from_range_start
    //     (a) no overlap => continue
    //     (b) overlap => one mapped, one unmapped
    //     (c) fully overlap => one mapped
    const result_1a = try map.mapRange(Range{ .start = 0, .length = 5 });
    try std.testing.expect(result_1a.len == 1 and
        result_1a[0].start == 0 and
        result_1a[0].length == 5);
    const result_1b = try map.mapRange(Range{ .start = 0, .length = 15 });
    try std.testing.expect(result_1b.len == 2 and
        result_1b[0].start == 100 and
        result_1b[0].length == 5 and
        result_1b[1].start == 0 and
        result_1b[1].length == 10);
    const result_1c = try map.mapRange(Range{ .start = 0, .length = 30 });
    try std.testing.expect(result_1c.len == 3 and
        result_1c[0].start == 100 and
        result_1c[0].length == 10 and
        result_1c[1].start == 0 and
        result_1c[1].length == 10 and
        result_1c[2].start == 20 and
        result_1c[2].length == 10);
    const result_2a = try map.mapRange(Range{ .start = 25, .length = 5 });
    try std.testing.expect(result_2a.len == 1 and
        result_2a[0].start == 25 and
        result_2a[0].length == 5);
    const result_2b = try map.mapRange(Range{ .start = 15, .length = 10 });
    try std.testing.expect(result_2b.len == 2 and
        result_2b[0].start == 105 and
        result_2b[0].length == 5 and
        result_2b[1].start == 20 and
        result_2b[1].length == 5);
    const result_2c = try map.mapRange(Range{ .start = 10, .length = 10 });
    try std.testing.expect(result_2c.len == 1 and
        result_2c[0].start == 100 and
        result_2c[0].length == 10);
}
// test "part1" {
//     const input =
//         \\
//         \\
//         \\
//         \\
//     ;
//     const expected_result = 0;
//     try utils.testPart(input, part1, expected_result);
// }

// test "part2" {
//     const input =
//         \\
//         \\
//         \\
//         \\
//     ;
//     const expected_result = 0;
//     try utils.testPart(input, part2, expected_result);
// }
