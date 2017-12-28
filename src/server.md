構築された `Endpoint` は適切に Hyper のサービスとして起動する必要がある．

最も簡単な方法は，`ServerBuilder` を用いるものである．
これは，`Endpoint` から HTTP サーバを用いるために用意されたヘルパであり，次のように用いる．

```rust
ServerBuilder::default()
    .bind("0.0.0.0:8080")
    .num_workers(1)
    .serve(Arc::new(endpoint));
```

もう一つの方法は，`Endpoint` を Hyper の `Service` に変換して直接 `Server` を起動するというものである．
`Endpoint` はメソッド `to_service` を持っているため，これを用いることで `Service` を実装した型へと変換することが出来る．

```rust
extern crate hyper;
extern crate tokio_core;
extern crate num_cpus;

fn main() {
    let mut core = Core::new().unwrap();
    let handle = core.handle();

    let endpoint = build_endpoint();

    // Service に変換する
    let mut service = endpoint.to_service(&handle);
    service.cookie_manager().set_secret_key(&secret_key);

    let addr = "127.0.0.1:4000".parse().unwrap();
    serve(&service, &addr, &handle);

    core.run(empty()).unwrap();
}

fn serve<T>(service: &T addr: &SocketAddr, handle: &Handle)
where
    T: Clone + Service<
        Request = hyper::Request,
        Response = hyper::Response,
        Error = hyper::Error,
    >,
{
    println!("Listening on {}", addr);

    let proto = Http::new();

    let listener = TcpListener::bind(&addr, &core.handle()).unwrap();
    let server = listener.incoming()
        .map_err(|_| ())
        .for_each(|(sock, addr)| {
            proto.bind_connection(&handle, sock, addr, service.clone());
            Ok(())
        });
    handle.spawn(server);
}
```

Finchers では，`tokio-proto` の `Service` として提供することが可能なミドルウェアのサポートは行わない方針を取っている．これは，フレームワーク側で提供する機能を必要最小限にするためであり，実装の単純化と低レイヤー側向けのミドルウェアの利用をスムーズに行うための措置である．
