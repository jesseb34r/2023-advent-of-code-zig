const std = @import("std");
const utils = @import("utils");

const Set = struct {
    red: u32 = 0,
    green: u32 = 0,
    blue: u32 = 0,
};

const Game = struct {
    id: u32,
    sets: []Set,

    pub fn parseGame(allocator: std.mem.Allocator, line: []const u8) !@This() {
        // Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        var game_parts = std.mem.splitSequence(u8, line, ": ");
        const id_part = game_parts.next().?; // Game 1
        const sets_part = game_parts.next().?; // 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green

        const id = try std.fmt.parseInt(u32, id_part[5..], 10); // 1

        var sets = std.ArrayList(Set).init(allocator);
        defer sets.deinit();

        var sets_iter = std.mem.splitSequence(u8, sets_part, "; ");
        while (sets_iter.next()) |set_str| { // 3 blue, 4 red
            var set = Set{};

            var colors_iter = std.mem.splitSequence(u8, set_str, ", ");
            while (colors_iter.next()) |color_str| { // 3 blue
                var color_parts = std.mem.splitScalar(u8, color_str, ' ');
                const count = try std.fmt.parseInt(u32, color_parts.next().?, 10);
                const color = color_parts.next().?;

                if (std.mem.eql(u8, color, "red")) {
                    set.red = count;
                } else if (std.mem.eql(u8, color, "green")) {
                    set.green = count;
                } else if (std.mem.eql(u8, color, "blue")) {
                    set.blue = count;
                }
            }

            try sets.append(set);
        }

        return @This(){
            .id = id,
            .sets = try sets.toOwnedSlice(),
        };
    }

    pub fn isPossible(self: @This(), bag: Set) bool {
        for (self.sets) |set| {
            if (set.red > bag.red or set.green > bag.green or set.blue > bag.blue) {
                return false;
            }
        }
        return true;
    }

    pub fn eql(self: @This(), other: @This()) bool {
        if (self.id != other.id) return false;
        if (self.sets.len != other.sets.len) return false;
        for (self.sets, other.sets) |set1, set2| {
            if (set1.red != set2.red or set1.green != set2.green or set1.blue != set2.blue) {
                return false;
            }
        }
        return true;
    }
};

pub fn part1(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    var sum: u64 = 0;

    const bag = Set{ .red = 12, .green = 13, .blue = 14 };

    while (input_lines.next()) |line| {
        const game = try Game.parseGame(allocator, line);
        if (game.isPossible(bag)) {
            sum += game.id;
        }
    }

    return sum;
}

pub fn part2(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    var sum: u64 = 0;

    _ = allocator;

    while (input_lines.next()) |line| {
        _ = line;
    }

    sum += 0;

    return sum;
}

test "parseGame" {
    var arena_file = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_file.deinit();
    const arena = arena_file.allocator();

    const input = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green";

    var expected_sets = std.ArrayList(Set).init(arena);

    try expected_sets.append(Set{ .red = 4, .green = 0, .blue = 3 });
    try expected_sets.append(Set{ .red = 1, .green = 2, .blue = 6 });
    try expected_sets.append(Set{ .red = 0, .green = 2, .blue = 0 });

    const expected_result = Game{
        .id = 1,
        .sets = try expected_sets.toOwnedSlice(),
    };

    const parsed_game = try Game.parseGame(arena, input);
    try std.testing.expect(parsed_game.eql(expected_result));
}

test "possibleGame" {
    var arena_file = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_file.deinit();
    const arena = arena_file.allocator();

    const game = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green";
    const parsed_game = try Game.parseGame(arena, game);
    const bag = Set{ .red = 4, .green = 2, .blue = 6 };

    try std.testing.expect(parsed_game.isPossible(bag));
}

test "impossibleGame" {
    var arena_file = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_file.deinit();
    const arena = arena_file.allocator();

    const game = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green";
    const parsed_game = try Game.parseGame(arena, game);
    const bag = Set{ .red = 0, .green = 0, .blue = 0 };

    try std.testing.expect(!parsed_game.isPossible(bag));
}

test "part1" {
    const input =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;
    const expected_result = 8;
    try utils.testPart(input, part1, expected_result);
}

test "part2" {
    const input =
        \\
        \\
        \\
        \\
    ;
    const expected_result = 0;
    try utils.testPart(input, part2, expected_result);
}
