# Specification of Sample Application

今回は，

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
GET /user/login
```

```txt
GET    /user
GET    /user/artices
GET    /user/artices/:article_id
POST   /user/articles
DELETE /user/articles/:article_id
PUT    /user/articles/:article_id
```

また，`/user` 下に現在ログインしているユーザのリソースが配置される．

