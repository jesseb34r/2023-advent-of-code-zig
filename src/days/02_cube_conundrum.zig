const std = @import("std");

const file_input = @embedFile("./inputs/02.txt");

const Set = struct {
    red: u32 = 0,
    green: u32 = 0,
    blue: u32 = 0,

    pub fn power(self: @This()) u64 {
        return self.red * self.green * self.blue;
    }

    pub fn eql(self: @This(), other: @This()) bool {
        return self.red == other.red and
            self.green == other.green and
            self.blue == other.blue;
    }
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

    pub fn minimalBag(self: @This()) Set {
        var bag = Set{};
        for (self.sets) |set| {
            bag.red = @max(bag.red, set.red);
            bag.green = @max(bag.green, set.green);
            bag.blue = @max(bag.blue, set.blue);
        }
        return bag;
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

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");

    const bag = Set{ .red = 12, .green = 13, .blue = 14 };

    var sum: u64 = 0;
    while (input_lines.next()) |line| {
        const game = try Game.parseGame(allocator, line);
        if (game.isPossible(bag)) {
            sum += game.id;
        }
    }
    return sum;
}

pub fn part2(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");

    var sum: u64 = 0;
    while (input_lines.next()) |line| {
        const game = try Game.parseGame(allocator, line);
        sum += game.minimalBag().power();
    }
    return sum;
}

test "parse game" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_input = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green";

    const parsed_game = try Game.parseGame(allocator, test_input);

    var expected_sets = std.ArrayList(Set).init(allocator);
    defer expected_sets.deinit();

    try expected_sets.append(Set{ .red = 4, .green = 0, .blue = 3 });
    try expected_sets.append(Set{ .red = 1, .green = 2, .blue = 6 });
    try expected_sets.append(Set{ .red = 0, .green = 2, .blue = 0 });
    const expected_result = Game{
        .id = 1,
        .sets = try expected_sets.toOwnedSlice(),
    };

    try std.testing.expect(parsed_game.eql(expected_result));
}

test "possible game" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_game_input = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green";
    const parsed_game = try Game.parseGame(allocator, test_game_input);

    const bag = Set{ .red = 4, .green = 2, .blue = 6 };
    try std.testing.expect(parsed_game.isPossible(bag));
}

test "impossible game" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_game_input = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green";
    const parsed_game = try Game.parseGame(allocator, test_game_input);

    const bag = Set{ .red = 0, .green = 0, .blue = 0 };
    try std.testing.expect(!parsed_game.isPossible(bag));
}

test "minimal bag" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var sets = std.ArrayList(Set).init(allocator);

    try sets.append(Set{ .red = 4, .green = 0, .blue = 3 });
    try sets.append(Set{ .red = 1, .green = 2, .blue = 6 });
    try sets.append(Set{ .red = 0, .green = 2, .blue = 0 });
    const game = Game{ .id = 1, .sets = try sets.toOwnedSlice() };

    const expected_minimal_bag = Set{ .red = 4, .green = 2, .blue = 6 };
    try std.testing.expect(game.minimalBag().eql(expected_minimal_bag));
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_input =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;

    const expected_result = 8;
    const result = try part1(allocator, test_input);

    try std.testing.expectEqual(expected_result, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_input =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;

    const expected_result = 2286;
    const result = try part2(allocator, test_input);

    try std.testing.expectEqual(expected_result, result);
}
