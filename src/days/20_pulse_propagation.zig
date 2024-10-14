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

                // std.debug.print("processing pulse, checking if memory is all high\n", .{});
                // check if all input modules most recent pulse was high
                var all_high = true;
                var memory_it = self.memory.?.iterator();
                while (memory_it.next()) |mod| {
                    if (mod.value_ptr.* == .low) {
                        // std.debug.print("found low pulse\n", .{});
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
        try graph.initState();

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

    /// make sure to set to initial state to get accurate counts
    pub fn countCycleLength(self: *Self) !u64 {
        // count number of pulses to the given input_node are needed to hit the output node
        var cycle_count: u64 = 0;
        var pulse_queue = std.ArrayList(Pulse).init(self.allocator);

        while (true) : (pulse_queue.clearAndFree()) {
            cycle_count += 1;

            try pulse_queue.append(Pulse{
                .from = "broadcaster",
                .to = self.broadcast_targets.items[0],
                .pulse_type = .low,
            });

            var cycle_end = false;

            while (pulse_queue.items.len > 0) {
                const pulse = pulse_queue.orderedRemove(0);

                if (self.modules.get(pulse.to) == null and pulse.pulse_type == .low) {
                    cycle_end = true;
                }

                if (self.modules.getPtr(pulse.to)) |module| {
                    if (try module.processPulse(pulse)) |new_pulses| {
                        for (new_pulses.items) |new_pulse| {
                            try pulse_queue.append(new_pulse);
                        }
                    }
                }
            }

            if (cycle_end) return cycle_count;
        }
        return 0;
    }

    pub fn constructSubGraph(self: *Self, starting_module: []const u8) !Self {
        // initialize graph
        var sub_graph = Self{
            .allocator = self.allocator,
            .modules = std.StringArrayHashMap(Module).init(self.allocator),
            .broadcast_targets = std.ArrayList([]const u8).init(self.allocator),
        };
        try sub_graph.broadcast_targets.append(starting_module);

        // clear current graph state before copying modules
        self.clearState();

        // construct graph from modules connected to starting_module
        var mod_queue = std.ArrayList([]const u8).init(self.allocator);
        try mod_queue.append(starting_module);

        while (mod_queue.items.len > 0) {
            const current_mod_name = mod_queue.orderedRemove(0);

            if (self.modules.get(current_mod_name)) |current_mod| {
                if (current_mod.kind == .flipflop) {
                    try mod_queue.appendSlice(current_mod.targets.items);
                }
                try sub_graph.modules.put(current_mod_name, current_mod);
            }
        }

        // initialize conjunction module inputs
        try sub_graph.initState();

        return sub_graph;
    }

    pub fn printGraphState(self: *const Self) !void {
        var f_modules = std.StringArrayHashMap(void).init(self.allocator);
        var c_modules = std.StringArrayHashMap(void).init(self.allocator);

        // var mod_queue = std.ArrayList([]const u8).init(self.allocator);
        // try mod_queue.appendSlice(self.broadcast_targets.items);

        // while (mod_queue.items.len > 0) {
        //     const current_mod_name = mod_queue.orderedRemove(0);

        //     if (self.modules.get(current_mod_name)) |current_mod| {
        //         switch (current_mod.kind) {
        //             .flipflop => {
        //                 try f_modules.put(current_mod.name, {});
        //                 try mod_queue.appendSlice(current_mod.targets.items);
        //             },
        //             .conjunction => {
        //                 try c_modules.put(current_mod.name, {});
        //             },
        //         }
        //     }
        // }

        var mod_it = self.modules.iterator();
        while (mod_it.next()) |mod| switch (mod.value_ptr.kind) {
            .flipflop => try f_modules.put(mod.value_ptr.name, {}),
            .conjunction => try c_modules.put(mod.value_ptr.name, {}),
        };

        std.debug.print("FlipFlop Modules: ", .{});
        var f_mod_it = f_modules.iterator();
        while (f_mod_it.next()) |f| std.debug.print("{s} ", .{f.key_ptr.*});
        std.debug.print("\nConjunction Modules: ", .{});
        var c_mod_it = c_modules.iterator();
        while (c_mod_it.next()) |c| std.debug.print("{s} ", .{c.key_ptr.*});
        std.debug.print("\n", .{});
    }

    fn initState(self: *Self) !void {
        var module_it = self.modules.iterator();
        while (module_it.next()) |mod| {
            if (mod.value_ptr.kind == .flipflop) mod.value_ptr.state = .off;
            for (mod.value_ptr.targets.items) |target_name| {
                const target_ptr = self.modules.getPtr(target_name);
                if (target_ptr) |t| {
                    if (t.kind == .conjunction) try t.*.memory.?.put(mod.value_ptr.name, .low);
                }
            }
        }
    }

    pub fn clearState(self: *Self) void {
        var module_it = self.modules.iterator();
        while (module_it.next()) |mod_entry| {
            switch (mod_entry.value_ptr.kind) {
                .flipflop => mod_entry.value_ptr.state = .off,
                .conjunction => mod_entry.value_ptr.memory.?.clearAndFree(),
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

    var cycle_lengths = std.ArrayList(u64).init(allocator);

    var sub_1 = try graph.constructSubGraph(graph.broadcast_targets.items[0]);
    try sub_1.printGraphState();
    try cycle_lengths.append(try sub_1.countCycleLength());

    var sub_2 = try graph.constructSubGraph(graph.broadcast_targets.items[1]);
    try sub_2.printGraphState();
    try cycle_lengths.append(try sub_2.countCycleLength());

    var sub_3 = try graph.constructSubGraph(graph.broadcast_targets.items[2]);
    try sub_3.printGraphState();
    try cycle_lengths.append(try sub_3.countCycleLength());

    var sub_4 = try graph.constructSubGraph(graph.broadcast_targets.items[3]);
    try sub_4.printGraphState();
    try cycle_lengths.append(try sub_4.countCycleLength());

    // Calculate the LCM of cycle lengths
    var cycle_lcm: u64 = cycle_lengths.items[0];
    for (cycle_lengths.items[1..]) |length| {
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
