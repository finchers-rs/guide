# Practical Example

> [draft] This chapter is currently working in progress.

実際の例として、ユーザ認証機能を持つ簡単な記事共有サービスを作ることを考える．

## API サーバの仕様
今回作成する API サーバのエンドポイントの一覧は次の通りである．
簡単のため API サーバのみとし，Web ページの配信は別に行うものとする．

```txt
GET /auth

GET /articles
GET /articles/:article_id

GET /users
GET /users/:user_id
GET /users/:user_id/articles

GET    /user
GET    /user/artices
GET    /user/artices/:article_id
POST   /user/articles
DELETE /user/articles/:article_id
PUT    /user/articles/:article_id
```

ユーザ認証は `/auth` に Basic 認証を伴う GET リクエストを送信することで行い（結果にアクセストークンが返る），`/user` 以下のリソースで認証されているユーザのリソースの取得・追加・削除・変更を行う．`/users` と `/articles` 以下には認証が不要な（公開されている）リソースのエンドポイントを置く．各エンドポイントの戻り値および POST / PUT リクエストにおけるリクエストボディは JSON 形式とする（詳細な説明は省略する）．


## 実装の概要
次のように段階的に実装する．

1. クライアント側のリクエストを解析する
1. （解析結果の）ユーザからのリクエストを基に処理を実行し結果を返す

## Step 1: エンドポイントの定義

ここで `basic_auth` と `access_token` はそれぞれ `Authorization` ヘッダから値を読み取るエンドポイントである．

```rust
struct ArticleId(String);

// Endpoint<Item = ArticleId, Error = ClientError>
let article_id = path().then(|res| match res {
    Ok(id) => Ok(ArticleId(id)),
    Err(e) => Err(ClientError::InvalidArticleId(e)),
});
```

```rust
struct UserId(String);

// Endpoint<Item = UserId, Error = ClientError>
let user_id = path().then(|res| match res {
    Ok(id) => Ok(UserId(id)),
    Err(e) => Err(ClientError::InvalidUserId(e)),
});
```

```rust
struct BasicAuth(String, String);

// Endpoint<Item = BasicAuth, Error = ClientError>
let basic_auth = header_opt().and_then(|h| match h {
    Some(Authorization(Basic { username, password: Some(password) })) => {
        Ok(BasicAuth(username, password))
    }
    Some(Authorization(Basic { username, password: None })) => {
        Err(BasicAuthError::EmptyPassword)
    }
    None => Err(BasicAuthError::EmptyBasicAuthHeader)
}.map_err(ClientError::BasicAuth));
```

```rust
struct AccessToken(String);

// Endpoint<Item = AccessToken, Error = ClientError>
let access_token = header_opt().and_then(|h| match h {
    Some(Authorization(Bearer { token })) => Ok(AccessToken(token)),
    None => Err(ClientError::AccessToken(AccessTokenError::EmptyToken)),
});
```

上で説明したエンドポイントを愚直にデコードすると次のようになる．
各ルートの出力する値の型が異なるため，このコードはそのままではコンパイルが通らないことに注意されたい．

```rust
// Endpoint<Item = ??, Error = ClientError>
let api = e!("api/v1").with(choice![
    get("auth").with(basic_auth),
    get("articles"),
    get("articles").with(article_id.clone()),
    get("users"),
    get("users").with(user_id.clone()),
    get("users").with(user_id.clone()).skip("articles"),
    get("user").with(user_info.clone()),
    get("user/articles").join(access_token.clone()),
    get("user/articles").with(article_id.clone()).join(access_token.clone()),
    post("user/articles").join((body(), access_token.clone())),
    delete("user/articles").with(article_id.clone()).join(access_token.clone()),
    put("user/articles").with(article_id.clone()).join((body(), access_token.clone())),
]);
```

## Step 1: 最適化
エンドポイントの実装を詳しく見てみる．
上の実装では、すべてのルートの分岐が一点（`api/v1` 直後）に集中しており、同じセグメントが複数のルートで重複して評価されている．
そのため、バックトラックが頻繁に発生しこのままでは効率的でない．
エンドポイントを可能な限り共通化するよう修正すると次のようになる．

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
    e!("user").with(access_token).join(choice![
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
    ]),
]);
```

可読性のため，リソースごとにエンドポイントを中間変数に束縛すると次のように変更することが出来る．

```rust
let auth = get("auth").with(auth);

let articles = e!("articles").with(choice![
    get(()),
    get(article_id),
]);

let users = e!("users").with(choice![
    get(()),
    e!(user_id).join(choice![
        get(()),
        get("articles"),
    ]),
]);

let current_user = e!("user").with(user_info).join(choice![
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
]);

let api = e!("api/v1").with(choice![
    auth,
    articles,
    users,
    current_user,
]);
```

## Step 2: 型合わせ
最後に，全てのエンドポイントの型が一致するよう各ルートの返す値を修正する．
上のコードを注意深く見ると、各エンドポイントの戻り値は次のようなユーザ定義型を用いて表現することができる．

```rust
enum Articles {
    List,
    Add(serde_json::Value),
    TheArticle(ArticleId, Article),
}

enum Users {
    List,
    Add,
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
    get(ok(Articles::List)),
    get(article_id)
        .map(|id| Articles::TheArticle(id, Article::Get)),
]);

// Endpoint<Item = Users, Error = ClientError>,
let users = e!("users").with(choice![
    get(ok(Users::List)),
    e!(user_id).join(choice![
        get(ok(User::Get)),
        get("articles").with(ok(User::Articles(Articles::List))),
    ]).map(|(id, user)| Users::TheUser(id, user)),
]);

// Endpoint<Item = (AccessToken, User), Error = ClientError>
let current_user = e!("user").with(access_token).join(choice![
    get(ok(User::Get)),
    e!("articles").with(choice![
        get(ok(Articles::List)),
        post(body()).map(|Json(entity)| Articles::Add(entity)),
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

これでコンパイルすることが可能になったので，この状態で簡易的な挙動のテストを行う（実際にはより網羅的なテストを記述する必要がある）．
この状態での動作確認は，例えば次のようにして行うことが出来る．

```rust
let mut request = Request::new(Get, "/api/v1/auth".parse().unwrap());
request.headers_mut().set(Authorization(Basic {
    username: "Alice".to_string(),
    password: Some("wonderland".to_string()),
}));
println!("{:?}", finchers::test::run_test(&api, request));
```

```rust
let mut request = Request::new(Get, "/api/v1/user/articles/xxxx".parse().unwrap());
request.headers_mut().set(Authorization(Bearer("tttt".to_string())));
println!("{:?}", finchers::test::run_test(&api, request));
```

## Step 3: サーバサイドの処理

TODO

## Step 4: `Responder` の実装

TODO

## コード全体