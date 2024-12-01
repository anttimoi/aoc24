const std = @import("std");
const common = @import("common.zig");

const Pair = common.Pair;
const Result = common.Result;

const FileConfig = struct {
    integer_type: type,
    integer_base: u8,
    bytes_per_row: usize,
    rows_in_file: usize,
    filename: []const u8,
    integer_digits: u8, // Number of digits in an integer
    integer_gap: u8, // Gap between two integers in a row
    heap_buffer_size: usize,
};

fn InputBuffer(comptime config: FileConfig) type {
    return [config.bytes_per_row * config.rows_in_file]u8;
}

fn RowBuffer(comptime config: FileConfig) type {
    return [config.bytes_per_row]u8;
}

fn ArrayPair(comptime config: FileConfig) type {
    return Pair([config.rows_in_file]config.integer_type);
}

fn DistanceArray(comptime config: FileConfig) type {
    return [config.rows_in_file]config.integer_type;
}

fn HeapBuffer(comptime config: FileConfig) type {
    return [config.heap_buffer_size]u8;
}

fn getConfig() FileConfig {
    return FileConfig{
        .integer_type = u32,
        .integer_base = 10,
        .bytes_per_row = 14,
        .rows_in_file = 1000,
        .filename = "1.txt",
        .heap_buffer_size = 20000, // Don't know how to calculate exact value but its something between 10k and 20k
        .integer_digits = 5,
        .integer_gap = 3,
    };
}

fn parseRow(comptime config: FileConfig, buffer: *InputBuffer(config), index_offset: usize) config.integer_type {
    const ascii_offset: u8 = 48;
    var result: usize = 0;
    for (0..config.integer_digits) |i| {
        const index = config.integer_digits - i - 1 + index_offset;
        const digit_char = buffer[index];
        const digit = digit_char - ascii_offset;
        result += @as(usize, digit) * std.math.pow(usize, 10, i);
    }
    return @intCast(result);
}

fn setPair(comptime config: FileConfig, input: *InputBuffer(config), output: *ArrayPair(config), row_index: usize) void {
    const row_offset = row_index * config.bytes_per_row;
    const second_integer_offset = config.integer_digits + config.integer_gap;

    const a = parseRow(config, input, row_offset);
    const b = parseRow(config, input, second_integer_offset + row_offset);

    output.a[row_index] = a;
    output.b[row_index] = b;
}

fn readFile(comptime config: FileConfig) !ArrayPair(config) {
    var buffer: InputBuffer(config) = undefined;
    _ = try std.fs.cwd().readFile(config.filename, &buffer);

    var array_pair = ArrayPair(config){
        .a = undefined,
        .b = undefined,
    };

    for (0..config.rows_in_file) |row_index| {
        setPair(config, &buffer, &array_pair, row_index);
    }

    return array_pair;
}

fn sort(comptime config: FileConfig, array: *ArrayPair(config)) void {
    std.mem.sort(config.integer_type, &array.a, {}, comptime std.sort.asc(config.integer_type));
    std.mem.sort(config.integer_type, &array.b, {}, comptime std.sort.asc(config.integer_type));
}

fn getDistanceSum(comptime config: FileConfig, array: *ArrayPair(config)) config.integer_type {
    var sum: config.integer_type = 0;

    for (0..config.rows_in_file) |i| {
        if (array.a[i] > array.b[i]) {
            sum += array.a[i] - array.b[i];
        } else {
            sum += array.b[i] - array.a[i];
        }
    }

    return sum;
}

fn countOccurence(comptime config: FileConfig, integer: config.integer_type, array: ArrayPair(config)) u64 {
    var count: u64 = 0;

    for (0..config.rows_in_file) |i| {
        if (array.b[i] == integer) {
            count += @intCast(integer);
        }
    }

    return count;
}

fn getOccurenceCounts(comptime config: FileConfig, heap_buffer: *HeapBuffer(config), array: ArrayPair(config)) !std.AutoHashMap(config.integer_type, config.integer_type) {
    var fba = std.heap.FixedBufferAllocator.init(heap_buffer);
    const allocator = fba.allocator();
    var map = std.AutoHashMap(config.integer_type, config.integer_type).init(allocator);

    for (0..config.rows_in_file) |i| {
        const integer = array.b[i];
        const old = map.get(integer) orelse 0;
        try map.put(integer, old + 1);
    }

    return map;
}

fn countOccurences(comptime config: FileConfig, heap_buffer: *HeapBuffer(config), array: ArrayPair(config)) !config.integer_type {
    var sum: config.integer_type = 0;

    const occurenceCounts = try getOccurenceCounts(config, heap_buffer, array);

    for (0..config.rows_in_file) |i| {
        const integer = array.a[i];
        const occurences = occurenceCounts.get(integer) orelse 0;
        sum += integer * occurences;
    }

    return sum;
}

pub fn part1() !Result {
    const config = getConfig();
    var input_timer = try std.time.Timer.start();
    var array_pair = try readFile(config);
    const input_duration = input_timer.lap() / 1000;

    var algorithm_timer = try std.time.Timer.start();
    sort(config, &array_pair);
    const sum = getDistanceSum(config, &array_pair);
    const algorithm_duration = algorithm_timer.lap() / 1000;

    return common.Result{
        .input_duration = input_duration,
        .algorithm_duration = algorithm_duration,
        .assignment_result = @intCast(sum),
    };
}

pub fn part2() !Result {
    const config = getConfig();
    var input_timer = try std.time.Timer.start();
    const array_pair = try readFile(config);
    const input_duration = input_timer.lap() / 1000;

    var algorithm_timer = try std.time.Timer.start();
    var heap_buffer: HeapBuffer(config) = undefined;
    const result = try countOccurences(config, &heap_buffer, array_pair);
    const algorithm_duration = algorithm_timer.lap() / 1000;

    return common.Result{
        .input_duration = input_duration,
        .algorithm_duration = algorithm_duration,
        .assignment_result = @as(u64, result),
    };
}
