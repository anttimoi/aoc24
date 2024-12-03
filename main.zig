const std = @import("std");
const sampling = @import("sampling.zig");

const d1 = @import("1.zig");
const d2 = @import("2.zig");
const d3 = @import("3.zig");

pub fn main() !void {
    const sample_size = 1000;
    try sampling.run(sample_size, d1.part1);
    try sampling.run(sample_size, d1.part2);
    try sampling.run(sample_size, d2.part1);
    try sampling.run(sample_size, d2.part2);
    try sampling.run(sample_size, d3.part1);
    try sampling.run(sample_size, d3.part2);
}
