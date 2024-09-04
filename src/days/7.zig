const std = @import("std");
const utils = @import("utils");

const Card = enum(u8) {
    Ace = 14,
    King = 13,
    Queen = 12,
    Jack = 11,
    Ten = 10,
    Nine = 9,
    Eight = 8,
    Seven = 7,
    Six = 6,
    Five = 5,
    Four = 4,
    Three = 3,
    Two = 2,
    // Joker = 1,

    const Self = @This();

    pub fn fromChar(char: u8) !Self {
        return switch (char) {
            'A' => .Ace,
            'K' => .King,
            'Q' => .Queen,
            'J' => .Jack,
            'T' => .Ten,
            '9' => .Nine,
            '8' => .Eight,
            '7' => .Seven,
            '6' => .Six,
            '5' => .Five,
            '4' => .Four,
            '3' => .Three,
            '2' => .Two,
            else => return error.InvalidCard,
        };
    }

    // pub fn fromCharPartTwo(char: u8) !Self {
    //     return switch (char) {
    //         'A' => .Ace,
    //         'K' => .King,
    //         'Q' => .Queen,
    //         'T' => .Ten,
    //         '9' => .Nine,
    //         '8' => .Eight,
    //         '7' => .Seven,
    //         '6' => .Six,
    //         '5' => .Five,
    //         '4' => .Four,
    //         '3' => .Three,
    //         '2' => .Two,
    //         'J' => .Joker,
    //         else => return error.InvalidCard,
    //     };
    // }

    pub fn getRank(self: Self) u8 {
        return @intFromEnum(self);
    }
};

const HandType = enum(u8) {
    FiveOfAKind = 7,
    FourOfAKind = 6,
    FullHouse = 5,
    ThreeOfAKind = 4,
    TwoPair = 3,
    OnePair = 2,
    HighCard = 1,

    const Self = @This();

    pub fn parse(cards: [5]Card) !HandType {
        var counts = [_]u8{0} ** 15;
        // var jokers: u8 = 0;
        for (cards) |card| {
            // if (card == .Joker) {
            // jokers += 1;
            // continue;
            // }
            counts[@intFromEnum(card)] += 1;
        }

        // var hand_type: HandType = .HighCard;
        var has_three = false;
        var pairs: u8 = 0;
        for (counts) |count| {
            switch (count) {
                5 => return .FiveOfAKind,
                4 => return .FourOfAKind,
                3 => has_three = true,
                2 => pairs += 1,
                else => {},
            }
        }

        if (has_three and pairs == 1) return .FullHouse;
        if (has_three) return .ThreeOfAKind;
        if (pairs == 2) return .TwoPair;
        if (pairs == 1) return .OnePair;
        return .HighCard;

        // switch (jokers) {
        //     0 => {},
        //     1 => {
        //         switch (hand_type) {
        //             .FourOfAKind => hand_type = .FiveOfAKind,
        //             .ThreeOfAKind => hand_type = .FourOfAKind,
        //             .TwoPair => hand_type = .FullHouse,
        //             .OnePair => hand_type = .ThreeOfAKind,
        //             else => hand_type = .OnePair,
        //         }
        //     },
        //     2 => {
        //         switch (hand_type) {
        //             .ThreeOfAKind => hand_type = .FiveOfAKind,
        //             .OnePair => hand_type = .FourOfAKind,
        //             else => hand_type = .ThreeOfAKind,
        //         }
        //     },
        //     3 => {
        //         if (hand_type == .OnePair) {
        //             hand_type = .FiveOfAKind;
        //         } else {
        //             hand_type = .FourOfAKind;
        //         }
        //     },
        //     4 => hand_type = .FiveOfAKind,
        //     5 => hand_type = .FiveOfAKind,
        //     else => unreachable,
        // }

        // return hand_type;
    }

    pub fn getRank(self: Self) u8 {
        return @intFromEnum(self);
    }
};

const Hand = struct {
    cards: [5]Card,
    bid: u64,
    hand_type: HandType,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        var hand_parts = std.mem.tokenizeSequence(u8, input, " ");

        const cards_str = hand_parts.next().?;
        var cards_arr = std.ArrayList(Card).init(allocator);
        for (cards_str) |card_char| {
            try cards_arr.append(try Card.fromChar(card_char));
        }
        const cards: [5]Card = (try cards_arr.toOwnedSlice())[0..5].*;

        const bid_str = hand_parts.next().?;
        const bid = try std.fmt.parseInt(u64, bid_str, 10);

        const hand_type = try HandType.parse(cards);

        return Self{ .cards = cards, .bid = bid, .hand_type = hand_type };
    }

    // pub fn parsePartTwo(allocator: std.mem.Allocator, input: []const u8) !Self {
    //     var hand_parts = std.mem.tokenizeSequence(u8, input, " ");

    //     const cards_str = hand_parts.next().?;
    //     var cards_arr = std.ArrayList(Card).init(allocator);
    //     for (cards_str) |card_char| {
    //         try cards_arr.append(try Card.fromCharPartTwo(card_char));
    //     }
    //     const cards: [5]Card = (try cards_arr.toOwnedSlice())[0..5].*;

    //     const bid_str = hand_parts.next().?;
    //     const bid = try std.fmt.parseInt(u64, bid_str, 10);

    //     const hand_type = try HandType.parse(cards);

    //     return Self{ .cards = cards, .bid = bid, .hand_type = hand_type };
    // }

    pub fn compareHands(context: void, a: Hand, b: Hand) bool {
        _ = context;
        if (a.hand_type.getRank() != b.hand_type.getRank()) {
            return a.hand_type.getRank() < b.hand_type.getRank();
        }
        for (a.cards, b.cards) |card_a, card_b| {
            if (card_a != card_b) {
                return card_a.getRank() < card_b.getRank();
            }
        }
        return false;
    }
};

pub fn part1(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    var hand_set = std.ArrayList(Hand).init(allocator);

    while (input_lines.next()) |line| {
        try hand_set.append(try Hand.parse(allocator, line));
    }

    std.sort.insertion(Hand, hand_set.items, {}, Hand.compareHands);

    var sum: u64 = 0;
    for (hand_set.items, 1..) |hand, i| {
        sum += i * hand.bid;
    }
    return sum;
}

pub fn part2(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    var hand_set = std.ArrayList(Hand).init(allocator);

    while (input_lines.next()) |line| {
        // try hand_set.append(try Hand.parsePartTwo(allocator, line));
        try hand_set.append(try Hand.parse(allocator, line));
    }

    std.sort.insertion(Hand, hand_set.items, {}, Hand.compareHands);

    var sum: u64 = 0;
    for (hand_set.items, 1..) |hand, i| {
        sum += i * hand.bid;
    }
    return sum;
}

test "part1" {
    const input =
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    ;
    const expected_result = 6440;
    try utils.testPart(input, part1, expected_result);
}

test "part2" {
    const input =
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    ;
    const expected_result = 5905;
    try utils.testPart(input, part2, expected_result);
}
