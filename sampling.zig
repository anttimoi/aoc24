const std = @import("std");
const Result = @import("common.zig").Result;

fn getAverageResult(comptime sample_size: u64, results: [sample_size]Result) Result {
    var sum = Result{
        .input_duration = 0,
        .algorithm_duration = 0,
        .assignment_result = 0,
    };

    for (0..sample_size) |i| {
        sum.input_duration += results[i].input_duration;
        sum.algorithm_duration += results[i].algorithm_duration;
        sum.assignment_result += results[i].assignment_result;
    }

    sum.input_duration /= sample_size;
    sum.algorithm_duration /= sample_size;
    sum.assignment_result /= sample_size;

    return sum;
}

fn print(result: Result) void {
    const total_duration = result.input_duration + result.algorithm_duration;
    std.debug.print("result: {d}\n", .{result.assignment_result});
    std.debug.print("input: {d} us, algorithm: {d} us, total: {d} us\n\n", .{ result.input_duration, result.algorithm_duration, total_duration });
}

pub fn run(comptime sample_size: usize, runner: fn () anyerror!Result) !void {
    var results: [sample_size]Result = undefined;

    for (0..sample_size) |i| {
        results[i] = try runner();
    }

    print(getAverageResult(sample_size, results));
}
