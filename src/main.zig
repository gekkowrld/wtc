const std = @import("std");
const zigstr = @import("zigstr");

// The commit messages from:
//      https://github.com/ngerakines/commitment/blob/main/commit_messages.txt
const cmsg = @embedFile("cmsg.txt");

const default_names = [_][]const u8{ "Ali", "Andy", "April", "Brannon", "Chris", "Cord", "Dan", "Darren", "David", "Edy", "Ethan", "Fanny", "Gabe", "Ganesh", "Greg", "Guillaume", "James", "Jason", "Jay", "Jen", "John", "Kelan", "Kim", "Lauren", "Marcus", "Matt", "Matthias", "Mattie", "Mike", "Nate", "Nick", "Pasha", "Patrick", "Paul", "Preston", "Qi", "Rachel", "Rainer", "Randal", "Ryan", "Sarah", "Stephen", "Steve", "Steven", "Sunakshi", "Todd", "Tom", "Tony" };

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();

    const arena = arena_instance.allocator();
    const strs = try split_string(arena, cmsg);

    const data = try zigstr.Data.init(arena);
    var rstr = try zigstr.fromConstBytes(arena, &data, random_str(strs));
    defer rstr.deinit();

    if (rstr.contains("XNAMEX")) {
        _ = try rstr.replace("XNAMEX", random_str(@constCast(&default_names)));
    } else if (rstr.contains("XUPPERNAMEX")) {
        _ = try rstr.replace("XUPPERNAMEX", random_str(@constCast(&default_names)));
        try rstr.toUpper();
    } else if (rstr.contains("XLOWERNAMEX")) {
        _ = try rstr.replace("XLOWERNAMEX", random_str(@constCast(&default_names)));
        try rstr.toLower();
    } else if (rstr.contains("XNUM")) {
        const xn = "XNUM";
        var start: u64 = 0;
        var end: u64 = 999;
        var index: isize = @intCast(std.mem.indexOf(u8, rstr.bytes(), xn).?); // Fail
        var srange = std.ArrayList(u8).init(arena);
        var new_str = std.ArrayList(u8).init(arena);

        var i: isize = 0;
        while (i < index) {
            try new_str.append(try rstr.byteAt(i));
            i += 1;
        }

        index += xn.len;

        while (index < rstr.byteLen()){
            const cc = try rstr.byteAt(index);
            if (cc == 'X') {
                index += 1;
                break;
            }

            try srange.append(cc);
            index += 1;
        }

        if (rstr.contains(",")) {
        var ssr = std.mem.splitSequence(u8, try srange.toOwnedSlice(), ",");
        start = std.fmt.parseInt(u64, ssr.first(), 10) catch start;
        end = std.fmt.parseInt(u64, ssr.next() orelse "999", 10) catch end;
        }else {
            const v = std.fmt.parseInt(u64, try srange.toOwnedSlice(), 10) catch start;
            start = v;
            end = v;
        }

        const stx = try std.fmt.allocPrint(arena, "{d}", .{std.crypto.random.intRangeAtMost(u64, start, end)});

        for (stx) |sx| {
            try new_str.append(sx);
        }

        while (index < rstr.byteLen()) {
            try new_str.append(try rstr.byteAt(index));
            index += 1;
        }

        try rstr.reset(try new_str.toOwnedSlice());
    }

    std.debug.print("{}", .{rstr});
}

fn u64_to_bytes(value: u64) []u8 {
    var buffer: [8]u8 = undefined;
    std.mem.copy(u8, &buffer, &value);
    return buffer[0..8]; // returns a slice of 8 bytes
}

fn split_string(allocator: std.mem.Allocator, str: []const u8) ![][]u8 {
    var strs = std.ArrayList([]u8).init(allocator);
    var st = std.ArrayList(u8).init(allocator);

    for (str) |s| {
        if (s == '\n') {
            try strs.append(try st.toOwnedSlice());
            continue;
        }
        try st.append(s);
    }

    return strs.toOwnedSlice();
}

fn random_str(msgs: [][]const u8) []const u8 {
    return msgs[std.crypto.random.intRangeAtMost(usize, 0, msgs.len-1)];
}
