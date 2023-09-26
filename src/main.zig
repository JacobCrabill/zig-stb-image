const std = @import("std");
const stb = @import("stb_image.zig");
const c = @cImport({
    @cInclude("stb/stb_image.h");
});

const Allocator = std.mem.Allocator;
const stdout = std.io.getStdOut().writer();

// Sample PNG image to be loaded directly in-memory
const sample_png_name = "zig-zero.png";
const sample_png = @embedFile(sample_png_name);

pub fn main() !void {
    var alloc = std.heap.page_allocator;
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

    var image = stb.load_image(filename);
    defer stb.free_image_optional(&image);
    if (image) |img| {
        std.debug.print("Image: {s}\n", .{filename});
        std.debug.print("Got image of size {d}x{d} with {d} channels\n", .{ img.width, img.height, img.nchan });
    } else {
        std.debug.print("Error loading {s}\n", .{filename});
    }

    var image_mem = stb.load_image_from_memory(sample_png);
    if (image_mem) |*img| {
        std.debug.print("Image: Embedded PNG {s}\n", .{sample_png_name});
        std.debug.print("Got image of size {d}x{d} with {d} channels\n", .{ img.width, img.height, img.nchan });
        img.deinit();
    } else {
        std.debug.print("Error loading image from memory\n", .{});
    }
}
