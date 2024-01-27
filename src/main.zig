const std = @import("std");
const stb = @import("stb_image.zig");
const c = @cImport({
    @cInclude("stb/stb_image.h");
});

const Allocator = std.mem.Allocator;

// Sample PNG image to be loaded directly in-memory
const sample_png_name = "zig-zero.png";
const sample_png = @embedFile(sample_png_name);

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len < 2) {
        std.debug.print("Usage:\n", .{});
        std.debug.print("  {s} <image file>.[jpg,png,git,tif,bmp]\n", .{args[0]});
        std.debug.print("\n", .{});
        std.debug.print("Supported formats: PNG, JPEG, TIFF, GIF, BMP, PSD, TGA\n", .{});
        return;
    }

    const filename = args[1];

    var image = try stb.load_image(.{ .filename = filename });
    defer stb.free_image(&image);
    std.debug.print("Image: {s}\n", .{filename});
    std.debug.print("Got image of size {d}x{d} with {d} channels\n", .{ image.width, image.height, image.nchan });

    var image_mem = try stb.load_image_from_memory(.{ .buf = sample_png });
    defer image_mem.deinit();

    std.debug.print("Image: Embedded PNG {s}\n", .{sample_png_name});
    std.debug.print("Got image of size {d}x{d} with {d} channels\n", .{ image_mem.width, image_mem.height, image_mem.nchan });
}
