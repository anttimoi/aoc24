const std = @import("std");

pub const Result = struct {
    input_duration: u64,
    algorithm_duration: u64,
    assignment_result: u64,
};

pub fn Pair(comptime value_type: type) type {
    return struct {
        a: value_type,
        b: value_type,
    };
}

pub const File = struct {
    name: []const u8,
    size: usize,
};

pub fn FileContent(comptime file: File) type {
    return [file.size]u8;
}

pub fn readFile(comptime file: File) ![file.size]u8 {
    var buffer: [file.size]u8 = undefined;
    _ = try std.fs.cwd().readFile(file.name, &buffer);
    return buffer;
}

pub fn parseInteger(comptime T: type, buffer: []const u8) T {
    var result: T = 0;

    for (buffer) |char| {
        result *= 10;
        const digit = char - 48;
        result += @intCast(digit);
    }

    return result;
}
