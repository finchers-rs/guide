# `Responder` の実装

Web アプリケーションとして実行するためには，出力である `ApiResult` と `ApiError` を `Response` に変換するための `Responder` の実装が必要となる．

```rust
impl Responder for ApiResult { ... }

impl Responder for ApiError { ... }
```
