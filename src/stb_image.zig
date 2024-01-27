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
pub fn load_image(options: struct {
    filename: []const u8,
    desired_channels: usize = 0,
}) !Image {
    var img = Image{};

    const filename_c = @as([*c]const u8, &options.filename[0]);
    const iptr: usize = @intFromPtr(c.stbi_load(
        filename_c,
        @as([*c]i32, &img.width),
        @as([*c]i32, &img.height),
        @as([*c]i32, &img.nchan),
        @intCast(options.desired_channels),
    ));
    if (iptr == 0) {
        log.err("Error loading image {s} - check that the file exists at the given path", .{options.filename});
        return error.LoadError;
    }

    img.data = @ptrFromInt(iptr);
    return img;
}

/// Load an image from raw bytes in memory
pub fn load_image_from_memory(options: struct {
    buf: []const u8,
    desired_channels: usize = 0,
}) !Image {
    var img = Image{};
    const iptr: usize = @intFromPtr(c.stbi_load_from_memory(
        @as([*c]const u8, &options.buf[0]),
        @intCast(options.buf.len),
        @as([*c]i32, &img.width),
        @as([*c]i32, &img.height),
        @as([*c]i32, &img.nchan),
        @intCast(options.desired_channels),
    ));

    if (iptr == 0) {
        log.err("Error loading image from memory - unsupported format or corrupted data?", .{});
        return error.LoadError;
    }

    img.data = @ptrFromInt(iptr);
    return img;
}

/// Free the data associated with an Image
pub fn free_image(image: *Image) void {
    image.deinit();
}
