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
