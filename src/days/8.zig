const std = @import("std");
const utils = @import("utils");

const MapNode = struct {
    code: [3]u8,
    left: ?*MapNode = null,
    right: ?*MapNode = null,

    const Self = @This();

    pub fn fromCode(code: [3]u8) Self {
        return Self{
            .code = code,
        };
    }
};

const MapTree = struct {
    nodes: std.AutoHashMap([3]u8, *MapNode),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .nodes = std.AutoHashMap([3]u8, *MapNode).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        var nodes_iter = self.nodes.valueIterator();
        while (nodes_iter.next()) |node_ptr| {
            self.allocator.destroy(node_ptr.*);
        }
        self.nodes.deinit();
    }

    pub fn addNode(self: *Self, code: [3]u8) !void {
        const node = try self.allocator.create(MapNode);
        errdefer self.allocator.destroy(node);
        node.* = MapNode.fromCode(code);
        try self.nodes.put(code, node);
    }

    pub fn setChildren(self: *Self, parent_code: [3]u8, left_code: [3]u8, right_code: [3]u8) !void {
        var parent = self.nodes.get(parent_code) orelse return error.NodeNotFound;
        parent.left = self.nodes.get(left_code);
        parent.right = self.nodes.get(right_code);
    }
};

pub fn part1(
    allocator: std.mem.Allocator,
    input_lines: *std.mem.TokenIterator(u8, .sequence),
) !u64 {
    const directions = input_lines.next().?;
    // _ = input_lines.next().?;

    var map_tree = MapTree.init(allocator);
    defer map_tree.deinit();

    var node_codes = std.ArrayList([3][3]u8).init(allocator);

    while (input_lines.next()) |line| {
        var node_parts = std.mem.splitSequence(u8, line, " = ");
        const code_str = node_parts.next().?;
        const children_str = node_parts.next().?;

        if (code_str.len != 3) return error.InvalidNodeCode;
        try map_tree.addNode(code_str[0..3].*);

        var children_parts = std.mem.splitSequence(u8, std.mem.trim(u8, children_str, "()"), ", ");
        const left = children_parts.next().?;
        const right = children_parts.next().?;

        if (left.len != 3 or right.len != 3) return error.InvalidChildCode;
        try node_codes.append(.{ code_str[0..3].*, left[0..3].*, right[0..3].* });
    }

    for (node_codes.items) |codes| {
        try map_tree.setChildren(codes[0], codes[1], codes[2]);
    }

    var current_node = map_tree.nodes.get("AAA".*).?;
    var path_length: u64 = 0;

    outer: while (true) {
        for (directions) |d| {
            path_length += 1;

            current_node = switch (d) {
                'L' => current_node.left.?,
                'R' => current_node.right.?,
                else => unreachable,
            };

            if (std.mem.eql(u8, &current_node.code, "ZZZ")) break :outer;
        }
    }

    return path_length;
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

test "part1" {
    const input_1 =
        \\RL
        \\
        \\AAA = (BBB, CCC)
        \\BBB = (DDD, EEE)
        \\CCC = (ZZZ, GGG)
        \\DDD = (DDD, DDD)
        \\EEE = (EEE, EEE)
        \\GGG = (GGG, GGG)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    const expected_result_1 = 2;
    try utils.testPart(input_1, part1, expected_result_1);

    const input_2 =
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    const expected_result_2 = 6;
    try utils.testPart(input_2, part1, expected_result_2);
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
