# Launching the HTTP Service

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