const std = @import("std");
const stb = @import("stb_image");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len < 2) {
        try stdout.print("Usage:\n", .{});
        try stdout.print("  {s} <image file>.[jpg,png,git,tif,bmp]\n", .{args[0]});
        try stdout.print("\n", .{});
        try stdout.print("Supported formats: PNG, JPEG, TIFF, GIF, BMP, PSD, TGA\n", .{});
        return;
    }

    const filename = args[1];

    var image = try stb.load_image(filename);
    defer image.deinit();
    std.debug.print("Image: {s}\n", .{filename});
    std.debug.print("Got image of size {d}x{d} with {d} channels\n", .{ image.width, image.height, image.nchan });
}
