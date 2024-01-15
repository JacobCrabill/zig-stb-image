const std = @import("std");

const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;

const CFlags = &[_][]const u8{"-fPIC"};

pub fn build(b: *std.Build) !void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Defaults to native build.
    const target = b.standardTargetOptions(.{});

    // Export the 'stb_image' module to downstream packages
    _ = b.addModule("stb_image", .{
        .root_source_file = .{ .path = "src/stb_image.zig" },
    });

    const stb = b.addStaticLibrary(.{
        .name = "stb-image",
        .optimize = optimize,
        .target = target,
    });
    stb.addIncludePath(.{ .path = "include" });
    stb.addCSourceFile(.{ .file = .{ .path = "src/stb_image.c" }, .flags = CFlags });

    // Configure compilation options
    // May be needed to compile for various targets (Mac/Windows, Arm, MUSL, etc.)
    // stb.defineCMacro("FOO", "1");

    // Link system libraries
    stb.linkLibC();
    stb.installHeadersDirectory("include/stb", "stb");
    b.installArtifact(stb);

    // Exampe application using libstb-image
    const exe = b.addExecutable(.{
        .name = "zig-stb",
        .root_source_file = .{ .path = "src/main.zig" },
        .version = .{ .major = 0, .minor = 1, .patch = 0 },
        .optimize = optimize,
        .target = target,
    });
    exe.addIncludePath(.{ .path = "include" });
    exe.linkLibrary(stb);
    b.installArtifact(exe);

    const app_step = b.step("zig-stb", "Build the example application");
    app_step.dependOn(&exe.step);

    // Configure how the main executable should be run
    const app = b.addRunArtifact(exe);
    app.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        app.addArgs(args);
    }

    // Run the application
    const run = b.step("run", "Run the demo application");
    const runner = b.addRunArtifact(exe);
    run.dependOn(&runner.step);
}
