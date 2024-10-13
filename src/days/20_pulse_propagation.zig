const std = @import("std");
const utils = @import("utils");

const PulseType = enum { high, low };

const Pulse = struct {
    from: []const u8,
    to: []const u8,
    pulse_type: PulseType,
};

const OnOff = enum { on, off };

const ModuleType = enum { flipflop, conjunction };

const Module = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    kind: ModuleType,
    targets: std.ArrayList([]const u8),
    state: ?OnOff = null,
    memory: ?std.StringArrayHashMap(PulseType) = null,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        const module_type: ModuleType = switch (input[0]) {
            '%' => .flipflop,
            '&' => .conjunction,
            else => unreachable,
        };

        var parts = std.mem.splitSequence(u8, input, " -> ");

        const name = parts.next().?[1..];

        const targets_part = parts.next().?;
        var targets_it = std.mem.splitSequence(u8, targets_part, ", ");
        var targets = std.ArrayList([]const u8).init(allocator);
        while (targets_it.next()) |target| {
            try targets.append(target);
        }

        return switch (module_type) {
            .flipflop => Module{
                .allocator = allocator,
                .name = name,
                .kind = module_type,
                .targets = targets,
                .state = .off,
            },
            .conjunction => Module{
                .allocator = allocator,
                .name = name,
                .kind = module_type,
                .targets = targets,
                .memory = std.StringArrayHashMap(PulseType).init(allocator),
            },
        };
    }

    pub fn processPulse(self: *Self, pulse: Pulse) !?std.ArrayList(Pulse) {
        var pulses = std.ArrayList(Pulse).init(self.allocator);
        switch (self.kind) {
            .flipflop => {
                std.debug.assert(self.state != null and self.memory == null);

                if (pulse.pulse_type == .high) return null;

                self.state.? = if (self.state.? == .on) .off else .on;

                for (self.targets.items) |target_name| {
                    try pulses.append(Pulse{
                        .from = self.name,
                        .to = target_name,
                        .pulse_type = if (self.state.? == .on) .high else .low,
                    });
                }
            },
            .conjunction => {
                std.debug.assert(self.state == null and self.memory != null);

                // update memory
                try self.memory.?.put(pulse.from, pulse.pulse_type);

                // check if all input modules most recent pulse was high
                var all_high = true;
                var memory_it = self.memory.?.iterator();
                while (memory_it.next()) |mod| {
                    if (mod.value_ptr.* == .low) {
                        all_high = false;
                        break;
                    }
                }

                for (self.targets.items) |target_name| {
                    try pulses.append(Pulse{
                        .from = self.name,
                        .to = target_name,
                        .pulse_type = if (all_high) .low else .high,
                    });
                }
            },
        }
        return pulses;
    }
};

const PulseCount = struct {
    high: u64,
    low: u64,
};

const Graph = struct {
    allocator: std.mem.Allocator,
    modules: std.StringArrayHashMap(Module),
    broadcast_targets: std.ArrayList([]const u8),
    cycle_end: bool = false,

    const Self = @This();

    pub fn parseAndInit(allocator: std.mem.Allocator, input: []const u8) !Self {
        // initialize graph
        var graph = Self{
            .allocator = allocator,
            .modules = std.StringArrayHashMap(Module).init(allocator),
            .broadcast_targets = std.ArrayList([]const u8).init(allocator),
        };

        // parse input
        var input_lines = std.mem.tokenizeSequence(u8, input, "\n");

        while (input_lines.next()) |line| {
            // broadcaster line is always formatted "broadcaster -> <targets>"
            if (line[0] == 'b') {
                var targets_it = std.mem.splitSequence(u8, line[15..], ", ");
                while (targets_it.next()) |target_name| {
                    try graph.broadcast_targets.append(target_name);
                }
                continue;
            }

            const module = try Module.parse(allocator, line);
            try graph.modules.put(module.name, module);
        }

        // initialize conjunction module inputs
        try graph.initConjunctionModuleMemory();

        return graph;
    }

    pub fn pressButton(self: *Self) !PulseCount {
        var low_count: u64 = 1; // start at 1 to include the pulse from the button
        var high_count: u64 = 0;
        var pulse_queue = std.ArrayList(Pulse).init(self.allocator);

        // add broadcast pulses to the queue
        for (self.broadcast_targets.items) |target_name| {
            low_count += 1;
            try pulse_queue.append(Pulse{
                .from = "broadcaster",
                .to = target_name,
                .pulse_type = .low,
            });
        }

        // process queue until empty
        while (pulse_queue.items.len > 0) {
            const pulse = pulse_queue.orderedRemove(0);

            // for checking cycle length in part 2
            if (pulse.pulse_type == .high and std.mem.eql(u8, pulse.to, "dt")) {
                self.cycle_end = true;
            }

            if (self.modules.getPtr(pulse.to)) |module| {
                if (try module.processPulse(pulse)) |new_pulses| {
                    for (new_pulses.items) |new_pulse| {
                        switch (new_pulse.pulse_type) {
                            .high => high_count += 1,
                            .low => low_count += 1,
                        }
                        try pulse_queue.append(new_pulse);
                    }
                }
            }
        }

        return PulseCount{ .high = high_count, .low = low_count };
    }

    fn initConjunctionModuleMemory(self: *Self) !void {
        // broadcast targets are all flipflop so ignore

        // check rest of modules
        var module_it = self.modules.iterator();
        while (module_it.next()) |from_mod| {
            for (from_mod.value_ptr.*.targets.items) |target_name| {
                const target_ptr = self.modules.getPtr(target_name);
                if (target_ptr) |t| {
                    if (t.kind == .conjunction) try t.*.memory.?.put(from_mod.value_ptr.name, .low);
                }
            }
        }
    }

    // pub fn printConjunctionModules(self: *const Self) void {
    //     var modules_it = self.modules.iterator();
    //     while (modules_it.next()) |mod| {
    //         switch (mod.value_ptr.*) {
    //             .flipflop => {},
    //             .conjunction => |c| {
    //                 std.debug.print("Name: {s} inputs:\n", .{idToSlice(c.id)});
    //                 for (c.state.keys()) |input_id| std.debug.print("{s} ", .{idToSlice(input_id)});
    //                 std.debug.print("\ntargets:\n", .{});
    //                 for (c.targets) |target_id| std.debug.print("{s} ", .{idToSlice(target_id)});
    //                 std.debug.print("\n", .{});
    //             },
    //         }
    //     }
    // }
};

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var graph = try Graph.parseAndInit(allocator, input);

    var pulse_count = PulseCount{
        .high = 0,
        .low = 0,
    };

    for (0..1000) |_| {
        const p = try graph.pressButton();
        pulse_count.high += p.high;
        pulse_count.low += p.low;
    }

    std.debug.print("Final counts: low: {d}, high: {d}\n", .{ pulse_count.low, pulse_count.high });
    return pulse_count.low * pulse_count.high;
}

fn gcd(a: u64, b: u64) u64 {
    return if (b == 0) a else gcd(b, a % b);
}

fn lcm(a: u64, b: u64) u64 {
    return (a * b) / gcd(a, b);
}

pub fn part2(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var graph = try Graph.parseAndInit(allocator, input);

    const broadcast_targets = graph.broadcast_targets;
    var cycle_lengths = [_]u64{0} ** 4;

    for (broadcast_targets, 0..) |target_id, i| {
        graph.broadcast_targets = @constCast(&[_]u16{target_id});
        var button_presses: u64 = 0;
        while (true) {
            button_presses += 1;
            if (graph.dt_hit) break;
        }
        cycle_lengths[i] = button_presses;
    }

    // Calculate the LCM of cycle lengths
    var cycle_lcm: u64 = cycle_lengths[0];
    for (cycle_lengths[1..]) |length| {
        cycle_lcm = lcm(cycle_lcm, length);
    }

    return cycle_lcm;
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
