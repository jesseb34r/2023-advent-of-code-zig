const std = @import("std");
const utils = @import("utils");

const PulseState = enum { high, low };

const Pulse = struct {
    input_module: []const u8,
    destination_modules: [][]const u8,
    pulse_state: PulseState,
};

const OnOff = enum {
    on,
    off,

    const Self = @This();

    pub fn toggle(self: *Self) void {
        self.* = if (self.* == .on) .off else .on;
    }
};

const FlipFlopModule = struct {
    name: []const u8,
    destination_modules: [][]const u8,
    state: OnOff = .off,

    const Self = @This();

    pub fn pulse(
        self: *Self,
        pulse_state: PulseState,
    ) ?Pulse {
        if (pulse_state == PulseState.high) {
            return null;
        } else {
            self.state.toggle();
        }
        return Pulse{
            .input_module = self.name,
            .destination_modules = self.destination_modules,
            .pulse_state = if (self.state == .on) .high else .low,
        };
    }
};

const ConjunctionModule = struct {
    name: []const u8,
    destination_modules: [][]const u8,
    state: std.StringArrayHashMap(PulseState),

    const Self = @This();

    pub fn pulse(
        self: *Self,
        pulse_state: PulseState,
        input_module: []const u8,
    ) !Pulse {
        try self.state.put(input_module, pulse_state);

        var state_it = self.state.iterator();
        var all_high = true;
        while (state_it.next()) |module| {
            if (module.value_ptr.* == .low) {
                all_high = false;
                break;
            }
        }

        return Pulse{
            .input_module = self.name,
            .destination_modules = self.destination_modules,
            .pulse_state = if (all_high) .low else .high,
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
            else => return error.InvalidModuleType,
        };

        var parts = std.mem.splitSequence(u8, input, " -> ");

        const name = parts.next().?[1..];

        const destinations_part = parts.next().?;
        var destinations_arr = std.mem.splitSequence(u8, destinations_part, ", ");
        var destinations_builder = std.ArrayList([]const u8).init(allocator);
        while (destinations_arr.next()) |dest| {
            try destinations_builder.append(dest);
        }

        const destination_modules = try destinations_builder.toOwnedSlice();

        return switch (module_type) {
            .flipflop => Module{ .flipflop = FlipFlopModule{
                .name = name,
                .destination_modules = destination_modules,
            } },
            .conjunction => Module{ .conjunction = ConjunctionModule{
                .name = name,
                .destination_modules = destination_modules,
                .state = std.StringArrayHashMap(PulseState).init(allocator),
            } },
        };
    }
};

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    // Parse modules
    var input_lines = std.mem.tokenizeSequence(u8, input, "\n");

    var modules = std.StringHashMap(Module).init(allocator);

    var broadcast_destinations = std.ArrayList([]const u8).init(allocator);

    // parse modules
    while (input_lines.next()) |line| {
        switch (line[0]) {
            'b' => {
                // parse broadcast module destinations
                var line_parts = std.mem.splitSequence(u8, line, " -> ");
                _ = line_parts.next();
                var dest_arr = std.mem.splitSequence(u8, line_parts.next().?, ", ");
                while (dest_arr.next()) |dest| try broadcast_destinations.append(dest);
            },
            '%', '&' => {
                const mod = try Module.parse(allocator, line);
                const name = switch (mod) {
                    .flipflop => |f| f.name,
                    .conjunction => |c| c.name,
                };
                try modules.put(name, mod);
            },
            else => unreachable,
        }
    }

    // set initial conjuction module input state to all lows
    for (broadcast_destinations.items) |dest| {
        const dest_mod = modules.get(dest);
        if (dest_mod == null) continue;
        if (dest_mod.? == .conjunction) {
            var state = dest_mod.?.conjunction.state;
            try state.put("broadcaster", .low);
        }
    }

    var modules_it = modules.iterator();
    while (modules_it.next()) |mod| {
        switch (mod.value_ptr.*) {
            .flipflop => |f| for (f.destination_modules) |dest| {
                const dest_mod = modules.get(dest);
                if (dest_mod == null) continue;
                if (dest_mod.? == .conjunction) {
                    var state = dest_mod.?.conjunction.state;
                    try state.put(f.name, .low);
                }
            },
            .conjunction => |c| for (c.destination_modules) |dest| {
                const dest_mod = modules.get(dest);
                if (dest_mod == null) continue;
                if (dest_mod.? == .conjunction) {
                    var state = dest_mod.?.conjunction.state;
                    try state.put(c.name, .low);
                }
            },
        }
    }

    // var high_count: u64 = 0;
    // var low_count: u64 = 0;

    // for (0..1000) |_| {
    //     //count initial low pulse from button to broadcaster
    //     low_count += 1;

    //     var pulses = std.ArrayList(Pulse).init(allocator);
    //     var next_pulse_wave = std.ArrayList(Pulse).init(allocator);

    //     // add initial pulses from broadcaster
    //     low_count += broadcast_destinations.items.len;
    //     try pulses.append(Pulse{
    //         .input_module = "broadcaster",
    //         .destination_modules = broadcast_destinations.items,
    //         .pulse_state = .low,
    //     });

    //     while (pulses.items.len > 0) {
    //         for (pulses.items) |pulse| {
    //             for (pulse.destination_modules) |dest| {
    //                 const mod = modules.getPtr(dest);
    //                 if (mod == null) continue;

    //                 switch (mod.?.*) {
    //                     .flipflop => |*f| {
    //                         if (pulse.pulse_state == .low) {
    //                             const new_pulse = f.pulse(pulse.pulse_state).?;
    //                             try next_pulse_wave.append(new_pulse);

    //                             if (new_pulse.pulse_state == .high) {
    //                                 high_count += new_pulse.destination_modules.len;
    //                             } else {
    //                                 low_count += new_pulse.destination_modules.len;
    //                             }
    //                         }
    //                     },
    //                     .conjunction => |*c| {
    //                         const new_pulse = try c.pulse(pulse.pulse_state, pulse.input_module);
    //                         try next_pulse_wave.append(new_pulse);

    //                         if (new_pulse.pulse_state == .high) {
    //                             high_count += new_pulse.destination_modules.len;
    //                         } else {
    //                             low_count += new_pulse.destination_modules.len;
    //                         }
    //                     },
    //                 }
    //             }
    //         }
    //         pulses.clearAndFree();
    //         try pulses.appendSlice(next_pulse_wave.items);
    //         next_pulse_wave.clearAndFree();
    //     }
    // }

    // std.debug.print("low: {d}, high: {d}\n", .{ low_count, high_count });
    // return low_count * high_count;

    var high_count: u64 = 0;
    var low_count: u64 = 0;

    for (0..1000) |button_press| {
        std.debug.print("Button press {d}:\n", .{button_press + 1});

        // Count initial low pulse from button to broadcaster
        low_count += 1;
        std.debug.print("button -low-> broadcaster\n", .{});

        var pulses = std.ArrayList(Pulse).init(allocator);
        var next_pulse_wave = std.ArrayList(Pulse).init(allocator);

        // Add initial pulses from broadcaster
        for (broadcast_destinations.items) |dest| {
            low_count += 1;
            std.debug.print("broadcaster -low-> {s}\n", .{dest});
        }
        try pulses.append(Pulse{
            .input_module = "broadcaster",
            .destination_modules = broadcast_destinations.items,
            .pulse_state = .low,
        });

        while (pulses.items.len > 0) {
            for (pulses.items) |pulse| {
                for (pulse.destination_modules) |dest| {
                    const mod = modules.getPtr(dest);
                    if (mod == null) {
                        // Count pulses to non-existent modules (like "output")
                        if (pulse.pulse_state == .high) {
                            high_count += 1;
                        } else {
                            low_count += 1;
                        }
                        std.debug.print("{s} -{s}-> {s}\n", .{ pulse.input_module, @tagName(pulse.pulse_state), dest });
                        continue;
                    }

                    switch (mod.?.*) {
                        .flipflop => |*f| {
                            if (pulse.pulse_state == .low) {
                                const new_pulse = f.pulse(pulse.pulse_state).?;
                                try next_pulse_wave.append(new_pulse);

                                if (new_pulse.pulse_state == .high) {
                                    high_count += new_pulse.destination_modules.len;
                                } else {
                                    low_count += new_pulse.destination_modules.len;
                                }
                                for (new_pulse.destination_modules) |new_dest| {
                                    std.debug.print("{s} -{s}-> {s}\n", .{ f.name, @tagName(new_pulse.pulse_state), new_dest });
                                }
                            } else {
                                std.debug.print("{s} -high-> {s} (ignored)\n", .{ pulse.input_module, f.name });
                            }
                        },
                        .conjunction => |*c| {
                            const new_pulse = try c.pulse(pulse.pulse_state, pulse.input_module);
                            try next_pulse_wave.append(new_pulse);

                            if (new_pulse.pulse_state == .high) {
                                high_count += new_pulse.destination_modules.len;
                            } else {
                                low_count += new_pulse.destination_modules.len;
                            }
                            for (new_pulse.destination_modules) |new_dest| {
                                std.debug.print("{s} -{s}-> {s}\n", .{ c.name, @tagName(new_pulse.pulse_state), new_dest });
                            }
                        },
                    }
                }
            }
            pulses.clearAndFree();
            try pulses.appendSlice(next_pulse_wave.items);
            next_pulse_wave.clearAndFree();
        }

        std.debug.print("After button press {d}: low: {d}, high: {d}\n", .{ button_press + 1, low_count, high_count });
    }

    std.debug.print("Final counts: low: {d}, high: {d}\n", .{ low_count, high_count });
    return low_count * high_count;
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
        \\broadcaster -> a, b, c
        \\%a -> b
        \\%b -> c
        \\%c -> inv
        \\&inv -> a
    ;
    const expected_result_1 = 32000000;
    const result_1 = try part1(allocator, test_input_1);
    try std.testing.expectEqual(expected_result_1, result_1);

    const test_input_2 =
        \\broadcaster -> a
        \\%a -> inv, con
        \\&inv -> b
        \\%b -> con
        \\&con -> output
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
