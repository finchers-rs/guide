# Introduction

Finchers Users Guide にようこそ。

Finchers は、非同期性と型安全性を重視したコンポーネント指向のWebフレームワークです。
元々のコンセプトは Scala のライブラリである Finch から着想を得ています。

Finchers では、`Endpoint` というトレイトを実装したコンポーネントを組み合わせていくことで Web アプリケーションを構築します。
Rust のトレイトに基づく静的なディスパッチにより、これらのコンポーネントを組み合わせることによる実行時コストは多くの場合インライン化されます。

## Quickstart

Finchers を用いた Web アプリケーションを試す最も簡単な方法は、プロジェクトのリポジトリをクローンしてサンプルコードを実行することです。
例えば、ToDo アプリの例 （`examples/todos`）を実行するためには次のようにします。

```shell-session
$ git clone https://github.com/finchers-rs/finchers.git
$ cd finchers
$ cargo +nightly run -p example-todos
```

More examples are located in the directory [`examples/`][examples].

[examples]: https://github.com/finchers-rs/finchers/tree/master/examples/

>
> Finchers では、 `futures_api` などいくつかの不安定な言語・ライブラリ機能に依存しています。
> 将来的にこれらが安定化されるまでは、nightly コンパイラを使用する必要があります。
> ツールチェインの管理に `rustup` を使用している場合、次のように nightly コンパイラを使用するよう
> 設定を上書きしておくことをお勧めします。
>
> ```shell-session
> $ cd /path/to/user-project
> $ rustup override set nightly
> ```
>
