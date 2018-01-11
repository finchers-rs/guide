# Specification of API Server

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

ユーザ認証は `/auth` に Basic 認証を伴う GET リクエストを送信することで行う．
レスポンスに含まれるアクセストークンを `Authorization` ヘッダに付与することで認証情報を送る．

`/articles`, `/users` 下には公開されている（認証情報が不要な）リソースのエンドポイントが配置される．また，`/user` 下に現在ログインしているユーザのリソースが配置される．
