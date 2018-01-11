# Structure of Finchers Framework

> [draft] This chapter is currently working in progress.

`Endpoint` はルーティング定義の根幹を成す抽象化のために用いられるトレイトである．
このトレイトは次のように定義されている．

```rust
trait Endpoint {
    type Item;
    type Error;
    type Task: Task<Item = Self::Item, Error = Self::Error>;

    fn apply(&self, &mut EndpointContext) -> Option<Self::Task>;
}
```

メソッド `apply` を呼び出すことでルーティングが実行される．
ここで `EndpointContext` は入力であるリクエストとルーティングに関する情報を保持する構造体である．
リクエストが適合しなければ `None` を返し，`404 Not Found` として解釈される．

`Task` は `Endpoint` の戻り値を抽象化するためのトレイトであり，ルーティングの結果が確定した後に `Future` の値に変換される．
このトレイトの定義は次のようになる．

```rust
trait Task {
    type Item;
    type Error;
    type Future: Future<Item = Self::Item, Error = Result<Self::Error, hyper::Error>>;

    fn launch(self, ctx: &mut TaskContext) -> Self::Future;
}
```

## コンポーネントの結合

`Endpoint` はいくつかのコンビネータメソッドを持ち，これを用いることで既存のエンドポイントを組み合わせて新しいエンドポイントを定義することが出来る．
`finchers::endpoint` 下には HTTP リクエストの解析に用いることの出来るいくつかのコンポーネントが定義されている．
