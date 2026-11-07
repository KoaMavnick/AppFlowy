# Repo layout

AppFlowy desktop is a Flutter UI on a Rust core. This checkout is the unmodified `main` branch. Linux desktop is the target here.

## Where the code lives

- **Flutter UI:** `frontend/appflowy_flutter`. Entry point is `lib/main.dart`. Screens and widgets are under `lib/` (`plugins/document`, `plugins/database`, `features/`, `workspace/`, `user/`, `startup/`). Linux embedding is `linux/`.
- **Rust core:** `frontend/rust-lib`. The Flutter app loads `dart-ffi` (`libdart_ffi.so`). Feature crates sit next to it: `flowy-core` (startup and wiring), `flowy-folder` (sidebar / views), `flowy-document` (documents), `flowy-user` (sessions), `flowy-server` (cloud vs local), `flowy-ai`, `flowy-search`, `flowy-storage`.
- **Database UI:** `frontend/appflowy_flutter/lib/plugins/database` (grid, board, calendar).
- **Database core:** `frontend/rust-lib/flowy-database2`, built on the `collab` / `collab-database` crates (pulled from the AppFlowy-Collab git dependency, not vendored in this repo).
- **SQLite:** `frontend/rust-lib/flowy-sqlite`. Diesel plus a bundled `libsqlite3`. The on-disk file name is `flowy-database.db` (user profile and related rows). Migrations live in `frontend/rust-lib/flowy-sqlite/migrations/`.
- **Document and collab storage:** RocksDB, via `collab-plugins` local storage. A local anonymous session creates `collab_db` under `~/.local/share/io.appflowy.appflowy/`.
- **Vector index:** `frontend/rust-lib/flowy-sqlite-vec`. Local embeddings stay off unless Ollama is set up.
- **Build orchestration:** `frontend/Makefile.toml` and `frontend/scripts/makefile/`. Code generation is `frontend/scripts/code_generation/generate.sh`.
- **Shared assets:** `frontend/resources/` (icons, translations). The Linux install notes are `frontend/scripts/install_dev_env/install_linux.sh`.

## Pins used to build Linux desktop

Flutter **3.27.4** (`frontend/scripts/install_dev_env/install_linux.sh`, `.github/workflows/flutter_ci.yaml`). Rust channel **1.85** (`frontend/rust-toolchain.toml`); a build in `frontend/` resolves that to the latest 1.85 patch (1.85.1 on this machine). CI names Rust **1.85.0** and cargo-make **0.37.18**.

Debug Linux build, from `frontend/`:

```bash
cargo make --profile development-linux-x86_64 appflowy-dev
```

The binary is `frontend/appflowy_flutter/product/0.11.4/linux/Debug/AppFlowy/AppFlowy`. The older docs say `./app_flowy`; this tree's product name is `AppFlowy`.

## Running on Parrot OS

The debug binary built on this Ubuntu 24.04 machine links `libdart_ffi.so` against **GLIBC_2.38** and **GLIBCXX_3.4.30**. Check the Parrot machine with `ldd --version`. If its glibc is older than 2.38, copying this build will not start. Debian 12-based Parrot releases are in that older group, so the reliable path is to build on the Parrot PC itself. Parrot uses apt, and the package names in the Ubuntu section of the Linux build doc apply. Also install `rsync` (the icon generator calls it) and, if `clang++` cannot find `<limits>`, the `g++` package that matches the GCC version Clang searches. Flutter must stay at 3.27.4. After `./AppFlowy` opens, Anonymous mode is the local-only session. No account is required.
