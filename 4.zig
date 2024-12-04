const std = @import("std");
const common = @import("common.zig");

const File = common.File;
const FileContent = common.FileContent;
const Result = common.Result;

const Dimensions = struct {
    rows: u16,
    columns: u16,
};

const Coordinate = struct {
    x: i32,
    y: i32,
};

const Direction = struct {
    x: i8,
    y: i8,
};

const FileConfig = struct {
    file: File,
    dimensions: Dimensions,
};

fn FileContentDims(comptime dims: Dimensions) type {
    return [dims.rows * dims.columns]u8;
}

fn mapCoordinateToIndex(comptime dims: Dimensions, coord: Coordinate) ?usize {
    if (coord.x >= dims.columns or coord.y >= dims.rows or coord.x < 0 or coord.y < 0) {
        return null;
    }

    return @intCast(coord.y * dims.columns + coord.x);
}

inline fn isMatch(comptime dims: Dimensions, comptime size: usize, pattern: *const [size][size]?u8, start: Coordinate, file: *const FileContentDims(dims)) bool {
    for (0.., pattern) |x_offset, row| {
        for (0.., row) |y_offset, char| {
            if (char == null) {
                continue;
            }

            const x_off: i32 = @intCast(x_offset);
            const y_off: i32 = @intCast(y_offset);
            const coord = Coordinate{ .x = start.x + x_off, .y = start.y + y_off };
            const i = mapCoordinateToIndex(dims, coord);
            if (i == null) {
                return false;
            }

            if (file[i.?] != char.?) {
                return false;
            }
        }
    }

    return true;
}

fn findMatches(comptime dims: Dimensions, comptime pattern_count: usize, comptime pattern_size: usize, patterns: [pattern_count][pattern_size][pattern_size]?u8, file: *const FileContentDims(dims)) u32 {
    var match_count: u32 = 0;

    for (0..patterns.len) |pattern_index| {
        const pattern: [pattern_size][pattern_size]?u8 = patterns[pattern_index];
        for (0..(dims.rows - pattern_size)) |i| {
            for (0..(dims.columns - pattern_size)) |j| {
                const coord = Coordinate{ .x = @intCast(j), .y = @intCast(i) };
                if (isMatch(dims, pattern_size, &pattern, coord, file)) {
                    match_count += 1;
                }
            }
        }
    }

    return match_count;
}

fn removeNewlines(comptime config: FileConfig, file: *const FileContent(config.file)) FileContentDims(config.dimensions) {
    var result: FileContentDims(config.dimensions) = undefined;

    var target_index: usize = 0;
    var source_index: usize = 0;
    while (source_index < config.file.size) : (source_index += 1) {
        if (file[source_index] != '\n') {
            result[target_index] = file[source_index];
            target_index += 1;
        }
    }

    return result;
}

pub fn part(comptime size: usize, comptime pattern_count: usize, comptime patterns: [pattern_count][size][size]?u8) !Result {
    const config = FileConfig{
        .file = File{
            .name = "4.txt",
            .size = 19740,
        },
        .dimensions = .{
            .rows = 140,
            .columns = 141, // Newline is the last character in each row
        },
    };

    var input_timer = try std.time.Timer.start();
    const contents = try common.readFile(config.file);
    const input_duration = input_timer.lap() / 1000;

    var algorithm_timer = try std.time.Timer.start();
    const result = findMatches(config.dimensions, pattern_count, size, patterns, &contents);
    const algorithm_duration = algorithm_timer.lap() / 1000;

    return Result{ .input_duration = input_duration, .algorithm_duration = algorithm_duration, .assignment_result = result };
}

pub fn part1() !Result {
    const size = 4;

    const patterns = [_][size][size]?u8{
        [size][size]?u8{
            [size]?u8{ 'X', 'M', 'A', 'S' },
            [size]?u8{ null, null, null, null },
            [size]?u8{ null, null, null, null },
            [size]?u8{ null, null, null, null },
        },
        [size][size]?u8{
            [size]?u8{ 'S', 'A', 'M', 'X' },
            [size]?u8{ null, null, null, null },
            [size]?u8{ null, null, null, null },
            [size]?u8{ null, null, null, null },
        },
        [size][size]?u8{
            [size]?u8{ 'X', null, null, null },
            [size]?u8{ 'M', null, null, null },
            [size]?u8{ 'A', null, null, null },
            [size]?u8{ 'S', null, null, null },
        },
        [size][size]?u8{
            [size]?u8{ 'S', null, null, null },
            [size]?u8{ 'A', null, null, null },
            [size]?u8{ 'M', null, null, null },
            [size]?u8{ 'X', null, null, null },
        },
        [size][size]?u8{
            [size]?u8{ 'X', null, null, null },
            [size]?u8{ null, 'M', null, null },
            [size]?u8{ null, null, 'A', null },
            [size]?u8{ null, null, null, 'S' },
        },
        [size][size]?u8{
            [size]?u8{ 'S', null, null, null },
            [size]?u8{ null, 'A', null, null },
            [size]?u8{ null, null, 'M', null },
            [size]?u8{ null, null, null, 'X' },
        },
        [size][size]?u8{
            [size]?u8{ null, null, null, 'S' },
            [size]?u8{ null, null, 'A', null },
            [size]?u8{ null, 'M', null, null },
            [size]?u8{ 'X', null, null, null },
        },
        [size][size]?u8{
            [size]?u8{ null, null, null, 'X' },
            [size]?u8{ null, null, 'M', null },
            [size]?u8{ null, 'A', null, null },
            [size]?u8{ 'S', null, null, null },
        },
    };

    return part(size, patterns.len, patterns);
}

pub fn part2() !Result {
    const size = 3;

    const patterns = [_][size][size]?u8{
        [size][size]?u8{
            [size]?u8{ 'M', null, 'S' },
            [size]?u8{ null, 'A', null },
            [size]?u8{ 'M', null, 'S' },
        },
        [size][size]?u8{
            [size]?u8{ 'S', null, 'S' },
            [size]?u8{ null, 'A', null },
            [size]?u8{ 'M', null, 'M' },
        },
        [size][size]?u8{
            [size]?u8{ 'S', null, 'M' },
            [size]?u8{ null, 'A', null },
            [size]?u8{ 'S', null, 'M' },
        },
        [size][size]?u8{
            [size]?u8{ 'M', null, 'M' },
            [size]?u8{ null, 'A', null },
            [size]?u8{ 'S', null, 'S' },
        },
    };

    return part(size, patterns.len, patterns);
}
