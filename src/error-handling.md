# Error Handling

## `HttpError`

Finchers では、Web アプリケーション内で生じるエラーを `HttpError` というトレイトを用いて抽象化します。
`HttpError` は `error` モジュール内で定義されており、そのシグネチャは以下の通りです。

```rust
trait HttpError: fmt::Debug + fmt::Display + Send + Sync + 'static {
    fn status_code(&self) -> StatusCode;
    fn headers(&self, h: &mut HeaderMap);
}
```

このトレイトを実装したエラー値は、同じく `error` モジュール内にある `Error` 型へと変換された上でフレームワーク内に保持され、クライアントへのレスポンス構築時にエラーレスポンスへと変換されます。

## Recovering

エラー値は通常「例外」としてフレームワーク内で扱われ、レスポンスへの変換は通常自動で行われます。
この挙動をカスタマイズしたい場合、`recover` というコンビネータを用いることで可能になります。

```rust
let endpoint = ...;

endpoint
    .fixed() // ルーティングのエラーを Future として返すようにする
    .recover(|err| -> Result<&'static str, Error> {
        if err.status_code() == StatusCode::NOT_FOUND {
            Ok("not found")
        } else if err.status_code() == StatusCode::BAD_REQUEST {
            Ok("bad request")
        } else {
            Err(err)
        }
    })
```

`recover` の返す値は隠蔽されており、その後でユーザ側で使用することは現在禁止しています。
