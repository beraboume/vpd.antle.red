[vpd.berabou.me](http://vpd.berabou.me/)
---

![2015-10-16 02.18.43](https://cloud.githubusercontent.com/assets/1548478/10521810/aad3d9aa-73ac-11e5-83dc-3b5efe921949.png)

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
（初回起動時、ファイルの圧縮にCPUをかなり消費します。プロセスが強制終了して`pkgs.min.js`が生成されない場合は、`onefile -o pkgs.min.js -m`を手動で行う必要があるかもしれません。ファイルが`./pkgs.min.js`に存在する場合、圧縮処理は起動しません。）

License
---
[MIT][License]

[License]: http://59naga.mit-license.org/
