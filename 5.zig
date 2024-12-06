const std = @import("std");
const common = @import("common.zig");

const File = common.File;
const Result = common.Result;
const readFile = common.readFile;
const parseInteger = common.parseInteger;

const SortRule = struct {
    first: u8,
    second: u8,
};

fn Input(comptime file_config: FileConfig) type {
    return struct {
        rules: [file_config.sort_rule_count]SortRule,
        lists: [file_config.list_count][file_config.max_list_length]u8,
    };
}

const FileConfig = struct {
    file: File,
    rule_size: usize,
    sort_rule_count: usize,
    list_count: usize,
    max_list_length: usize,
};

fn SortContext(comptime file_config: FileConfig) type {
    return struct {
        rules: [file_config.sort_rule_count]SortRule,
    };
}

fn Counter(comptime file_config: FileConfig) type {
    return fn (comptime file_config: FileConfig, input: Input(file_config), index: usize) u32;
}

fn getFileConfig(comptime file: File, comptime sort_rule_count: usize, comptime total_rows: usize, comptime rule_size: usize, comptime max_list_length: usize) FileConfig {
    return FileConfig{
        .file = file,
        .sort_rule_count = sort_rule_count,
        .list_count = total_rows - sort_rule_count - 1,
        .rule_size = rule_size,
        .max_list_length = max_list_length,
    };
}

fn getRuleSlice(comptime config: FileConfig, bytes: *const [config.file.size]u8, index: usize) [config.rule_size]u8 {
    var slice: [config.rule_size]u8 = undefined;
    for (0..config.rule_size) |i| {
        slice[i] = bytes[(index * config.rule_size) + i];
    }

    return slice;
}

fn parseRuleSlice(comptime config: FileConfig, slice: [config.rule_size]u8) SortRule { // TODO
    const mid = config.rule_size / 2;
    const firstInteger = slice[0 .. mid - 1];
    const secondInteger = slice[mid .. config.rule_size - 1];

    return SortRule{
        .first = parseInteger(u8, firstInteger),
        .second = parseInteger(u8, secondInteger),
    };
}

fn readInput(comptime config: FileConfig) !Input(config) {
    var input = Input(config){
        .rules = undefined,
        .lists = undefined,
    };

    const bytes = try readFile(config.file);

    for (0..config.sort_rule_count) |i| {
        const rule_slice = getRuleSlice(config, &bytes, i);
        const rule = parseRuleSlice(config, rule_slice);
        input.rules[i] = rule;
    }

    const list_start_index = config.sort_rule_count * config.rule_size + 1;
    var current_list_index: usize = 0;
    var list_index: usize = 0;

    const integer_size = 3;
    const total_integer_count = (config.file.size - config.sort_rule_count * config.rule_size) / integer_size;
    const last_index = total_integer_count - 1;

    for (0..total_integer_count) |i| {
        const slice_start = list_start_index + i * integer_size;
        const slice_end = slice_start + integer_size - 1;
        const terminator = if (i == last_index) 10 else bytes[slice_end];
        const digits = bytes[slice_start..slice_end];
        const integer = parseInteger(u8, digits);

        std.debug.assert(list_index < config.max_list_length);
        input.lists[current_list_index][list_index] = integer;
        list_index += 1;

        if (terminator == 10) {
            current_list_index += 1;
            list_index = 0;
        }
    }
    return input;
}

pub fn sort(comptime config: FileConfig) fn (context: SortContext(config), u8, u8) bool {
    return struct {
        pub fn inner(context: SortContext(config), a: u8, b: u8) bool {
            for (context.rules) |rule| {
                if (a == rule.first and b == rule.second) {
                    return true;
                } else if (a == rule.second and b == rule.first) {
                    return false;
                }
            }

            if (a == 0) {
                return false;
            } else if (b == 0) {
                return true;
            }

            return a < b;
        }
    }.inner;
}

fn lenWithoutZeroes(comptime base_len: usize, list: *const [base_len]u8) usize {
    var count: u8 = 0;
    for (0..list.len) |i| {
        if (list[i] != 0) {
            count += 1;
        }
    }
    return count;
}

fn sortAndGetMiddlePageNumber(comptime config: FileConfig, list: *const [config.max_list_length]u8, rules: [config.sort_rule_count]SortRule) u8 {
    const context = SortContext(config){ .rules = rules };
    std.sort.pdq(u8, @constCast(list), context, sort(config));

    const true_length = lenWithoutZeroes(list.len, list);
    return list[true_length / 2];
}

fn isInRightOrder(comptime config: FileConfig, list: *const [config.max_list_length]u8, rules: [config.sort_rule_count]SortRule) bool {
    const len = lenWithoutZeroes(list.len, list);

    for (1..len) |i| {
        const a = list[i - 1];
        const b = list[i];

        for (rules) |rule| {
            if (a == rule.first and b == rule.second) {
                continue;
            } else if (a == rule.second and b == rule.first) {
                return false;
            }
        }
    }

    return true;
}

fn getMiddlePageNumber(comptime config: FileConfig, list: *const [config.max_list_length]u8) u8 {
    const len = lenWithoutZeroes(list.len, list);
    return list[len / 2];
}

fn counter1(comptime config: FileConfig, input: Input(config), index: usize) u32 {
    if (isInRightOrder(config, &input.lists[index], input.rules)) {
        return getMiddlePageNumber(config, &input.lists[index]);
    }
    return 0;
}

fn counter2(comptime config: FileConfig, input: Input(config), index: usize) u32 {
    if (!isInRightOrder(config, &input.lists[index], input.rules)) {
        return sortAndGetMiddlePageNumber(config, &input.lists[index], input.rules);
    }
    return 0;
}

fn countMiddlePageNumbers(comptime config: FileConfig, input: Input(config), counter: Counter(config)) u32 {
    var count: u32 = 0;
    for (0..input.lists.len) |i| {
        count += counter(config, input, i);
    }
    return count;
}

fn getConfig() FileConfig {
    return getFileConfig(File{
        .name = "5.txt",
        .size = 15142,
    }, 1176, 1366, 6, 23);
}

fn part(comptime config: FileConfig, counter: Counter(config)) !Result {
    var input_timer = try std.time.Timer.start();
    const input = try readInput(config);
    const input_duration = input_timer.lap() / 1000;

    var algorithm_timer = try std.time.Timer.start();
    const result = countMiddlePageNumbers(config, input, counter);
    const algorithm_duration = algorithm_timer.lap() / 1000;

    return Result{ .input_duration = input_duration, .algorithm_duration = algorithm_duration, .assignment_result = result };
}

pub fn part1() !Result {
    return part(getConfig(), counter1);
}

pub fn part2() !Result {
    return part(getConfig(), counter2);
}
