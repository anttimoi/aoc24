const std = @import("std");
const Result = @import("common.zig").Result;

const Instruction = struct {
    name: []const u8,
    value: bool,
};

const EnableInstructionResult = struct {
    index: usize,
    enable: bool,
};

const MulInstructionResult = struct {
    index: usize,
    result: u32,
};

const FileConfig = struct {
    filename: []const u8,
    filesize: usize,
    mul_header: []const u8,
    do_instruction: Instruction,
    dont_instruction: Instruction,
};

const IntegerResult = struct {
    integer: ?u32,
    indexes_traversed: usize,
};

fn FileContent(comptime config: FileConfig) type {
    return [config.filesize]u8;
}

fn readFile(comptime config: FileConfig) !FileContent(config) {
    var buffer: FileContent(config) = undefined;
    _ = try std.fs.cwd().readFile(config.filename, &buffer);
    return buffer;
}

fn matchesReference(comptime reference: []const u8, array: [reference.len]u8) bool {
    for (0..array.len) |i| {
        if (array[i] != reference[i]) {
            return false;
        }
    }
    return true;
}

fn getSlice(comptime config: FileConfig, comptime len: usize, buffer: *const FileContent(config), index: usize) [len]u8 {
    var arr: [len]u8 = undefined;

    for (0..len) |i| {
        arr[i] = buffer[index + i];
    }

    return arr;
}

fn isMulHeader(comptime config: FileConfig, buffer: [config.mul_header.len]u8) bool {
    return matchesReference(config.mul_header, buffer);
}

fn getMulSlice(comptime config: FileConfig, buffer: *const FileContent(config), index: usize) [config.mul_header.len]u8 {
    return getSlice(config, config.mul_header.len, buffer, index);
}

fn findInteger(comptime config: FileConfig, buffer: *const FileContent(config), start_index: usize, terminator: u8) IntegerResult {
    var integer: u32 = 0;
    var index = start_index;

    while (index < config.filesize) {
        const char = buffer[index];

        if (char >= 48 and char <= 57) {
            const digit = char - 48;
            integer = integer * 10 + digit;
        } else if (char == terminator) {
            return IntegerResult{
                .integer = integer,
                .indexes_traversed = index - start_index + 1,
            };
        } else {
            return IntegerResult{
                .integer = null,
                .indexes_traversed = index - start_index, // Leave unknown char as untraversed
            };
        }

        index += 1;
    }

    return IntegerResult{
        .integer = null,
        .indexes_traversed = index - start_index + 1,
    };
}

fn handleEnableInstruction(comptime config: FileConfig, comptime instruction: Instruction, buffer: *const FileContent(config), index: usize) ?EnableInstructionResult {
    if (buffer[index] == instruction.name[0]) {
        const slice = getSlice(config, instruction.name.len, buffer, index);

        if (matchesReference(instruction.name, slice)) {
            return EnableInstructionResult{
                .index = index + instruction.name.len,
                .enable = instruction.value,
            };
        }
    }

    return null;
}

fn handleMulInstruction(comptime config: FileConfig, buffer: *const FileContent(config), index: usize) ?MulInstructionResult {
    const window_size = config.mul_header.len;

    if (buffer[index] == config.mul_header[0]) {
        const slice = getMulSlice(config, buffer, index);
        if (isMulHeader(config, slice)) {
            var new_index = index + window_size;

            const result_1 = findInteger(config, buffer, new_index, ',');
            new_index += result_1.indexes_traversed;
            if (result_1.integer == null) {
                return MulInstructionResult{
                    .index = new_index,
                    .result = 0,
                };
            }

            const result_2 = findInteger(config, buffer, new_index, ')');
            new_index += result_2.indexes_traversed;
            if (result_2.integer == null) {
                return MulInstructionResult{
                    .index = new_index,
                    .result = 0,
                };
            }

            return MulInstructionResult{
                .index = new_index,
                .result = result_1.integer.? * result_2.integer.?,
            };
        }
    }

    return null;
}

fn parse(comptime config: FileConfig, comptime force_enable: bool, buffer: *const FileContent(config)) u32 {
    var result: u32 = 0;
    var index: usize = 0;
    var enable: bool = true;

    while (index < config.filesize) {
        if (force_enable or enable) {
            const mul_result = handleMulInstruction(config, buffer, index);
            if (mul_result != null) {
                index = mul_result.?.index;
                result = result + mul_result.?.result;
                continue;
            }
        }

        if (!force_enable) {
            const do_result = handleEnableInstruction(config, config.do_instruction, buffer, index);
            if (do_result != null) {
                enable = do_result.?.enable;
                index = do_result.?.index;
                continue;
            }

            const dont_result = handleEnableInstruction(config, config.dont_instruction, buffer, index);
            if (dont_result != null) {
                enable = dont_result.?.enable;
                index = dont_result.?.index;
                continue;
            }
        }

        index += 1;
    }

    return result;
}

pub fn part(comptime force_enable: bool) !Result {
    const config = FileConfig{
        .filename = "3.txt",
        .filesize = 19499,
        .mul_header = "mul(",
        .do_instruction = .{ .name = "do()", .value = true },
        .dont_instruction = .{ .name = "don't()", .value = false },
    };

    var input_timer = try std.time.Timer.start();
    const content = try readFile(config);
    const input_duration = input_timer.lap() / 1000;

    var algorithm_timer = try std.time.Timer.start();
    const result = parse(config, force_enable, &content);
    const algorithm_duration = algorithm_timer.lap() / 1000;

    return Result{
        .input_duration = input_duration,
        .algorithm_duration = algorithm_duration,
        .assignment_result = result,
    };
}

pub fn part1() !Result {
    return part(true);
}

pub fn part2() !Result {
    return part(false);
}
