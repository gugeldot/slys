//! The API the Flutter app sees. Keep it thin: every function forwards to `slys-core`.
//! `flutter_rust_bridge_codegen generate` turns this module into Dart classes.

pub mod operations;
pub mod storage;
pub mod version;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
    // No core dumps, no same-user debugger attach: the master key lives in this process.
    slys_core::hardening::harden_process();
}
