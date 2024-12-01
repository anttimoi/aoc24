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
    integer_slices: Pair(Pair(usize)),
    heap_buffer_size: usize,
};

fn InputBuffer(comptime config: FileConfig) type {
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
        .integer_slices = Pair(Pair(usize)){
            .a = Pair(usize){
                .a = 0,
                .b = 5,
            },
            .b = Pair(usize){
                .a = 8,
                .b = 13,
            },
        },
    };
}

fn getSlice(comptime config: FileConfig, buffer: InputBuffer(config), slice: Pair(usize)) []const u8 {
    return buffer[slice.a..slice.b];
}

fn parseSlice(comptime config: FileConfig, buffer: InputBuffer(config), slice: Pair(usize)) !config.integer_type {
    return try std.fmt.parseInt(config.integer_type, getSlice(config, buffer, slice), config.integer_base);
}

fn setPair(comptime config: FileConfig, buffer: InputBuffer(config), arr: *ArrayPair(config), index: usize) !void {
    const a = try parseSlice(config, buffer, config.integer_slices.a);
    const b = try parseSlice(config, buffer, config.integer_slices.b);
    arr.a[index] = a;
    arr.b[index] = b;
}

fn readFile(comptime config: FileConfig) !ArrayPair(config) {
    var file = try std.fs.cwd().openFile(config.filename, .{});
    defer file.close();

    var buffer: InputBuffer(config) = undefined;
    var read_size: usize = 0;
    var index: usize = 0;

    var array_pair = ArrayPair(config){
        .a = undefined,
        .b = undefined,
    };

    while (true) {
        read_size = try file.read(&buffer);
        const is_eof = read_size == 0;
        if (is_eof) break;

        try setPair(config, buffer, &array_pair, index);
        index += 1;
    }

    return array_pair;
}

fn sort(comptime config: FileConfig, array: *ArrayPair(config)) void {
    std.mem.sort(config.integer_type, &array.a, {}, comptime std.sort.asc(config.integer_type));
    std.mem.sort(config.integer_type, &array.b, {}, comptime std.sort.asc(config.integer_type));
}

fn getDistances(comptime config: FileConfig, array: *ArrayPair(config)) DistanceArray(config) {
    var distances: DistanceArray(config) = undefined;

    for (0..config.rows_in_file) |i| {
        if (array.a[i] > array.b[i]) {
            distances[i] = array.a[i] - array.b[i];
        } else {
            distances[i] = array.b[i] - array.a[i];
        }
    }

    return distances;
}

fn getSum(comptime config: FileConfig, distances: *DistanceArray(config)) config.integer_type {
    var sum: config.integer_type = 0;

    for (0..config.rows_in_file) |i| {
        sum += distances[i];
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

fn integerIsNotInA(comptime config: FileConfig, integer: config.integer_type, array: ArrayPair(config)) bool {
    for (0..config.rows_in_file) |i| {
        if (array.a[i] == integer) {
            return false;
        }
    }

    return true;
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
    var distances = getDistances(config, &array_pair);
    const sum = getSum(config, &distances);
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
