const std = @import("std");

const Position = struct {
    row: usize,
    col: usize,

    const Self = @This();

    pub fn forward(self: *const Self, dir: Direction, rows: usize, cols: usize) ?Self {
        return switch (dir) {
            .up => if (self.row > 0) Position{
                .row = self.row - 1,
                .col = self.col,
            } else null,
            .down => if (self.row < (rows - 1)) Position{
                .row = self.row + 1,
                .col = self.col,
            } else null,
            .left => if (self.col > 0) Position{
                .row = self.row,
                .col = self.col - 1,
            } else null,
            .right => if (self.col < (cols - 1)) Position{
                .row = self.row,
                .col = self.col + 1,
            } else null,
        };
    }

    pub fn eql(self: *const Self, other: Self) bool {
        return self.row == other.row and self.col == other.col;
    }
};

const Direction = enum {
    up,
    down,
    left,
    right,

    const Self = @This();

    pub fn opposite(self: *const Self) Self {
        return switch (self.*) {
            .up => .down,
            .down => .up,
            .left => .right,
            .right => .left,
        };
    }
};

const Node = struct {
    cost: u32,
    pos: Position,
    dir: Direction,
    moves_in_dir: u8,
    parent: ?*const Node = null,

    const Self = @This();

    /// Returns `(lhs > rhs)` instead of `(lhs < rhs)` to order priority queue
    /// so that the lowest item is the highest priority.
    pub fn order(context: void, lhs: *Node, rhs: *Node) std.math.Order {
        _ = context;

        if (lhs.cost > rhs.cost) return .gt;
        if (lhs.cost == rhs.cost) return .eq;
        if (lhs.cost < rhs.cost) return .lt;

        unreachable;
    }

    pub fn eql(self: *const Self, other: *const Self) bool {
        return self.pos.row == other.pos.row and self.pos.col == other.pos.col;
    }

    /// Finds the possible successors of this node, the nodes that are valid
    /// moves from this one.
    pub fn findSuccessors(
        self: *const Self,
        allocator: std.mem.Allocator,
        grid: *const [][]u8,
    ) ![]*Self {
        var successors_builder = std.ArrayList(*Self).init(allocator);

        const directions = comptime [_]Direction{ .up, .down, .left, .right };
        for (directions) |dir| {
            if (self.dir == dir and self.moves_in_dir == 3) {
                // already moved 3 tiles in a straight line, can't move further
                continue;
            }
            if (self.dir.opposite() == dir) {
                // can't move in opposite direction
                continue;
            }

            // simulate a move inside the bounds
            if (self.pos.forward(dir, grid.len, grid.*[0].len)) |pos| {
                const cost = @as(u32, grid.*[pos.row][pos.col] - '0');
                const moves_in_dir = if (self.dir == dir) self.moves_in_dir + 1 else 1;

                const new_node = try allocator.create(Node);
                new_node.* = .{
                    .cost = self.cost + cost,
                    .pos = pos,
                    .dir = dir,
                    .moves_in_dir = moves_in_dir,
                    .parent = self,
                };
                try successors_builder.append(new_node);
            }
        }

        return try successors_builder.toOwnedSlice();
    }

    pub fn findUltraSuccessors(
        self: *const Self,
        allocator: std.mem.Allocator,
        grid: *const [][]u8,
    ) ![]*Self {
        var successors_builder = std.ArrayList(*Self).init(allocator);

        const directions = comptime [_]Direction{ .up, .down, .left, .right };
        for (directions) |dir| {
            if (self.dir == dir and self.moves_in_dir == 10) {
                // already moved 10 tiles in a straight line, can't move further
                continue;
            }
            if (self.dir != dir and self.moves_in_dir < 4) {
                // must move at least 4 tiles before turning
                continue;
            }
            if (self.dir.opposite() == dir) {
                // can't move in opposite direction
                continue;
            }

            // simulate a move inside the bounds
            if (self.pos.forward(dir, grid.len, grid.*[0].len)) |pos| {
                const cost = @as(u32, grid.*[pos.row][pos.col] - '0');
                const moves_in_dir = if (self.dir == dir) self.moves_in_dir + 1 else 1;

                const new_node = try allocator.create(Node);
                new_node.* = .{
                    .cost = self.cost + cost,
                    .pos = pos,
                    .dir = dir,
                    .moves_in_dir = moves_in_dir,
                    .parent = self,
                };
                try successors_builder.append(new_node);
            }
        }

        return try successors_builder.toOwnedSlice();
    }
};

fn parseGrid(allocator: std.mem.Allocator, input: []const u8) ![][]u8 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");

    var grid_builder = std.ArrayList([]u8).init(allocator);
    while (input_lines.next()) |line| {
        var row = try allocator.alloc(u8, line.len);
        for (line, 0..) |val, i| {
            row[i] = val;
        }
        try grid_builder.append(row);
    }

    return try grid_builder.toOwnedSlice();
}

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    const grid = try parseGrid(allocator, input);
    const goal = Position{
        .row = grid.len - 1,
        .col = grid[0].len - 1,
    };

    // initialize priority queue
    var pq = std.PriorityQueue(*Node, void, Node.order).init(allocator, {});

    const State = struct {
        pos: Position,
        dir: Direction,
        moves_in_dir: u8,
    };

    // value = cost
    var seen = std.AutoHashMap(State, u32).init(allocator);

    const start_right = try allocator.create(Node);
    start_right.* = .{
        .cost = 0,
        .dir = .right,
        .pos = .{ .row = 0, .col = 0 },
        .moves_in_dir = 0,
    };
    try pq.add(start_right);

    const start_down = try allocator.create(Node);

    start_down.* = .{
        .cost = 0,
        .dir = .down,
        .pos = .{ .row = 0, .col = 0 },
        .moves_in_dir = 0,
    };
    try pq.add(start_down);

    while (pq.removeOrNull()) |node| {
        if (node.pos.eql(goal)) return node.cost;

        const state = State{
            .pos = node.pos,
            .dir = node.dir,
            .moves_in_dir = node.moves_in_dir,
        };

        if (seen.get(state)) |cost| if (cost <= node.cost) continue;
        try seen.put(state, node.cost);

        for (try node.findSuccessors(allocator, &grid)) |successor| {
            try pq.add(successor);
        }
    }

    return error.NoPathFound;
}

pub fn part2(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    const grid = try parseGrid(allocator, input);
    const goal = Position{
        .row = grid.len - 1,
        .col = grid[0].len - 1,
    };

    // initialize priority queue
    var pq = std.PriorityQueue(*Node, void, Node.order).init(allocator, {});

    const State = struct {
        pos: Position,
        dir: Direction,
        moves_in_dir: u8,
    };

    // value = cost
    var seen = std.AutoHashMap(State, u32).init(allocator);

    const start_right = try allocator.create(Node);
    start_right.* = .{
        .cost = 0,
        .dir = .right,
        .pos = .{ .row = 0, .col = 0 },
        .moves_in_dir = 0,
    };
    try pq.add(start_right);

    const start_down = try allocator.create(Node);

    start_down.* = .{
        .cost = 0,
        .dir = .down,
        .pos = .{ .row = 0, .col = 0 },
        .moves_in_dir = 0,
    };
    try pq.add(start_down);

    var final_node: ?*const Node = null;

    while (pq.removeOrNull()) |node| {
        if (node.pos.eql(goal)) {
            final_node = node;
            break;
        }

        const state = State{
            .pos = node.pos,
            .dir = node.dir,
            .moves_in_dir = node.moves_in_dir,
        };

        if (seen.get(state)) |cost| if (cost <= node.cost) continue;
        try seen.put(state, node.cost);

        for (try node.findUltraSuccessors(allocator, &grid)) |successor| {
            try pq.add(successor);
        }
    }

    if (final_node == null) return error.NoPathFound;

    // Reconstruct the path
    var path = std.ArrayList(Position).init(allocator);
    var current_node = final_node;
    while (current_node) |node| : (current_node = node.parent) {
        try path.append(node.pos);
    }

    // Reverse the path (it's currently from goal to start)
    std.mem.reverse(Position, path.items);

    var grid_copy = try allocator.dupe([]u8, grid);
    for (grid_copy) |*row| {
        row.* = try allocator.dupe(u8, row.*);
    }
    for (path.items) |pos| {
        grid_copy[pos.row][pos.col] = '#';
    }

    // for (grid_copy) |row| {
    // std.debug.print("{s}\n", .{row});
    // }

    return final_node.?.cost;
}

test "part1" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const test_input =
        \\2413432311323
        \\3215453535623
        \\3255245654254
        \\3446585845452
        \\4546657867536
        \\1438598798454
        \\4457876987766
        \\3637877979653
        \\4654967986887
        \\4564679986453
        \\1224686865563
        \\2546548887735
        \\4322674655533
    ;
    const expected_result = 102;

    const result = try part1(arena, test_input);
    try std.testing.expectEqual(expected_result, result);
}

test "part2" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const test_input_1 =
        \\2413432311323
        \\3215453535623
        \\3255245654254
        \\3446585845452
        \\4546657867536
        \\1438598798454
        \\4457876987766
        \\3637877979653
        \\4654967986887
        \\4564679986453
        \\1224686865563
        \\2546548887735
        \\4322674655533
    ;
    const expected_result_1 = 94;
    const result_1 = try part2(arena, test_input_1);
    try std.testing.expectEqual(expected_result_1, result_1);

    const test_input_2 =
        \\111111111111
        \\999999999991
        \\999999999991
        \\999999999991
        \\999999999991
    ;
    const expected_result_2 = 71;
    const result_2 = try part2(arena, test_input_2);
    try std.testing.expectEqual(expected_result_2, result_2);
}
