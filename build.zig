const builtin = @import("builtin");
const std = @import("std");

const CFlags = &[_][]const u8{"-fPIC"};

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const linkage = b.option(std.builtin.LinkMode, "linkage", "Static or dynamic linkage") orelse .static;

    ////////////////////////////////////////////////////////////////////////////
    // Create the Zig STB Image Module
    ////////////////////////////////////////////////////////////////////////////

    // Export the 'stb_image' module to downstream packages
    //
    // Much like a CMake target, the libraries and includes attached to this module
    // will apply transitively to the modules of downstream packages, meaning it
    // should "Just Work"
    const mod = b.addModule("stb_image", .{
        .root_source_file = b.path("src/stb_image.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mod.addIncludePath(b.path("include"));
    mod.addCSourceFile(.{ .file = b.path("src/stb_image.c"), .flags = CFlags });

    // Compile the C source file into a library, and ensure it gets installed
    // along with the required include directory
    const stb = b.addLibrary(.{
        .name = "stb-image",
        .root_module = mod,
        .linkage = linkage,
    });
    stb.installHeadersDirectory(b.path("include"), "", .{});
    b.installArtifact(stb);

    ////////////////////////////////////////////////////////////////////////////
    // Example application using zig-stb-image
    ////////////////////////////////////////////////////////////////////////////

    const exe = b.addExecutable(.{
        .name = "zig-stb",
        .root_source_file = b.path("src/main.zig"),
        .version = .{ .major = 0, .minor = 1, .patch = 0 },
        .optimize = optimize,
        .target = target,
        .link_libc = true,
    });

    exe.root_module.addImport("stb_image", mod);
    b.installArtifact(exe);

    // Configure how the main executable should be run
    const exe_runner = b.addRunArtifact(exe);
    exe_runner.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        exe_runner.addArgs(args);
    }

    // Run the application
    const run = b.step("run", "Run the demo application");
    run.dependOn(&exe_runner.step);
}
