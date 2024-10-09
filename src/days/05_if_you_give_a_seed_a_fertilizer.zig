const std = @import("std");
const utils = @import("utils");

const Range = struct {
    start: u64,
    length: u64,
};

const MapRange = struct {
    to_range_start: u64,
    from_range_start: u64,
    range_length: u64,
};

const Map = struct {
    ranges: []MapRange,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, lines: *std.mem.SplitIterator(u8, .sequence)) !Self {
        var ranges = std.ArrayList(MapRange).init(allocator);
        defer ranges.deinit();

        while (lines.next()) |line| {
            if (line.len == 0) break;

            var numbers_iter = std.mem.splitSequence(u8, line, " ");

            const to_start = try std.fmt.parseInt(u64, numbers_iter.next() orelse return error.InvalidInput, 10);
            const from_start = try std.fmt.parseInt(u64, numbers_iter.next() orelse return error.InvalidInput, 10);
            const range_length = try std.fmt.parseInt(u64, numbers_iter.next() orelse return error.InvalidInput, 10);

            try ranges.append(MapRange{
                .to_range_start = to_start,
                .from_range_start = from_start,
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
                const from_right = from.start +| from.length -| 1;
                const map_from_left = map_range.from_range_start;
                const map_from_right = map_range.from_range_start +| map_range.range_length -| 1;
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
                        from_ranges.items[i].length = map_from_left -| from_left;
                        if (from_right <= map_from_right) {
                            try mapped.append(Range{
                                .start = map_to_left,
                                .length = from_right -| map_from_left +| 1,
                            });
                        } else {
                            try mapped.append(Range{
                                .start = map_to_left,
                                .length = map_range.range_length,
                            });
                            try from_ranges.append(Range{
                                .start = map_from_right +| 1,
                                .length = from_right -| map_from_right,
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
            const start = try std.fmt.parseInt(u64, start_str, 10);
            const length_str = seeds_iter.next() orelse return error.InvalidInput;
            const length = try std.fmt.parseInt(u64, length_str, 10);
            try seed_ranges.append(Range{ .start = start, .length = length });
        }

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

    pub fn getLocationRanges(self: *Self) ![]Range {
        var to_map = self.seed_ranges;

        for (self.maps) |map| {
            var mapped = std.ArrayList(Range).init(self.allocator);
            defer mapped.deinit();

            for (to_map) |range| {
                const m = try map.mapRange(range);

                for (m) |r| try mapped.append(r);
            }

            to_map = try mapped.toOwnedSlice();
        }

        return to_map;
    }

    pub fn getLocation(self: *const Self, seed: u64) u64 {
        const current_index = seed;
        _ = self;
        // for (self.maps) |*map| {
        //     current_index = map.mapFrom(current_index);
        // }
        return current_index;
    }
};

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
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

pub fn part2(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    var almanac = try Almanac.parse(allocator, input_lines.rest());
    defer almanac.deinit();

    const location_ranges = try almanac.getLocationRanges();
    defer allocator.free(location_ranges);

    var lowest_location: u64 = std.math.maxInt(u64);
    for (location_ranges) |range| {
        if (range.start < lowest_location) {
            lowest_location = @truncate(range.start);
        }
    }

    return lowest_location;
}

test "map range" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var map_ranges = std.ArrayList(MapRange).init(allocator);
    try map_ranges.append(MapRange{ .from_range_start = 10, .to_range_start = 100, .range_length = 10 });
    const map = Map{
        .allocator = allocator,
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
//     const test_input =
//         \\
//         \\
//         \\
//         \\
//     ;
//     const expected_result = 0;
//     const result = try part2(allocator, test_input);
//
//    try std.testing.expectEqual(expected_result, result);
// }

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_input =
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ;

    const expected_result = 46;
    const result = try part2(allocator, test_input);

    try std.testing.expectEqual(expected_result, result);
}
