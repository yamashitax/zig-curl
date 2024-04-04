pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "zurl",
        .target = target,
        .optimize = optimize,
    });
    const link_vendor = b.option(
        bool,
        "link_vendor",
        "Whether link to vendored libcurl (default: true)",
    ) orelse true;

    if (link_vendor) {
        lib.linkLibrary(
            buildLibCurl(b, target, optimize),
        );
    } else {
        lib.linkSystemLibrary("curl");
    }

    const module = b.addModule("zurl", .{
        .root_source_file = .{ .path = "src/main.zig" },
    });

    module.linkLibrary(lib);

    const test_exe = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    test_exe.linkLibrary(lib);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&b.addRunArtifact(test_exe).step);
}

fn buildLibCurl(b: *Build, target: Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *Step.Compile {
    const tls = @import("libs/mbedtls.zig").create(b, target, optimize);
    const zlib = @import("libs/zlib.zig").create(b, target, optimize);
    const curl = @import("libs/curl.zig").create(b, target, optimize);
    curl.linkLibrary(tls);
    curl.linkLibrary(zlib);

    b.installArtifact(curl);
    return curl;
}

const std = @import("std");

const Build = std.Build;
const Step = Build.Step;
const Module = Build.Module;
const LazyPath = Build.LazyPath;
