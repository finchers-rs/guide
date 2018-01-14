# Specification of Sample Application

## Authorization

```txt
GET /authorize
```

`/authorize` に Basic 認証を伴う GET リクエストを送ることで認証を行う。
戻り値は JSON 形式とし、プライベートなリソースにアクセスするためのアクセストークンを含む。

## Public Resources

```txt
GET /articles
GET /articles/:article_id

GET /users
GET /users/:user_id
GET /users/:user_id/articles
```

`/articles`, `/users` 下には公開されている（認証情報が不要な）リソースのエンドポイントが配置される．

## Private Resources

```txt
GET    /user
GET    /user/artices
GET    /user/artices/:article_id
POST   /user/articles
DELETE /user/articles/:article_id
PUT    /user/articles/:article_id
```

`/user` 下に現在ログインしているユーザのリソースが配置される．
上の認証で得た Bearer トークンをヘッダに付与する必要があり、なければ Unauthorized を返す。
