[vpd.berabou.me](http://vpd.berabou.me/)
---

![2015-10-04 13.53.15](https://cloud.githubusercontent.com/assets/1548478/10266467/685b3d5e-6a9f-11e5-815f-6be7bd3c5abd.png)

# Setup & Boot

gitおよびNodeJSとbowerのインストールが終了していることが前提です。ターミナル／cmder環境下で

```bash
git clone https://github.com/59naga/vpd.berabou.me.git
cd vpd.berabou.me

npm install
npm start
# Server running at http://localhost:59798
```

とすることで、`http://localhost:59798`上に、開発環境を起動できます。

```bash
NODE_ENV=production npm start
# Server running at http://localhost:59798
```

とすることで、本番環境に近い、コンパイルを圧縮して、各`index`ファイルを公開します。

License
---
[MIT][License]

[License]: http://59naga.mit-license.org/
