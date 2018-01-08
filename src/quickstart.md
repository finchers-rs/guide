# Quickstart

> [draft] This chapter is currently working in progress.

## Installing Rust
You will need to install the latest version of Rust toolchain before starting to write your Finchers application.
The recommended way is to install the Rust toolchain using `rustup` as follows:

```shell-session
$ curl -sSf https://sh.rustup.rs | sh
```

Finchers requires the version of the Rust toolchain 1.23 or higher.

## Writing Your First Finchers Application

First, create a new Cargo project.

```shell-session
$ cargo new --bin finchers-hello
$ cd finchers-hello
```

Next, add the dependency for `finchers` to `Cargo.toml`.

```toml
[dependencies]
finchers = "0.11"
```

Edit `src/main.rs`.

```rust
#[macro_use]
extern crate finchers;

use finchers::Application;

fn main() {
    let endpoint = e!("Hello, Finchers!\n");
    Application::from_endpoint(endpoint).run();
}
```

```shell-session
$ cargo run
```

```shell-session
$ curl http://127.0.0.1:4000/
Hello, Finchers!
```