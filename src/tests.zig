// const Day = struct {
//     /// filename is the day number and the title from AOC
//     /// e.g. 01_trebuchet.zig
//     filename: []const u8,

//     /// once a day is completed correctly, add this for testing performance in the future
//     part1_answer: ?u64,
//     part2_answer: ?u64,

//     const Self = @This();

//     /// Returns the name of the file with .zig stripped
//     pub fn name(self: *const Self) []const u8 {
//         return std.fs.path.step(self.filename);
//     }

//     /// Returns the day number of the file with zero indexing removed
//     /// e.g. "01_trebuchet.zig" is day "1"
//     pub fn day(self: *const Self) []const u8 {
//         // filename must be day_name.zig
//         const end_index = std.mem.indexOfScalar(u8, self.filename, '_') orelse
//             unreachable;

//         var start_index: usize = 0;
//         while (self.main_file[start_index] == '0') start_index += 1;
//         return self.main_file[start_index..end_index];
//     }

//     /// Returns the day number as a usize
//     pub fn number(self: *const Self) usize {
//         return std.fmt.parseInt(usize, self.day(), 10) catch unreachable;
//     }
// };

// const days = [25]Day{
//     Day{
//         .filename = "01_trebuchet.zig",
//         .part1_answer = 54304,
//         .part2_answer = 54418,
//     },
//     Day{
//         .filename = "02_cube_conundrum.zig",
//         .part1_answer = 2101,
//         .part2_answer = 58269,
//     },
//     Day{
//         .filename = "03_gear_ratios.zig",
//         .part1_answer = 525181,
//         .part2_answer = 84289137,
//     },
//     Day{
//         .filename = "04_scratchcards.zig",
//         .part1_answer = 28538,
//         .part2_answer = 9425061,
//     },
//     Day{
//         .filename = "05_if_you_give_a_seed_a_fertilizer.zig",
//         .part1_answer = 403695602,
//         .part2_answer = 219529182,
//     },
//     Day{
//         .filename = "06_wait_for_it.zig",
//         .part1_answer = 281600,
//         .part2_answer = 33875953,
//     },
//     Day{
//         .filename = "07_camel_cards.zig",
//         .part1_answer = 250946742,
//         .part2_answer = 251824095,
//     },
//     Day{
//         .filename = "08_haunted_wasteland.zig",
//         .part1_answer = ,
//         .part2_answer = ,
//     },
//     Day{
//         .filename = "09_mirage_maintenance.zig",
//         .part1_answer = ,
//         .part2_answer = ,
//     },
//     Day{
//         .filename = "10_pipe_maze.zig",
//         .part1_answer = ,
//         .part2_answer = ,
//     },
//     Day{
//         .filename = "11_cosmic_expansion.zig",
//         .part1_answer = ,
//         .part2_answer = ,
//     },
//     Day{
//         .filename = "12_hot_springs.zig",
//         .part1_answer = ,
//         .part2_answer = ,
//     },
//     Day{
//         .filename = "13_point_of_incidence.zig",
//         .part1_answer = ,
//         .part2_answer = ,
//     },
//     Day{
//         .filename = "14_parabolic_reflector_dish.zig",
//         .part1_answer = ,
//         .part2_answer = ,
//     },
//     Day{
//         .filename = "15_lens_library.zig",
//         .part1_answer = ,
//         .part2_answer = ,
//     },
//     Day{
//         .filename = "16_the_floor_will_be_lava.zig",
//         .part1_answer = ,
//         .part2_answer = ,
//     },
//     Day{
//         .filename = "17_clumsy_crucible.zig",
//     },
//     Day{
//         .filename = "18_lavaduct_lagoon.zig",
//     },
//     Day{
//         .filename = "19_aplenty.zig",
//     },
//     Day{
//         .filename = "20_pulse_propagation.zig",
//     },
//     Day{
//         .filename = "21_step_counter.zig",
//     },
//     Day{
//         .filename = "22_sand_slabs.zig",
//     },
//     Day{
//         .filename = "23_a_long_walk.zig",
//     },
//     Day{
//         .filename = "24_never_tell_me_the_odds.zig",
//     },
//     Day{
//         .filename = "25_snowverload.zig",
//     },
// };
