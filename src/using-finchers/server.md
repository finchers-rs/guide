# Definition of Server Side Processes

サーバサイドの処理は，大雑把に言うと次のような `Api` を受け取る（非同期な）関数として実装される．
本質的ではないため，ここでは `process` の実装の詳細な説明は省略する．

```rust
fn process(input: Api) -> impl Future<Item = ApiResult, Error = ServerError> + 'static {
    match input {
        Api::Auth(BasicAuth(username, password)) => { ... }
        Api::Articles(articles) => { ... }
        Api::Users(users) => { ... }
        Api::CurrentUser(AccessToken(token), user) => { ... }
    }
}

enum ApiResult {
    Article(Article),
    CurrentUser(User),
    Articles(Vec<Article>),
    Users(Vec<User>),
    NoContent,
}
```

上で定義したクライアント側の入力と組み合わせると，次のようになる．

```rust
enum ApiError {
    Client(ClientError),
    Server(ServerError),
}

let endpoint = api.map_err(ApiError::Client)
    .and_then(|input| process(input).map_err(ApiError::Server));

```
