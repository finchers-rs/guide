# Understanding Endpoint

Finchers では、HTTP アプリケーションにおけるルーティングとリクエストの解析を `Endpoint` というトレイトにより抽象化しています。
大まかに言うと、このトレイトはクライアントからのリクエストを受け取り、ある型の値を返す（非同期な）関数を表します。

説明のために簡略化した `Endpoint` の定義を以下に示します。

```rust
trait Endpoint<'a> {
    type Output: Tuple;
    type Future: TryFuture<Ok = Self::Output, Error = Error> + 'a;

    fn apply(&'a self, cx: &mut Context<'_>) -> EndpointResult<Self::Future>;
}
```

多くのものが登場しました。少しずつ見ていきましょう。

このトレイトは、一つのメソッド `apply()` を持っています。
この中では、クライアントから受信したリクエストの中身を処理し、関連型 `Output` の値に解決される `Future` の値を返します。
リクエストの値へのアクセスは `Context` という構造体を介して行います。
この中には、クライアントからのリクエストの値と同時に Finchers 内部で使用されるパス内の位置情報などのコンテキスト値が格納されています。

関連型 `Output` はエンドポイント自体の「出力」を表します。
後述するコンビネータを実装する関係で、この関連型はタプル型のみを取るよう制限されています（実際には、この制約は内部トレイト `Tuple` で表されます）。

## Built-in Endpoints

通常、ユーザはこのトレイトの実装を直接記述する必要はありません。
その代わり、あらかじめ組み込まれているコンポーネントを組み合わせていくことで Web アプリケーションを構築していきます。
これは丁度、combine などのパーザコンビネータの働きと類似しています。

path segments:

* `path(segment)`
* `param<T>()`

body parsing:

* `body::parse::<T>()`
* `body::json::<T>()`
* `body::urlencoded::<T>()`

header:

* `header::required::<T>()`
* `header::optional::<T>()`

query:

* `query::parse()`

## Composing Endpoints

上に紹介したエンドポイントは、一般的な Web アプリケーションを構築するために用いることを想定した基本的な機能のみを提供します。
実用的な複雑なアプリケーションを実装するためには、これらのコンポーネントを組み合わせていくことで実現します。
基本的には、次の 3 つの方法でコンポーネントを組み合わせます:

* 2 つの `Endpoint` を結合し、それらの結果の直積（タプル）を返す
* 2 つの `Endpoint` のうち、リクエストに「よりマッチする」側の出力を返す
* 結果を別の値に変換する

ライブラリでは、基本的なコンビネータを提供するためのトレイト `EndpointExt` が用意されており、これをインポートすることで以下のコンビネータが使用可能になります。

### Product

コンビネータ `and` を用いることで、2つのエンドポイントの結果を結合したエンドポイントを作ります。
2つのエンドポイントの結果は、HList という仕組みを用いて単一のタプルに平滑化されます。
これにより、複数のエンドポイントを組み合わせていくことで `Output` の型が入り組んだものになることを防ぐことが可能になります。

```rust
let endpoint1 = path("posts");
let endpoint2 = param::<u32>();

let endpoint = endpoint1.and(endpoint2);
```

上の例の場合、2 つのエンドポイント（それぞれ `()`, `(u32,)` を `Output` に持つ）を組み合わせた結果の型は `(u32,)` となります。
このような結合を常に可能にするため、`Endpoint` の関連型 `Output` が取ることの出来る型がタプル型のみになるような制約が設けられています。

### Mapping

結合したエンドポイントの出力は、ビジネスロジックへと渡すことで出力へと「変換」する必要があります。
この変換を実現するためのコンビネータは次のとおりです。
それぞれ 

* `e.map(f)` - a
* `e.then(f)` - a
* `e.and_then(f)` - a

`and()` により平滑化されたタプルからクロージャの引数への変換は、次のように自動的に行われます。

```rust
let endpoint = path("posts").and(param()).and(body::parse())
    .map(|id: u32, body: String| {
        format!("id = {}, body = {}", id, body)
    });
```

### Coproduct (`or`)

```rust
let add_post = ...;
let create_post = ...;

let post_api = add_post.or(create_post);
```
