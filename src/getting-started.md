*Note:* The english version is coming soon...

# Installation

`Cargo.toml` および `main.rs` を追加する．

```toml
[dependencies]
futures = "0.1"
finchers = "0.10.0"
```

```rust
extern crate futures;
extern crate finchers;
```

# Building an endpoint
WIP

# Starting the HTTP service

```rust
ServerBuilder::default()
    .bind("0.0.0.0:8080")
    .num_workers(1)
    .serve(Arc::new(endpoint));
```
