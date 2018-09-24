# Converting to HTTP Responses

コンビネータにより返された値は、クライアントに送信する前に HTTP レスポンスへと変換する必要があります。
Finchers では、この変換処理を `Output` というトレイトを用いて抽象化しています。

`Output` は次のように定義されています。

```rust
trait Output {
    type Body;
    type Error;

    fn respond(self, cx: &mut OutputContext<'_>)
        -> Result<Response<Self::Body>, Self::Error>;
}
```