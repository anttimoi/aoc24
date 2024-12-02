const std = @import("std");
const Result = @import("common.zig").Result;

const FileConfig = struct {
    level_separator: u8,
    report_separator: u8,
    max_levels_per_report: u8,
    max_digits_per_level: u8,
    filename: []const u8,
    filesize: usize,
};

fn CharBuffer(comptime config: FileConfig) type {
    return [config.max_digits_per_level]u8;
}

fn Levels(comptime config: FileConfig) type {
    return struct {
        values: [config.max_levels_per_report]u8,
        level_count: u8,
    };
}

fn ReadState(comptime config: FileConfig) type {
    return struct { safe_reports: u32, index: usize, char_buffer: CharBuffer(config), levels: Levels(config) };
}

fn FileContent(comptime config: FileConfig) type {
    return [config.filesize]u8;
}

fn Checker(comptime config: FileConfig) type {
    return fn (comptime config: FileConfig, levels: Levels(config)) bool;
}

fn readFile(comptime config: FileConfig) !FileContent(config) {
    var buffer: FileContent(config) = undefined;
    _ = try std.fs.cwd().readFile(config.filename, &buffer);
    return buffer;
}

fn getInteger(comptime config: FileConfig, char_buffer: CharBuffer(config), digit_count: usize) u8 {
    var integer: u8 = 0;
    const ascii_offset = 48;
    for (0..digit_count) |i| {
        const digit = char_buffer[i] - ascii_offset;
        const power: u8 = @intCast(digit_count - i - 1);
        const significand = std.math.pow(u8, 10, power);
        integer += @as(u8, digit) * significand;
    }
    return integer;
}

fn clearCharBuffer(comptime config: FileConfig, read_state: *ReadState(config)) void {
    read_state.index = 0;
}

fn addChar(comptime config: FileConfig, read_state: *ReadState(config), byte: u8) void {
    read_state.char_buffer[read_state.index] = byte;
    read_state.index += 1;
}

fn addLevel(comptime config: FileConfig, read_state: *ReadState(config), integer: u8) void {
    read_state.levels.values[read_state.levels.level_count] = integer;
    read_state.levels.level_count += 1;
}

fn clearLevels(comptime config: FileConfig, read_state: *ReadState(config)) void {
    read_state.levels.level_count = 0;
}

// So, a report only counts as safe if both of the following are true:
// 1. The levels are either all increasing or all decreasing.
// 2. Any two adjacent levels differ by at least one and at most three.
fn reportIsSafe(comptime config: FileConfig, levels: Levels(config)) bool {
    var last_level = levels.values[0];
    var all_increasing = true;
    var all_decreasing = true;

    for (1..levels.level_count) |i| {
        const level = levels.values[i];

        if (level > last_level) {
            all_decreasing = false;
        } else if (level < last_level) {
            all_increasing = false;
        }

        const change = @abs(@as(i16, level) - @as(i16, last_level));
        const is_safe_change = change >= 1 and change <= 3;
        if (!is_safe_change) {
            return false;
        }

        last_level = level;
    }

    return all_increasing or all_decreasing;
}

fn removeIndex(comptime config: FileConfig, levels: Levels(config), remove_index: usize) Levels(config) {
    var new_levels = Levels(config){ .values = undefined, .level_count = levels.level_count - 1 };
    var new_index: usize = 0;
    for (0..levels.level_count) |old_index| {
        if (old_index != remove_index) {
            new_levels.values[new_index] = levels.values[old_index];
            new_index += 1;
        }
    }
    return new_levels;
}

fn reportIsSafe2(comptime config: FileConfig, levels: Levels(config)) bool {
    for (0..levels.level_count) |index| {
        const new_levels = removeIndex(config, levels, index);
        if (reportIsSafe(config, new_levels)) {
            return true;
        }
    }

    return reportIsSafe(config, levels);
}

fn getNewReadState(comptime config: FileConfig) ReadState(config) {
    return ReadState(config){
        .safe_reports = 0,
        .index = 0,
        .char_buffer = undefined,
        .levels = Levels(config){ .values = undefined, .level_count = 0 },
    };
}

fn calculateSafeReports(comptime config: FileConfig, checker: Checker(config), content: *const FileContent(config)) u32 {
    var read_state = getNewReadState(config);

    for (content) |byte| {
        if (byte == config.level_separator or byte == config.report_separator) {
            const integer = getInteger(config, read_state.char_buffer, read_state.index);
            addLevel(config, &read_state, integer);

            if (byte == config.report_separator) {
                if (checker(config, read_state.levels)) {
                    read_state.safe_reports += 1;
                }
                clearLevels(config, &read_state);
            }

            clearCharBuffer(config, &read_state);
        } else {
            addChar(config, &read_state, byte);
        }
    }

    return read_state.safe_reports;
}

fn part(comptime config: FileConfig, checker: Checker(config)) !Result {
    var input_timer = try std.time.Timer.start();
    const content = try readFile(config);
    const input_duration = input_timer.lap() / 1000;

    var algorithm_timer = try std.time.Timer.start();
    const result = calculateSafeReports(config, checker, &content);
    const algorithm_duration = algorithm_timer.lap() / 1000;

    return Result{
        .input_duration = input_duration,
        .algorithm_duration = algorithm_duration,
        .assignment_result = result,
    };
}

fn getConfig() FileConfig {
    return FileConfig{ .level_separator = 32, .report_separator = 10, .filename = "2.txt", .filesize = 18943, .max_levels_per_report = 8, .max_digits_per_level = 2 };
}

pub fn part1() !Result {
    return part(getConfig(), reportIsSafe);
}

pub fn part2() !Result {
    return part(getConfig(), reportIsSafe2);
}
