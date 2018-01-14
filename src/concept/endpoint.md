# Structure of Finchers Framework

> [draft] This chapter is currently working in progress.

`Endpoint` はルーティング定義の根幹を成す抽象化のために用いられるトレイトである．
このトレイトは次のように定義されている．

```rust
trait Endpoint {
    type Item;
    type Error;
    type Result: EndpointResult<Item = Self::Item, Error = Self::Error>;

    fn apply(&self, &mut EndpointContext) -> Option<Self::Result>;
}
```

`EndpointResult` は `Endpoint` の戻り値を抽象化するためのトレイトであり，ルーティングの結果が確定した後に `Future` の値に変換される．
このトレイトの定義は次のようになる．

```rust
trait EndpointResult {
    type Item;
    type Error;
    type Future: Future<Item = Self::Item, Error = Result<Self::Error, hyper::Error>>;

    fn into_future(self, ctx: &mut TaskContext) -> Self::Future;
}
```

1. `Endpoint::apply` が呼び出される
2. `EndpointResult::into_future` が呼び出され、`Future` のインスタンスが生成される
3. `Future` の値が解決される

## コンポーネントの結合

`Endpoint` はいくつかのコンビネータメソッドを持ち，これを用いることで既存のエンドポイントを組み合わせて新しいエンドポイントを定義することが出来る．
`finchers::endpoint` 下には HTTP リクエストの解析に用いることの出来るいくつかのコンポーネントが定義されている．
