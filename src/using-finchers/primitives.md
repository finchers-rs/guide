# Definition of Primitive Endpoints

まず、共通に用いられるコンポーネントの定義をする。

 `:artile_id` および `:user_id` 部分の解析。
これは組み込みのエンドポイントである `path()` を用いる。

```rust
struct ArticleId(String);
struct UserId(String);

let article_id = path().then(|res| match res {
    Ok(id) => Ok(ArticleId(id)),
    Err(e) => Err(ClientError::InvalidArticleId(e)),
});

let user_id = path().then(|res| match res {
    Ok(id) => Ok(UserId(id)),
    Err(e) => Err(ClientError::InvalidUserId(e)),
});
```

`Authorization` ヘッダからの値の取り出し。

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

```rust
let body = body().then(|b| match b {
    Ok(Json(body)) => Ok(body),
    Err(e) => Err(ClientError::ParseBody(e)),
});
```

