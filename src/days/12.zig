const std = @import("std");
const utils = @import("utils");

fn parseKeys(allocator: std.mem.Allocator, key_str: []const u8) ![]usize {
    var iter = std.mem.splitScalar(u8, key_str, ',');
    var num_arr = std.ArrayList(usize).init(allocator);

    while (iter.next()) |num_str| {
        try num_arr.append(try std.fmt.parseInt(usize, num_str, 10));
    }

    return try num_arr.toOwnedSlice();
}

fn getNumValidCases(map: []const u8, keys: []usize) u64 {
    if (map.len == 0) return if (keys.len == 0) 1 else 0;
    if (keys.len == 0) return if (std.mem.indexOfScalar(u8, map, '#') != null) 0 else 1;

    // keys not all used, not end of map:

    var cases: u64 = 0;

    if (map[0] == '.' or map[0] == '?') {
        cases += getNumValidCases(if (map.len < 2) &[0]u8{} else map[1..], keys);
    }

    if (map[0] == '#' or map[0] == '?') {
        if (keys[0] <= map.len and std.mem.indexOfScalar(u8, map[0..keys[0]], '.') == null and (keys[0] == map.len or map[keys[0]] != '#')) {
            cases += getNumValidCases(
                if (map.len < keys[0] + 1) &[0]u8{} else map[(keys[0] + 1)..],
                if (keys.len < 2) &[0]usize{} else keys[1..],
            );
        }
    }

    return cases;
}

pub fn part1(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    var sum: u64 = 0;
    while (input_lines.next()) |line| {
        var line_parts = std.mem.splitSequence(u8, line, " ");
        const map_str = line_parts.next().?;
        const key_str = line_parts.next().?;
        const keys = try parseKeys(allocator, key_str);

        sum += getNumValidCases(map_str, keys);
    }
    return sum;
}

// fn memoizedGetNumValidCases(map: []const u8, keys: []usize, cache) u64{
//     const cache_key = .{ .map = map, .keys = keys };

//     if (cache.get(cache_key)) |cached_result| {
//         return cached_result;
//     };

//     const result = getNumValidCases(map, keys);
//     try cache.put(key, result);
// return result;
// };

const CacheKey = struct {
    map_len: usize,
    map_first: u8,
    keys_len: usize,
    keys_first: usize,

    fn init(map: []const u8, keys: []const usize) CacheKey {
        return .{
            .map_len = map.len,
            .map_first = if (map.len > 0) map[0] else 0,
            .keys_len = keys.len,
            .keys_first = if (keys.len > 0) keys[0] else 0,
        };
    }

    fn hash(self: CacheKey) u64 {
        var h = std.hash.Wyhash.init(0);
        h.update(&std.mem.toBytes(self.map_len));
        h.update(&[_]u8{self.map_first});
        h.update(&std.mem.toBytes(self.keys_len));
        h.update(&std.mem.toBytes(self.keys_first));
        return h.final();
    }

    fn eql(self: CacheKey, other: CacheKey) bool {
        return self.map_len == other.map_len and
            self.map_first == other.map_first and
            self.keys_len == other.keys_len and
            self.keys_first == other.keys_first;
    }
};

fn memoizedGetNumValidCases(
    map: []const u8,
    keys: []usize,
    cache: *std.AutoHashMap(CacheKey, u64),
) u64 {
    if (map.len == 0) return if (keys.len == 0) 1 else 0;
    if (keys.len == 0) return if (std.mem.indexOfScalar(u8, map, '#') != null) 0 else 1;

    const cache_key = CacheKey.init(map, keys);

    if (cache.*.get(cache_key)) |cached_result| {
        return cached_result;
    }

    var cases: u64 = 0;

    if (map[0] == '.' or map[0] == '?') {
        cases += memoizedGetNumValidCases(if (map.len < 2) &[0]u8{} else map[1..], keys, cache);
    }

    if (map[0] == '#' or map[0] == '?') {
        if (keys[0] <= map.len and
            std.mem.indexOfScalar(u8, map[0..keys[0]], '.') == null and
            (keys[0] == map.len or map[keys[0]] != '#'))
        {
            cases += memoizedGetNumValidCases(if (map.len < keys[0] + 1) &[0]u8{} else map[(keys[0] + 1)..], if (keys.len < 2) &[0]usize{} else keys[1..], cache);
        }
    }

    cache.*.put(cache_key, cases) catch unreachable;
    return cases;
}

pub fn part2(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    var sum: u64 = 0;

    var cache = std.AutoHashMap(CacheKey, u64).init(allocator);
    defer cache.deinit();

    while (input_lines.next()) |line| {
        var line_parts = std.mem.splitSequence(u8, line, " ");

        const map_str = line_parts.next().?;
        var map_arr = std.ArrayList(u8).init(allocator);
        defer map_arr.deinit();
        for (0..5) |i| {
            if (i > 0) try map_arr.append('?');
            try map_arr.appendSlice(map_str);
        }
        const map = try map_arr.toOwnedSlice();

        const key_str = line_parts.next().?;
        const keys_parsed = try parseKeys(allocator, key_str);
        var keys_arr = std.ArrayList(usize).init(allocator);
        defer keys_arr.deinit();
        for (0..5) |_| {
            try keys_arr.appendSlice(keys_parsed);
        }
        const keys = try keys_arr.toOwnedSlice();

        sum += memoizedGetNumValidCases(map, keys, &cache);
        cache.clearRetainingCapacity();
    }

    return sum;
}

test "part1" {
    const input =
        \\???.### 1,1,3
        \\.??..??...?##. 1,1,3
        \\?#?#?#?#?#?#?#? 1,3,1,6
        \\????.#...#... 4,1,1
        \\????.######..#####. 1,6,5
        \\?###???????? 3,2,1
    ;
    const expected_result = 21;
    try utils.testPart(input, part1, expected_result);
}

test "part2" {
    const input =
        \\???.### 1,1,3
        \\.??..??...?##. 1,1,3
        \\?#?#?#?#?#?#?#? 1,3,1,6
        \\????.#...#... 4,1,1
        \\????.######..#####. 1,6,5
        \\?###???????? 3,2,1
    ;
    const expected_result = 525152;
    try utils.testPart(input, part2, expected_result);
}
