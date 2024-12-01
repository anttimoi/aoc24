const std = @import("std");
const d1 = @import("1.zig");
const sampling = @import("sampling.zig");

pub fn main() !void {
    const sample_size = 1000;
    try sampling.run(sample_size, d1.part1);
    try sampling.run(sample_size, d1.part2);
}
