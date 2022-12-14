const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // Get the conda prefix from the environment and create the correct environement variables
    const conda_prefix = std.process.getEnvVarOwned(allocator, "CONDA_PREFIX") catch "";
    const lib_path = std.fmt.allocPrint(allocator, "{s}/lib", .{conda_prefix}) catch "";
    const include_path = std.fmt.allocPrint(allocator, "{s}/include", .{conda_prefix}) catch "";

    const exe = b.addExecutable("zig-sdl", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("c");
    // This tells zig to look at the conda path for libraries
    exe.addLibraryPath(lib_path);
    // ... the same for the include path
    exe.addIncludePath(include_path);
    // and we need to add the libraries to the rpath, otherwise we get a runtime error
    exe.addRPath(lib_path);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
