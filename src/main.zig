const std = @import("std");
const c = @cImport({
    @cInclude("stb/stb_image.h");
});

const Allocator = std.mem.Allocator;
const stdout = std.io.getStdOut().writer();

const os = std.os;

pub fn main() !void {
    var alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len < 2) {
        try stdout.print("Usage:\n", .{});
        try stdout.print("  {s} <image file>.[jpg,png,git,tif,bmp]\n", .{args[0]});
        try stdout.print("\n", .{});
        try stdout.print("Supported formats: PNG, JPEG, TIFF, GIF, BMP, PSD, TGA\n", .{});
        os.exit(0);
    }

    const filename = args[1];

    var x: i32 = 0;
    var y: i32 = 0;
    var n: i32 = 0;
    var data: [*]u8 = c.stbi_load(@as([*c]u8, filename), @as([*c]i32, &x), @as([*c]i32, &y), @as([*c]i32, &n), 0);
    defer c.stbi_image_free(data);

    // Note that we're using the C header directly, so no zig-level error handling (you're on your own there)
    if (data[0] == 0) {
        // Actually we can't hit this path(?), as Zig will panic when crossing the C/Zig ABI boundary
        // (cannot cast "null" to a valid Zig pointer)
        try stdout.print("ERROR: Failed to load file '{s}'\n", .{filename});
        os.exit(1);
    }

    std.debug.print("Image: {s}\n", .{filename});
    std.debug.print("Got image of size {d}x{d} with {d} channels\n", .{ x, y, n });
}
