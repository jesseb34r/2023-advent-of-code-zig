const std = @import("std");
const utils = @import("utils");

const PartRating = enum(u8) {
    x = 'x',
    m = 'm',
    a = 'a',
    s = 's',
};

const Part = struct {
    x: u64,
    m: u64,
    a: u64,
    s: u64,

    const Self = @This();

    pub fn parse(input: []const u8) !Self {
        // example line {x=787,m=2655,a=1222,s=2876}
        const trimmed = std.mem.trim(u8, input, "{}");
        var iter = std.mem.splitSequence(u8, trimmed, ",");
        return Self{
            .x = try std.fmt.parseInt(u64, iter.next().?[2..], 10),
            .m = try std.fmt.parseInt(u64, iter.next().?[2..], 10),
            .a = try std.fmt.parseInt(u64, iter.next().?[2..], 10),
            .s = try std.fmt.parseInt(u64, iter.next().?[2..], 10),
        };
    }

    pub fn value(self: *const Self) u64 {
        return self.x + self.m + self.a + self.s;
    }
};

const Condition = enum(u8) { lt = '<', gt = '>' };

const Rule = struct {
    rating: PartRating,
    condition: Condition,
    value: u64,
    destination: []const u8,

    const Self = @This();

    pub fn parse(input: []const u8) !Self {
        const rating: PartRating = @enumFromInt(input[0]);
        const condition: Condition = @enumFromInt(input[1]);

        var rest = std.mem.splitScalar(u8, input[2..], ':');

        const value = try std.fmt.parseInt(u64, rest.next().?, 10);
        const destination = rest.next().?;

        return Self{
            .rating = rating,
            .condition = condition,
            .value = value,
            .destination = destination,
        };
    }

    pub fn processPart(self: *const Self, part: Part) ?[]const u8 {
        const part_value = switch (self.rating) {
            .x => part.x,
            .m => part.m,
            .a => part.a,
            .s => part.s,
        };

        switch (self.condition) {
            .lt => return if (part_value < self.value) self.destination else null,
            .gt => return if (part_value > self.value) self.destination else null,
        }
    }
};

const Workflow = struct {
    name: []const u8,
    rules: []Rule,
    destination: []const u8,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Self {
        // example line: qqz{s>2770:qs,m<1801:hdj,R}
        const name_end = std.mem.indexOfScalar(u8, input, '{') orelse return error.InvalidInput;
        const name = input[0..name_end];

        var rules_arr = std.mem.splitScalar(u8, input[(name_end + 1)..(input.len - 1)], ',');
        var rules_builder = std.ArrayList(Rule).init(allocator);

        var destination: []const u8 = undefined;

        while (rules_arr.next()) |rule_str| {
            if (rules_arr.peek() == null) {
                destination = rule_str;
                break;
            }
            try rules_builder.append(try Rule.parse(rule_str));
        }

        const rules = try rules_builder.toOwnedSlice();

        return Self{
            .name = name,
            .rules = rules,
            .destination = destination,
        };
    }

    /// returns the appropriate destination name
    pub fn processPart(self: *const Self, part: Part) []const u8 {
        for (self.rules) |rule| {
            const destination = rule.processPart(part);
            if (destination == null) continue else return destination.?;
        }
        return self.destination;
    }
};

/// true => accept, false => reject
fn processPart(
    workflows: *std.StringHashMap(Workflow),
    part: Part,
    destination: []const u8,
) bool {
    if (std.mem.eql(u8, destination, "R")) return false;
    if (std.mem.eql(u8, destination, "A")) return true;

    const next_dest = workflows.get(destination).?.processPart(part);

    // std.debug.print("Next destination: {s}\n", .{next_dest});

    return processPart(
        workflows,
        part,
        next_dest,
    );
}

pub fn part1(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_sections = std.mem.splitSequence(u8, input, "\n\n");
    const workflows_section = input_sections.next().?;
    const parts_section = input_sections.next().?;

    var workflows_arr = std.mem.tokenizeSequence(u8, workflows_section, "\n");
    var workflows = std.StringHashMap(Workflow).init(allocator);

    while (workflows_arr.next()) |workflow_str| {
        const workflow = try Workflow.parse(allocator, workflow_str);
        try workflows.put(workflow.name, workflow);
    }

    var parts_arr = std.mem.tokenizeSequence(u8, parts_section, "\n");
    var sum: u64 = 0;
    while (parts_arr.next()) |part_str| {
        const part = try Part.parse(part_str);

        // std.debug.print("Part: {any}\n", .{part});

        const first_dest = workflows.get("in").?.processPart(part);

        // std.debug.print("First Destination: {s}\n", .{first_dest});

        if (processPart(&workflows, part, first_dest)) {
            // std.debug.print("Accepted\n", .{});
            sum += part.value();
        } else {
            // std.debug.print("Rejected\n", .{});
        }
    }

    return sum;
}

const Range = struct {
    min: u64 = 1,
    max: u64 = 4000,

    const Self = @This();

    pub fn range(self: *const Self) u64 {
        return self.max - self.min + 1;
    }
};

const Path = struct {
    x: Range = Range{},
    m: Range = Range{},
    a: Range = Range{},
    s: Range = Range{},

    const Self = @This();

    pub fn uniquePaths(self: *const Self) u64 {
        return (self.x.range() * self.m.range() * self.a.range() * self.s.range());
    }
};

fn findSuccessPaths(
    workflows: *std.StringHashMap(Workflow),
    current_path: Path,
    destination: []const u8,
) u64 {
    if (std.mem.eql(u8, destination, "R")) return 0;
    if (std.mem.eql(u8, destination, "A")) return current_path.uniquePaths();

    var sum: u64 = 0;
    const current_workflow = &workflows.get(destination).?;
    var remaining_path = current_path;

    for (current_workflow.rules) |rule| {
        inline for (@typeInfo(PartRating).Enum.fields) |field| {
            if (@field(PartRating, field.name) == rule.rating) {
                const range = @field(remaining_path, field.name);

                switch (rule.condition) {
                    .lt => {
                        if (range.max < rule.value) {
                            return sum + findSuccessPaths(
                                workflows,
                                remaining_path,
                                rule.destination,
                            );
                        } else if (range.min < rule.value) {
                            var narrowed_path = remaining_path;
                            @field(narrowed_path, field.name).max = rule.value - 1;
                            sum += findSuccessPaths(
                                workflows,
                                narrowed_path,
                                rule.destination,
                            );
                            @field(remaining_path, field.name).min = rule.value;
                        }
                    },
                    .gt => {
                        if (range.min > rule.value) {
                            return sum + findSuccessPaths(
                                workflows,
                                remaining_path,
                                rule.destination,
                            );
                        } else if (range.max > rule.value) {
                            var narrowed_path = remaining_path;
                            @field(narrowed_path, field.name).min = rule.value + 1;
                            sum += findSuccessPaths(
                                workflows,
                                narrowed_path,
                                rule.destination,
                            );
                            @field(remaining_path, field.name).max = rule.value;
                        }
                    },
                }
            }
        }
    }

    return sum + findSuccessPaths(
        workflows,
        remaining_path,
        current_workflow.destination,
    );
}

pub fn part2(allocator: std.mem.Allocator, comptime input: []const u8) !u64 {
    var input_sections = std.mem.splitSequence(u8, input, "\n\n");
    const workflows_section = input_sections.next().?;

    var workflows_arr = std.mem.tokenizeSequence(u8, workflows_section, "\n");
    var workflows = std.StringHashMap(Workflow).init(allocator);

    while (workflows_arr.next()) |workflow_str| {
        const workflow = try Workflow.parse(allocator, workflow_str);
        try workflows.put(workflow.name, workflow);
    }

    return findSuccessPaths(
        &workflows,
        Path{},
        "in",
    );
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_input =
        \\px{a<2006:qkq,m>2090:A,rfg}
        \\pv{a>1716:R,A}
        \\lnx{m>1548:A,A}
        \\rfg{s<537:gd,x>2440:R,A}
        \\qs{s>3448:A,lnx}
        \\qkq{x<1416:A,crn}
        \\crn{x>2662:A,R}
        \\in{s<1351:px,qqz}
        \\qqz{s>2770:qs,m<1801:hdj,R}
        \\gd{a>3333:R,R}
        \\hdj{m>838:A,pv}
        \\
        \\{x=787,m=2655,a=1222,s=2876}
        \\{x=1679,m=44,a=2067,s=496}
        \\{x=2036,m=264,a=79,s=2244}
        \\{x=2461,m=1339,a=466,s=291}
        \\{x=2127,m=1623,a=2188,s=1013}
    ;

    const expected_result = 19114;
    const result = try part1(allocator, test_input);

    try std.testing.expectEqual(expected_result, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_input =
        \\px{a<2006:qkq,m>2090:A,rfg}
        \\pv{a>1716:R,A}
        \\lnx{m>1548:A,A}
        \\rfg{s<537:gd,x>2440:R,A}
        \\qs{s>3448:A,lnx}
        \\qkq{x<1416:A,crn}
        \\crn{x>2662:A,R}
        \\in{s<1351:px,qqz}
        \\qqz{s>2770:qs,m<1801:hdj,R}
        \\gd{a>3333:R,R}
        \\hdj{m>838:A,pv}
        \\
        \\{x=787,m=2655,a=1222,s=2876}
        \\{x=1679,m=44,a=2067,s=496}
        \\{x=2036,m=264,a=79,s=2244}
        \\{x=2461,m=1339,a=466,s=291}
        \\{x=2127,m=1623,a=2188,s=1013}
    ;

    const expected_result = 167409079868000;
    const result = try part2(allocator, test_input);

    try std.testing.expectEqual(expected_result, result);
}
