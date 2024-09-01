const std = @import("std");
const utils = @import("utils");

const Card = struct {
    const Self = @This();

    winning_numbers: []u8,
    your_numbers: []u8,

    pub fn parseCard(
        allocator: std.mem.Allocator,
        line: []const u8,
    ) !Self {
        var card_parts = std.mem.splitScalar(u8, line, ':');
        _ = card_parts.next();
        const numbers_part = card_parts.next().?;

        var numbers_parts = std.mem.splitScalar(u8, numbers_part, '|');
        const winning_part = numbers_parts.next().?;
        const your_part = numbers_parts.next().?;

        var winning_numbers = std.ArrayList(u8).init(allocator);
        defer winning_numbers.deinit();

        var winning_numbers_iter = std.mem.tokenizeScalar(u8, winning_part, ' ');
        while (winning_numbers_iter.next()) |num_str| {
            const num = try std.fmt.parseInt(u8, num_str, 10);
            try winning_numbers.append(num);
        }

        const winning_numbers_slice = try winning_numbers.toOwnedSlice();

        var your_numbers = std.ArrayList(u8).init(allocator);
        defer your_numbers.deinit();

        var your_numbers_iter = std.mem.tokenizeScalar(u8, your_part, ' ');
        while (your_numbers_iter.next()) |num_str| {
            const num = try std.fmt.parseInt(u8, num_str, 10);
            try your_numbers.append(num);
        }

        const your_numbers_slice = try your_numbers.toOwnedSlice();

        return Self{
            .winning_numbers = winning_numbers_slice,
            .your_numbers = your_numbers_slice,
        };
    }

    pub fn countMatchingNumbers(self: *const Self) usize {
        var sum: usize = 0;

        for (self.your_numbers) |your_num| {
            for (self.winning_numbers) |winning_num| {
                if (your_num == winning_num) {
                    sum += 1;
                    break;
                }
            }
        }

        return sum;
    }

    pub fn getScore(self: *const Self) u64 {
        const matching_numbers = self.countMatchingNumbers();
        if (matching_numbers == 0) return 0;
        return std.math.pow(u64, 2, matching_numbers - 1);
    }

    pub fn eql(self: *Self, other: *Self) bool {
        if (self.winning_numbers.len != other.winning_numbers.len or
            self.your_numbers.len != other.your_numbers.len)
        {
            return false;
        }

        for (self.winning_numbers, other.winning_numbers) |a, b| {
            if (a != b) return false;
        }

        for (self.your_numbers, other.your_numbers) |a, b| {
            if (a != b) return false;
        }

        return true;
    }
};

const CardListIterator = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    cards: []Card,
    index: usize,

    pub fn process(self: *Self) u64 {
        var card_counts = self.allocator.alloc(u64, self.cards.len) catch unreachable;
        defer self.allocator.free(card_counts);
        @memset(card_counts, 1);

        for (self.cards, 0..) |card, i| {
            const matching_numbers = card.countMatchingNumbers();
            for (0..matching_numbers) |j| {
                const next_index = i + j + 1;
                if (next_index < self.cards.len) {
                    card_counts[next_index] += card_counts[i];
                }
            }
        }

        var total_cards: u64 = 0;
        for (card_counts) |count| {
            total_cards += count;
        }

        return total_cards;
    }

    pub fn parseCardList(
        allocator: std.mem.Allocator,
        input_lines: *std.mem.TokenIterator(u8, .sequence),
    ) !Self {
        var cards = std.ArrayList(Card).init(allocator);
        defer cards.deinit();

        while (input_lines.next()) |line| {
            const card = try Card.parseCard(allocator, line);
            try cards.append(card);
        }

        const cards_slice = try cards.toOwnedSlice();
        return Self.init(allocator, cards_slice);
    }

    pub fn init(allocator: std.mem.Allocator, cards: []Card) Self {
        return .{
            .allocator = allocator,
            .cards = cards,
            .index = 0,
        };
    }

    pub fn next(self: *Self) ?Card {
        if (self.index >= self.cards.len) {
            return null;
        }
        const card = self.cards[self.index];
        self.index += 1;
        return card;
    }

    pub fn reset(self: *Self) void {
        self.index = 0;
    }
};

pub fn part1(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    var sum: u64 = 0;

    while (input_lines.next()) |line| {
        const card = try Card.parseCard(allocator, line);
        sum += card.getScore();
    }

    return sum;
}

pub fn part2(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    var card_list_iter = try CardListIterator.parseCardList(allocator, input_lines);

    return card_list_iter.process();
}

test "part1" {
    const input =
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;
    const expected_result = 13;
    try utils.testPart(input, part1, expected_result);
}

test "part2" {
    const input =
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;
    const expected_result = 30;
    try utils.testPart(input, part2, expected_result);
}
