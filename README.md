# Zig-STB-Image

Zig build of the
[STB image library](https://github.com/nothings/stb/blob/5736b15f7ea0ffb08dd38af21067c314d6a3aae9/stb_image.h).

The definitions have been split out of the header file and into a C source file, allowing Zig to
include the header w/o needing to transpile the entire library (instead, the C compiler is used to
compile it into a static library that Zig can link to).

# Getting started

## Package Manager (build.zig.zon)

Create a `build.zig.zon` in your project (replace LATEST_COMMIT with the latest commit hash):

```
.{
    .name = "mypkg",
    .version = "0.1.0",
    .dependencies = .{
        .zig_stb_image = .{
            .url = "https://github.com/JacobCrabill/zig-stb-image/archive/LATEST_COMMIT.tar.gz",
        },
    },
    .paths = {},
}
```

Run zig build in your project, and the compiler will instruct you to add a `.hash = "...",` line
under the .url line:

```
note: expected .hash = "<long base64 string>",
```

## Build System (build.zig)

To use the library, add the dependency in your build.zig:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    // Setup your target and optimization options; create an exe or lib target
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // ...

    // Declare the zig_stb_image dependency and import it to your target's root module
    const zig_stb_image = b.dependency("zig_stb_image", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("stb-image", zig_stb_image.module("stb_image"));
}
```

You can now use it in your src/main.zig file:

```zig
const stb = @import("stb-image");

pub fn main() !void {
    const filename = "hello.png";
    const nchan: i32 = 4;
    const img = stb.image_load(filename, nchan);
    defer img.deinit();
}
```
