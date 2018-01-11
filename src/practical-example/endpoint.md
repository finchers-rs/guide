# Definition of API Endpoint

まず，各エンドポイントは次のような階層構造で表現することが出来る．

```txt
GET /auth [Authorization: Basic]

/articles
  |-> GET /
  |-> GET /[:article_id]

/users
  |-> GET /
  /:user_id
    |-> GET /
    |-> GET /articles

/user [Authorization: Bearer]
  |-> GET /
  /articles
    |-> GET /
    |-> POST / [application/json]
    /[:article_id]
      |-> GET /
      |-> DELETE /
      |-> PUT / [application/json]
```

この構造に注意しつつエンドポイントを実装すると次のようになる．

```rust
let api = e!("api/v1").with(choice![
    get("auth").with(basic_auth),
    e!("articles").with(choice![
        get(()),
        get(article_id.clone()),
    ]),
    e!("users").with(choice![
        get(()),
        e!(user_id).join(choice![
            get(()),
            get("articles"),
        ]),
    ]),
    e!("user").with((access_token, choice![
        get(()),
        e!("articles").with(choice![
            get(()),
            post(body()),
            e!(article_id).join(choice![
                get(()),
                delete(()),
                put(body()),
            ]),
        ]),
    ])),
]);
```

最後に，全てのエンドポイントの型が一致するよう各ルートの返す値を修正する．
上のコードを注意深く見ると、各エンドポイントの戻り値は次のようなユーザ定義型を用いて表現することができる．

```rust
enum Articles {
    Get,
    Post(serde_json::Value),
    TheArticle(ArticleId, Article),
}

enum Users {
    Get,
    TheUser(UserId, User),
}

enum Article {
    Get,
    Delete,
    Put(serde_json::Value),
}

enum User {
    Get,
    Articles(Articles),
}

enum Api {
    Auth(BasicAuth),
    Articles(Articles),
    Users(Users),
    CurrentUser(AccessToken, User),
}
```

上の列挙型を返すようにエンドポイントを修正すると次のようになる。

```rust
// Endpoint<Item = BasicAuth, Error = ClientError>
let auth = get("auth").with(basic_auth());

// Endpoint<Item = Articls, Error = ClientError>
let articles = e!("articles").with(choice![
    get(ok(Articles::Get)),
    get(article_id)
        .map(|id| Articles::TheArticle(id, Article::Get)),
]);

// Endpoint<Item = Users, Error = ClientError>,
let users = e!("users").with(choice![
    get(ok(Users::Get)),
    e!(user_id).join(choice![
        get(ok(User::Get)),
        get("articles").with(ok(User::Articles(Articles::Get))),
    ]).map(|(id, user)| Users::TheUser(id, user)),
]);

// Endpoint<Item = (AccessToken, User), Error = ClientError>
let current_user = e!("user").with(access_token).join(choice![
    get(ok(User::Get)),
    e!("articles").with(choice![
        get(ok(Articles::Get)),
        post(body()).map(|Json(entity)| Articles::Post(entity)),
        e!(article_id).join(choice![
            get(ok(Article::Get)),
            delete(ok(Article::Delete)),
            put(body()).map(|Json(entity)| Article::Put(entity)),
        ]).map(|(id, article)| Articles::TheArticle(id, article)),
    ]).map(User::Articles),
]);

// Endpoint<Item = Api, Error = ClientError>
let api = e!("api/v1").with(choice![
    auth.map(Api::Auth),
    articles.map(Api::Articles),
    users.map(Api::Users),
    current_user.map(Api::CurrentUser),
]);
```

## テスト
これでコンパイルすることが可能になったので，この状態で簡易的な挙動のテストを行う（実際にはより網羅的なテストを記述する必要がある）．
この状態での動作確認は，例えば次のようにして行うことが出来る．

```rust
use finchers::test::TestRunner;
let mut test_runner = TestRunner::new(&api).unwrap();

let mut request = Request::new(Get, "/api/v1/user/articles/0042".parse().unwrap());
request.headers_mut().set_raw("Authorizaion", "Bearer xxxx");
assert_eq!(
    test_runner.run(request),
    Some(Ok(
        Api::CurrentUser(
            AccessToken("xxxx".into()),
            User::Articles(Articles::TheArticle(ArticleId("0042".into()), Article::Get))
        )
    ))
);

let request = Request::new(Get, "/api/v1/user/articles/0042".parse().unwrap());
assert_eq!(
    test_runner.run(request),
    Some(Err(ClientError::AccessToken(AccessTokenError::EmptyToken))),
);

let request = Request::new(Get, "/api/v1/theuser/articles".parse().unwrap());
assert!(test_runner.run(request).is_none());
```

