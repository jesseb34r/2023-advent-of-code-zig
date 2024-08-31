const std = @import("std");
const utils = @import("utils");

const SYMBOLS = .{ '*', '/', '@', '&', '$', '=', '#', '-', '+', '%' };

const NumberWithRange = struct {
    value: u64,
    start_index: usize,
    end_index: usize,
};

const SymbolWithRange = struct {
    symbol: u8,
    index: usize,
};

const SchematicLine = struct {
    numbers: []NumberWithRange,
    symbols: []SymbolWithRange,

    pub fn parseLine(allocator: std.mem.Allocator, line: []const u8) !@This() {
        var numbers = std.ArrayList(NumberWithRange).init(allocator);
        defer numbers.deinit();
        var symbols = std.ArrayList(SymbolWithRange).init(allocator);
        defer symbols.deinit();

        var start_index: ?usize = null;
        var current_digits = std.ArrayList(u8).init(allocator);
        defer current_digits.deinit();

        for (line, 0..line.len) |c, i| {
            if (std.ascii.isDigit(c)) {
                try current_digits.append(c);
                if (start_index == null) {
                    start_index = i;
                }
            } else {
                if (start_index != null) {
                    try numbers.append(NumberWithRange{
                        .value = try std.fmt.parseInt(u64, try current_digits.toOwnedSlice(), 10),
                        .start_index = start_index.?,
                        .end_index = i - 1,
                    });
                    start_index = null;
                    current_digits.clearAndFree();
                }

                if (std.mem.indexOfScalar(u8, &SYMBOLS, c) != null) {
                    try symbols.append(SymbolWithRange{ .symbol = c, .index = i });
                }
            }
        }

        // Handle number at the end of the line
        if (start_index != null) {
            try numbers.append(NumberWithRange{
                .value = try std.fmt.parseInt(u64, try current_digits.toOwnedSlice(), 10),
                .start_index = start_index.?,
                .end_index = line.len - 1,
            });
        }

        return @This(){
            .numbers = try numbers.toOwnedSlice(),
            .symbols = try symbols.toOwnedSlice(),
        };
    }

    pub fn eql(self: @This(), other: @This()) bool {
        if (self.numbers.len != other.numbers.len) return false;
        if (self.symbols.len != other.symbols.len) return false;

        for (self.numbers, other.numbers) |num1, num2| {
            if (num1.value != num2.value or
                num1.start_index != num2.start_index or
                num1.end_index != num2.end_index)
            {
                return false;
            }
        }

        for (self.symbols, other.symbols) |sym1, sym2| {
            if (sym1.symbol != sym2.symbol or sym1.index != sym2.index) {
                return false;
            }
        }

        return true;
    }
};

const Schematic = struct {
    lines: []SchematicLine,

    pub fn parseSchematic(
        allocator: std.mem.Allocator,
        input_lines: *std.mem.TokenIterator(u8, .sequence),
    ) !@This() {
        var parsed_lines = std.ArrayList(SchematicLine).init(allocator);
        defer parsed_lines.deinit();

        while (input_lines.next()) |line| {
            try parsed_lines.append(try SchematicLine.parseLine(allocator, line));
        }

        return Schematic{ .lines = try parsed_lines.toOwnedSlice() };
    }

    pub fn getPartNumberSum(self: @This()) u64 {
        var sum: u64 = 0;

        for (0..self.lines.len) |i| {
            numbers_loop: for (self.lines[i].numbers) |number| {
                const row_start = if (i > 0) i - 1 else i;
                const row_end = if (i < self.lines.len - 1) i + 1 else i;

                for (row_start..row_end + 1) |row| {
                    for (self.lines[row].symbols) |symbol| {
                        if (symbol.index >= number.start_index -| 1 and
                            symbol.index <= number.end_index + 1)
                        {
                            sum += number.value;
                            continue :numbers_loop;
                        }
                    }
                }
            }
        }

        return sum;
    }
};

pub fn part1(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    const schematic = try Schematic.parseSchematic(allocator, input_lines);
    return schematic.getPartNumberSum();
}

pub fn part2(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    _ = allocator;
    var sum: u64 = 0;

    while (input_lines.next()) |line| {
        _ = line;
    }
    sum += 0;

    return sum;
}

test "parse schematic line" {
    var arena_file = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_file.deinit();
    const arena = arena_file.allocator();

    const input_line = "467..*114..";

    var expected_numbers = std.ArrayList(NumberWithRange).init(arena);
    defer expected_numbers.deinit();
    try expected_numbers.append(NumberWithRange{ .value = 467, .start_index = 0, .end_index = 2 });
    try expected_numbers.append(NumberWithRange{ .value = 114, .start_index = 6, .end_index = 8 });

    var expected_symbols = std.ArrayList(SymbolWithRange).init(arena);
    defer expected_symbols.deinit();
    try expected_symbols.append(SymbolWithRange{ .symbol = '*', .index = 5 });

    const expected_line = SchematicLine{
        .numbers = try expected_numbers.toOwnedSlice(),
        .symbols = try expected_symbols.toOwnedSlice(),
    };
    const parsed_line = try SchematicLine.parseLine(arena, input_line);

    try std.testing.expect(parsed_line.eql(expected_line));
}

test "part1" {
    const input =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;
    const expected_result = 4361;
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
