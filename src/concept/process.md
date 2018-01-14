# `Process`

直感的に言うと、これはエンドポイントの解析結果を受け取りサーバサイドの処理結果を返す（非同期な）関数である。
トレイト `Process` は次のように定義される。

```rust
trait Process<In> {
    type Out;
    type Err;
    type Future: Future<Item = Self::Out, Error = Self::Err>;
    
    fn call(&self, input: Option<In>) -> Self::Future;
}
```

エンドポイントの解析が正常値あるいは None を返すとその値が Process に渡されて実行される。
