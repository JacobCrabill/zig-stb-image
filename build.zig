const builtin = @import("builtin");
const std = @import("std");

const Builder = std.Build;
const LibExeObjStep = std.build.LibExeObjStep;

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

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Defaults to native build.
    const target = b.standardTargetOptions(.{});

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

    // Configure compilation options
    // May be needed to compile for various targets (Mac/Windows, Arm, MUSL, etc.)
    // stb.defineCMacro("FOO", "1");

    // Example application using libstb-image
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

    // Export the 'stb_image' module to downstream packages
    const mod = b.addModule("stb_image", .{
        .root_source_file = .{ .path = "src/stb_image.zig" },
        .link_libc = true,
    });
    mod.addIncludePath(.{ .path = "include" });
    // mod.addCSourceFile(.{ .file = .{ .path = "src/stb_image.c" }, .flags = CFlags });
    mod.linkLibrary(stb);

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
