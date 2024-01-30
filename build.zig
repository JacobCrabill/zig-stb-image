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
    // Create the STB Image Module
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
    stb.installHeadersDirectory("include/stb", "stb");
    b.installArtifact(stb);

    // Export the 'stb_image' module to downstream packages
    //
    // Much like a CMake target, the libraries and includes attached to this
    // module will apply transitively to the modules of downstream users,
    // meaning it should "Just Work"
    const mod = b.addModule("stb_image", .{
        .root_source_file = .{ .path = "src/stb_image.zig" },
        .link_libc = true,
    });
    mod.addIncludePath(.{ .path = "include" });
    mod.linkLibrary(stb);

    ////////////////////////////////////////////////////////////////////////////
    // Example application using libstb-image
    ////////////////////////////////////////////////////////////////////////////

    const exe = b.addExecutable(.{
        .name = "zig-stb",
        .root_source_file = .{ .path = "src/main.zig" },
        .version = .{ .major = 0, .minor = 1, .patch = 0 },
        .optimize = optimize,
        .target = target,
        .link_libc = true,
    });

    exe.root_module.addIncludePath(.{ .path = "include" });
    exe.root_module.linkLibrary(stb);
    exe.installHeadersDirectory("include/stb", "stb");
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
