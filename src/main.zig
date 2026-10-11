const std = @import("std");
const stb = @import("stb_image");

// Sample PNG image to be loaded directly in-memory
const sample_png_name = "zig-zero.png";
const sample_png = @embedFile(sample_png_name);

pub fn main(init: std.process.Init) !void {
    var buf: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &buf);
    const stdout: *std.Io.Writer = &stdout_writer.interface;
    defer stdout.flush() catch {};

    const args = try init.minimal.args.toSlice(init.gpa);
    defer init.gpa.free(args);

    if (args.len < 2) {
        try stdout.print("Usage:\n", .{});
        try stdout.print("  {s} <image file>.[jpg,png,git,tif,bmp]\n", .{args[0]});
        try stdout.print("\n", .{});
        try stdout.print("Supported formats: PNG, JPEG, TIFF, GIF, BMP, PSD, TGA\n", .{});
        return;
    }

    const filename = args[1];

    var image = try stb.load_image(filename, null);
    defer stb.free_image(&image);
    std.debug.print("Image: {s}\n", .{filename});
    std.debug.print("Got image of size {d}x{d} with {d} channels\n", .{ image.width, image.height, image.nchan });

    var image_mem = try stb.load_image_from_memory(sample_png);
    defer image_mem.deinit();

    std.debug.print("Image: Embedded PNG {s}\n", .{sample_png_name});
    std.debug.print("Got image of size {d}x{d} with {d} channels\n", .{ image_mem.width, image_mem.height, image_mem.nchan });
}
