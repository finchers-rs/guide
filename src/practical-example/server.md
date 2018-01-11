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

上のエンドポイントを Web アプリケーションとして実行するためには，出力である `ApiResult` と `ApiError` を `Response` に変換するための `Responder` の実装が必要となる．

```rust
impl Responder for ApiResult { ... }

impl Responder for ApiError { ... }
```

すべての実装が完了した後，次のようにアプリケーションを実行することが可能になる．

```rust
Application::from_endpoint(endpoint).run();
```

端末を起動し，動作確認を行う．

```shell-session
$ curl http://localhost:4000/api/v1/auth -u Alice:wonderland
{
    "access_token": "xxxxxxxx",
    "expires_in": "2018-01-31T00:00:00",
}
```

```shell-session
$ curl -v http://localhost:4000/api/v1/user/articles \
    -H "Content-type: application/json" \
    -H "Authorization: Bearer xxxxxxxx" \
    -d '{ "title": "Hello, Finchers!", "content": "WIP" }'

...

< HTTP/1.1 201 Created
...
{
    "article_id": "1",
    "title": "Hello, Finchers!",
    "created_at: "2018-01-08T00:00:00",
    "content": "WIP"
}
```