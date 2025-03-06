const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // STB Image library
    const stbi = b.dependency("zig_stb_image", .{ .target = target, .optimize = optimize });

    // Example application using libstb-image
    const exe = b.addExecutable(.{
        .name = "zig-stb",
        .root_source_file = b.path("main.zig"),
        .version = .{ .major = 0, .minor = 1, .patch = 0 },
        .optimize = optimize,
        .target = target,
    });

    // With the recent changes to the std.Build, we now no longer need to
    // "know" about the details of our dependent modules!
    // Much like a CMake target, we can now just "import" the module, and
    // all of its dependencies are transitively applied.
    exe.root_module.addImport("stb_image", stbi.module("stb_image"));
    b.installArtifact(exe);

    const app_run = b.addRunArtifact(exe);
    app_run.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        app_run.addArgs(args);
    }

    // Run the application
    const run = b.step("run", "Run the demo application");
    run.dependOn(&app_run.step);
}
