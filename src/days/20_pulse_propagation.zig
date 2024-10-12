const std = @import("std");
const utils = @import("utils");

const PulseType = enum { high, low };

const Pulse = struct {
    from: u16,
    targets: []u16,
    pulse_type: PulseType,
};

const OnOff = enum { on, off };

const FlipFlopModule = struct {
    id: u16,
    targets: []u16,
    state: OnOff,

    const Self = @This();

    pub fn init(id: u16, targets: []u16) Self {
        return Self{ .id = id, .targets = targets, .state = .off };
    }

    pub fn pulse(
        self: *Self,
        pulse_type: PulseType,
    ) ?Pulse {
        if (pulse_type == .high) return null;

        self.toggle();

        return Pulse{
            .from = self.id,
            .targets = self.targets,
            .pulse_type = if (self.state == .on) .high else .low,
        };
    }

    fn toggle(self: *Self) void {
        self.state = if (self.state == .on) .off else .on;
    }
};

const ConjunctionModule = struct {
    id: u16,
    targets: []u16,
    state: std.AutoArrayHashMap(u16, PulseType),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, id: u16, targets: []u16) Self {
        const state = std.AutoArrayHashMap(u16, PulseType).init(allocator);
        return Self{ .id = id, .targets = targets, .state = state };
    }

    pub fn pulse(
        self: *Self,
        from: u16,
        pulse_type: PulseType,
    ) !Pulse {
        try self.state.put(from, pulse_type);

        var state_it = self.state.iterator();
        var all_high = true;
        while (state_it.next()) |module| {
            if (module.value_ptr.* == .low) {
                all_high = false;
                break;
            }
        }

        return Pulse{
            .from = self.id,
            .targets = self.targets,
            .pulse_type = if (all_high) .low else .high,
        };
    }
};

const ModuleType = enum {
    flipflop,
    conjunction,
};

const Module = union(ModuleType) {
    flipflop: FlipFlopModule,
    conjunction: ConjunctionModule,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        const module_type: ModuleType = switch (input[0]) {
            '%' => .flipflop,
            '&' => .conjunction,
            else => unreachable,
        };

        var parts = std.mem.splitSequence(u8, input, " -> ");

        const id = sliceToId(parts.next().?[1..]);

        const targets_part = parts.next().?;
        var targets_it = std.mem.splitSequence(u8, targets_part, ", ");
        var targets_builder = std.ArrayList(u16).init(allocator);
        while (targets_it.next()) |target| {
            try targets_builder.append(sliceToId(target));
        }
        const target_modules = try targets_builder.toOwnedSlice();

        return switch (module_type) {
            .flipflop => Module{
                .flipflop = FlipFlopModule.init(id, target_modules),
            },
            .conjunction => Module{
                .conjunction = ConjunctionModule.init(allocator, id, target_modules),
            },
        };
    }
};

fn sliceToId(name: []const u8) u16 {
    std.debug.assert(name.len == 2);
    return @as(u16, name[0]) << 8 | name[1];
}

const PulseCount = struct {
    high: u64,
    low: u64,
};

const Graph = struct {
    allocator: std.mem.Allocator,
    modules: std.AutoArrayHashMap(u16, Module),
    broadcast_targets: []u16 = undefined,

    const Self = @This();

    pub fn parseAndInit(allocator: std.mem.Allocator, input: []const u8) !Self {
        var input_lines = std.mem.tokenizeSequence(u8, input, "\n");

        var graph = Self.init(allocator);

        while (input_lines.next()) |line| {
            if (line[0] == 'b') {
                try graph.parseBroadcasterTargets(line);
                continue;
            }

            try graph.addModule(try Module.parse(allocator, line));
        }

        try graph.initConjunctionModuleState();

        return graph;
    }

    pub fn broadcast(self: *Self) !PulseCount {
        var low_count: u64 = 1; // start at 1 to include the pulse from the button
        var high_count: u64 = 0;
        var pulse_queue = std.ArrayList(Pulse).init(self.allocator);

        // low_count += self.broadcast_targets.len;
        try pulse_queue.append(Pulse{
            .from = @as(u16, 0),
            .targets = self.broadcast_targets,
            .pulse_type = .low,
        });

        while (pulse_queue.items.len > 0) {
            const pulse = pulse_queue.orderedRemove(0);
            switch (pulse.pulse_type) {
                .high => high_count += pulse.targets.len,
                .low => low_count += pulse.targets.len,
            }

            for (pulse.targets) |target_id| {
                if (self.modules.getPtr(target_id)) |module| {
                    switch (module.*) {
                        .flipflop => |*f| {
                            if (f.pulse(pulse.pulse_type)) |new_pulse| {
                                try pulse_queue.append(new_pulse);
                            }
                        },
                        .conjunction => |*c| {
                            const new_pulse = try c.pulse(pulse.from, pulse.pulse_type);
                            try pulse_queue.append(new_pulse);
                        },
                    }
                }
            }
        }

        return PulseCount{ .high = high_count, .low = low_count };
    }

    fn init(allocator: std.mem.Allocator) Self {
        const modules = std.AutoArrayHashMap(u16, Module).init(allocator);
        return Self{ .allocator = allocator, .modules = modules };
    }

    fn addModule(self: *Self, module: Module) !void {
        const id = switch (module) {
            .flipflop => |f| f.id,
            .conjunction => |c| c.id,
        };

        try self.modules.put(id, module);
    }

    fn parseBroadcasterTargets(self: *Self, line: []const u8) !void {
        // broadcaster line is always formatted "broadcaster -> <targets>"
        var broadcast_targets_it = std.mem.splitSequence(u8, line[15..], ", ");
        var broadcast_targets_builder = std.ArrayList(u16).init(self.allocator);
        while (broadcast_targets_it.next()) |target| {
            try broadcast_targets_builder.append(sliceToId(target));
        }
        self.broadcast_targets = try broadcast_targets_builder.toOwnedSlice();
    }

    fn initConjunctionModuleState(self: *Self) !void {
        // check broadcast_targets
        const broadcast_id: u16 = 0;
        for (self.broadcast_targets) |target_id| {
            switch (self.modules.getPtr(target_id).?.*) {
                .flipflop => {},
                .conjunction => |*c| {
                    try c.state.put(broadcast_id, .low);
                },
            }
        }

        // check rest of modules
        var module_it = self.modules.iterator();
        while (module_it.next()) |mod| {
            const id = switch (mod.value_ptr.*) {
                .flipflop => |f| f.id,
                .conjunction => |c| c.id,
            };
            const targets = switch (mod.value_ptr.*) {
                .flipflop => |f| f.targets,
                .conjunction => |c| c.targets,
            };

            for (targets) |target_id| {
                const mod_ptr = self.modules.getPtr(target_id);
                if (mod_ptr == null) continue; // ignore targets that don't exist

                switch (mod_ptr.?.*) {
                    .flipflop => {},
                    .conjunction => |*c| {
                        try c.state.put(id, .low);
                    },
                }
            }
        }
    }
};

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var graph = try Graph.parseAndInit(allocator, input);

    var pulse_count = PulseCount{
        .high = 0,
        .low = 0,
    };

    for (0..1000) |_| {
        const p = try graph.broadcast();
        pulse_count.high += p.high;
        pulse_count.low += p.low;
    }

    std.debug.print("Final counts: low: {d}, high: {d}\n", .{ pulse_count.low, pulse_count.high });
    return pulse_count.low * pulse_count.high;
}

pub fn part2(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");
    _ = allocator;
    var sum: u64 = 0;

    while (input_lines.next()) |line| {
        _ = line;
    }
    sum += 0;

    return sum;
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_input_1 =
        \\broadcaster -> aa, bb, cc
        \\%aa -> bb
        \\%bb -> cc
        \\%cc -> in
        \\&in -> aa
    ;
    const expected_result_1 = 32000000;
    const result_1 = try part1(allocator, test_input_1);
    try std.testing.expectEqual(expected_result_1, result_1);

    const test_input_2 =
        \\broadcaster -> aa
        \\%aa -> in, co
        \\&in -> bb
        \\%bb -> co
        \\&co -> ou
    ;
    const expected_result_2 = 11687500;
    const result_2 = try part1(allocator, test_input_2);
    try std.testing.expectEqual(expected_result_2, result_2);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_input =
        \\
        \\
        \\
        \\
    ;

    const expected_result = 0;
    const result = try part2(allocator, test_input);

    try std.testing.expectEqual(expected_result, result);
}
