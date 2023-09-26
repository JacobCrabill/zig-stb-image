const std = @import("std");
const c = @cImport({
    @cInclude("stb/stb_image.h");
});

const log = std.log.scoped(.stb_image);

/// Basic representation of an image
pub const Image = struct {
    width: i32 = 0,
    height: i32 = 0,
    nchan: i32 = 0,
    data: [*]u8 = undefined,

    pub fn deinit(self: *Image) void {
        c.stbi_image_free(self.data);
        self.width = 0;
        self.height = 0;
        self.nchan = 0;
        self.data = undefined;
        self.* = undefined;
    }
};

/// Load an image from a file
pub fn load_image(filename: []const u8) ?Image {
    var img = Image{};

    const filename_c = @as([*c]const u8, &filename[0]);
    const iptr: usize = @intFromPtr(c.stbi_load(filename_c, @as([*c]i32, &img.width), @as([*c]i32, &img.height), @as([*c]i32, &img.nchan), 0));
    if (iptr == 0) {
        log.err("Error loading image {s} - check that the file exists at the given path", .{filename});
        return null;
    }

    img.data = @ptrFromInt(iptr);
    return img;
}

/// Load an image from raw bytes in memory
pub fn load_image_from_memory(buf: []const u8) ?Image {
    var img = Image{};
    const iptr: usize = @intFromPtr(c.stbi_load_from_memory(@as([*c]const u8, &buf[0]), @intCast(buf.len), @as([*c]i32, &img.width), @as([*c]i32, &img.height), @as([*c]i32, &img.nchan), 0));

    if (iptr == 0) {
        log.err("Error loading image from memory - unsupported format or corrupted data?", .{});
        return null;
    }

    img.data = @ptrFromInt(iptr);
    return img;
}

/// Free the data associated with an Image
pub fn free_image(image: *Image) void {
    image.deinit();
}

/// Free the data associated with an Image, if it exists
/// Helper function to play nicely with the optional return values of load_image*
/// Example:
///   var image = stb.load_image(filename);
///   defer stb.free_image_optional(&image);
pub fn free_image_optional(image: *?Image) void {
    if (image.*) |*img| {
        img.deinit();
    }
}
