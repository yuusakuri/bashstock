# BashStock

BashStockは、クロスプラットフォーム（macOS / Linux）に対応したBash 3.2向けの関数ライブラリです。安全な引数解析や入力検査、OS間の挙動差分を吸収するユーティリティを提供します。

主に`.bashrc`などから読み込み、対話型シェルで繰り返し利用する処理を共通化する用途を想定しています。

## 特徴

BashStockは、Bash関数を直接呼び出して利用します。

名前付き引数を使える関数では、次のように引数名を指定できます。

```bash
example::run -Name sample -Count 3
```

対応する関数では、引数名や値の候補をTab補完できます。

macOSとLinuxで外部コマンドの仕様が異なる処理は、BashStock側で差分を吸収します。

## 対応環境

- Bash 3.2以上
- macOS
- Linux

特定のLinuxディストリビューションやCPUアーキテクチャそのものを利用条件にはしません。個別機能が特定の外部コマンドを必要とする場合は、その関数の説明に要件を記載します。

## インストール

任意のディレクトリへBashStockを配置します。

```bash
git clone https://github.com/yuusakuri/bashstock.git "$HOME/.bashstock"
```

## 読み込み

`.bashrc`から`bashstock.sh`を読み込みます。

```bash
source "$HOME/.bashstock/bashstock.sh"
```

標準で提供する関数とTab補完は、この読み込みで利用できます。同じシェルで複数回読み込んでも再初期化しません。読み込み自体は、ネットワーク通信、権限昇格、利用者作成、ファイル更新を実行しません。

## 使い方

### 関数

公開関数は名前空間付きで定義します。

```bash
string::upper 'hello'
path::normalize './foo/../bar'
```

関数名は、対象となる機能領域と処理内容が分かる名前にします。

### 名前付き引数

複数の設定値を受け取る関数では、名前付き引数を利用できます。

```bash
example::run -Name sample -Count 3
```

真偽値を表す引数は値を省略できます。

```bash
example::run -Name sample -Force
```

関数ごとの利用可能な引数は関数一覧に記載します。

### Tab補完

名前付き引数に対応する関数では、関数名の後でTabキーを押すと利用可能な引数を補完できます。

値の候補が定義されている引数では、その候補も補完対象になります。

## 関数一覧

公開関数と引数の詳細は[関数一覧](docs/functions.md)に記載します。名前付き引数とTab補完の正式仕様は[名前付き引数の仕様](docs/argument-model.md)に記載します。公開関数の設計判断は[設計](docs/design.md)、参照元ごとの選定理由は[Lobashの関数選定](docs/references/lobash.md)、[bash-commonsの関数選定](docs/references/bash-commons.md)、[Pure Bash Bibleの関数選定](docs/references/pure-bash-bible.md)に記載します。

## 開発

```bash
./bin/check
```

個別に実行する場合は`./bin/build`、`./bin/test`、`./bin/lint`を使用します。Makeでは各コマンド名から`./bin/`を除いて実行できます。開発方法、テスト、ShellCheck、Bash 3.2互換性の確認方法は[CONTRIBUTING.md](CONTRIBUTING.md)に記載します。

## ディレクトリ構成

| パス | 役割 |
|---|---|
| `bashstock.sh` | 利用者が読み込む生成済みの公開エントリーポイント。`src/*.sh`から`bin/build`が生成します。 |
| `src/` | 開発用ソース。ファイル名から内容が分かる単位で分割します。 |
| `bin/` | 開発者が直接実行するコマンドを格納します。 |
| `libexec/` | コマンドから内部的に呼び出す実行ファイルを格納します。 |
| `test/` | Batsの自動テストを格納します。 |
| `vendor/` | バージョンを固定した外部依存を格納します。 |
| `docs/` | 公開仕様、設計、参照資料を格納します。 |

## ライセンス

このリポジトリの独自コードはMIT Licenseで提供します。Bats-coreのライセンス本文はサブモジュール内に格納されています。
