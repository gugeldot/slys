# Developer shortcuts. Requirements: Rust (via rustup), Flutter, and on Linux: clang cmake ninja gtk3.
.PHONY: help dev bridge watch-bridge test test-core test-app lint cli-demo build-linux version-check

help:
	@echo "make dev           run the app with hot reload (Dart changes appear instantly)"
	@echo "make watch-bridge  regenerate the Dart bindings whenever the Rust API changes"
	@echo "make bridge        regenerate the Dart bindings once"
	@echo "make test          all tests (Rust + app, real core through the real bridge)"
	@echo "make cli-demo      fragment and rebuild a sample file with the CLI, to see the core work"
	@echo "make lint          fmt + clippy + flutter analyze"

dev:
	cd app && flutter run -d linux

bridge:
	cd app && flutter_rust_bridge_codegen generate

watch-bridge:
	cd app && flutter_rust_bridge_codegen generate --watch

test: test-core test-app

test-core:
	cargo test --workspace

test-app:
	cd app && xvfb-run -a flutter test integration_test -d linux

lint:
	cargo fmt --all --check
	cargo clippy --workspace --all-targets -- -D warnings
	cd app && flutter analyze

cli-demo:
	scripts/cli-demo.sh

build-linux:
	cd app && flutter build linux --release

version-check:
	scripts/check-version.sh
