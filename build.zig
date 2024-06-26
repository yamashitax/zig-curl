const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const curlPkg = std.build.Pkg{
        .name = "curl",
        .source = std.build.FileSource{ .path = "./src/main.zig" },
    };

    const lib = b.addStaticLibrary("zig-curl", "src/main.zig");
    lib.setBuildMode(mode);
    const libs = if (builtin.os.tag == .windows) [_][]const u8{
        "c",
        "curl",
        "bcrypt",
        "crypto",
        "crypt32",
        "ws2_32",
        "wldap32",
        "ssl",
        "psl",
        "iconv",
        "idn2",
        "unistring",
        "z",
        "zstd",
        "nghttp2",
        "ssh2",
        "brotlienc",
        "brotlidec",
        "brotlicommon",
    } else [_][]const u8{ "c", "curl" };
    for (libs) |i| {
        lib.linkSystemLibrary(i);
    }
    if (builtin.os.tag == .linux) {
        lib.linkSystemLibraryNeeded("libcurl");
    }
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    if (builtin.os.tag == .windows) {
        main_tests.include_dirs.append(.{ .raw_path = "c:/msys64/mingw64/include" }) catch unreachable;
        main_tests.lib_paths.append("c:/msys64/mingw64/lib") catch unreachable;
    }
    main_tests.addPackage(curlPkg);
    main_tests.linkLibrary(lib);

    const exe = b.addExecutable("curl-basic", "example/basic/main.zig");
    if (builtin.os.tag == .windows) {
        exe.include_dirs.append(.{ .raw_path = "c:/msys64/mingw64/include" }) catch unreachable;
        exe.lib_paths.append("c:/msys64/mingw64/lib") catch unreachable;
    }
    exe.setBuildMode(mode);
    exe.addPackage(curlPkg);
    exe.linkLibrary(lib);
    b.default_step.dependOn(&exe.step);
    exe.install();

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
