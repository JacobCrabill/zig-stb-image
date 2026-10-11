const builtin = @import("builtin");
const std = @import("std");

const Translator = @import("translate_c").Translator;
const CFlags = &[_][]const u8{"-fPIC"};

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const linkage = b.option(std.builtin.LinkMode, "linkage", "Static or dynamic linkage") orelse .static;

    ////////////////////////////////////////////////////////////////////////////
    // cImport is gone; translate all C files to Zig at build time instead
    ////////////////////////////////////////////////////////////////////////////
    const translate_c = b.dependency("translate_c", .{});
    const translator: Translator = .init(translate_c, .{
        .c_source_file = b.path("include/stb/stb_image.h"),
        .target = target,
        .optimize = optimize,
        // additional options now available that go here:
        // https://codeberg.org/ziglang/translate-c#options
    });

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
        .imports = &.{.{ .name = "stb", .module = translator.mod }},
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

    const example = b.addExecutable(.{
        .name = "zig-stb",
        .version = .{ .major = 0, .minor = 2, .patch = 0 },
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    example.root_module.addImport("stb_image", mod);
    b.installArtifact(example);

    // Configure how the main executable should be run
    const run_example = b.addRunArtifact(example);
    run_example.step.dependOn(b.getInstallStep());
    run_example.addPassthruArgs();

    // Run the application
    const run = b.step("run", "Run the demo application");
    run.dependOn(&run_example.step);
}
