const builtin = @import("builtin");
const std = @import("std");

const CFlags = &[_][]const u8{"-fPIC"};

pub fn build(b: *std.Build) !void {
    comptime {
        const current_zig = builtin.zig_version;
        const min_zig = std.SemanticVersion.parse("0.12.0-dev.2030") catch unreachable; // build system changes: ziglang/zig#18160
        if (current_zig.order(min_zig) == .lt) {
            @compileError(std.fmt.comptimePrint("Your Zig version v{} does not meet the minimum build requirement of v{}", .{
                current_zig,
                min_zig,
            }));
        }
    }

    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    ////////////////////////////////////////////////////////////////////////////
    // Create the Zig STB Image Module
    ////////////////////////////////////////////////////////////////////////////

    // Compile the C source file into a static library, and ensure it gets installed
    // along with the required include directory
    const stb = b.addStaticLibrary(.{
        .name = "stb-image",
        .optimize = optimize,
        .target = target,
        .link_libc = true,
    });
    stb.addIncludePath(.{ .path = "include" });
    stb.addCSourceFile(.{ .file = .{ .path = "src/stb_image.c" }, .flags = CFlags });
    stb.installHeadersDirectory(.{ .path = "include/stb" }, "stb", .{});
    b.installArtifact(stb);

    // Export the 'stb_image' module to downstream packages
    //
    // Much like a CMake target, the libraries and includes attached to this module
    // will apply transitively to the modules of downstream packages, meaning it
    // should "Just Work"
    const mod = b.addModule("stb_image", .{
        .root_source_file = .{ .path = "src/stb_image.zig" },
        .link_libc = true,
    });
    mod.linkLibrary(stb);

    ////////////////////////////////////////////////////////////////////////////
    // Example application using zig-stb-image
    ////////////////////////////////////////////////////////////////////////////

    const exe = b.addExecutable(.{
        .name = "zig-stb",
        .root_source_file = .{ .path = "src/main.zig" },
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
