# BashStock

BashStockは、他のBashプロジェクトが第三者ライブラリとして読み込む開発キットです。Apple Siliconを含むmacOS、Ubuntu 18.04以降、Fedoraで共通して利用できる関数、引数解析、入力検査、テスト、静的検査、継続的インテグレーションを提供します。

## 特徴

- Bash 3.2以上で動作します。
- `errexit`、`nounset`、`pipefail`を有効にします。
- shFlags 1.3.0がオプションを定義します。
- 移植可能な引数アダプターが、macOSとLinuxの`getopt`の差を吸収します。
- 利用者の入力を`eval`による変数代入へ渡しません。
- 関数は`feature::command-name`形式で命名します。
- 機能ごとにソースを分割します。
- 標準ライブラリ99関数と、任意で読み込むAWS 14関数を提供します。
- 製品固有のサンプル機能を含みません。
- Bats-core 1.14.0が正常系、異常系、入力の安全性を検査します。
- ShellCheckとBashの構文検査を一つのコマンドで実行できます。

## 動作環境

| 用途 | 条件 |
|---|---|
| 実行 | Bash 3.2以上 |
| 対応OS | Apple Siliconを含むmacOS、Ubuntu 18.04以降、Fedora |
| 取得 | Git |
| テスト | Gitサブモジュール内のBats-core |
| 静的検査 | ShellCheck |
| 短縮コマンド | Make |

## 取得方法

リポジトリをサブモジュールと一緒に取得します。

```bash
git clone --recurse-submodules <repository-url>
cd bashstock
```

通常の`git clone`を実行した場合は、次のコマンドでBats-coreを取得します。

```bash
git submodule update --init --recursive
```

## 使用方法

確認用CLIへ引数を付けずに実行すると、ヘルプを表示します。

```bash
./bin/bashstock
```

ヘルプとバージョンを表示します。

```bash
./bin/bashstock --help
./bin/bashstock --version
```

## 関数ライブラリ

標準ライブラリ99関数は、`src/library.sh`を読み込むと使用できます。読み込みによってネットワーク通信、権限昇格、利用者作成、ファイル更新は実行されません。

```bash
source "/path/to/bashstock/src/library.sh"

string::upper "example"
path::normalize "/srv/app/../data"
```

AWS関数は標準ライブラリへ自動的に含まれません。IMDS、EC2、Auto Scalingから、使用するモジュールを読み込みます。Auto Scalingモジュールは依存するIMDS関数とEC2関数も読み込みます。

```bash
source "/path/to/bashstock/src/library.sh"
source "/path/to/bashstock/src/aws/imds.sh"
source "/path/to/bashstock/src/aws/ec2.sh"
source "/path/to/bashstock/src/aws/auto-scaling.sh"
```

公開関数の名前、引数、出力、終了状態は、[設計判断](docs/design.md)、[Lobashの関数選定](docs/references/lobash.md)、[bash-commonsの関数選定](docs/references/bash-commons.md)に記載しています。

## オプション

| 短い名前 | 長い名前 | 値 | 説明 | 既定値 |
|---|---|---|---|---|
| `-v` | `--version` | なし | バージョンを表示します。 | 無効 |
| `-h` | `--help` | なし | ヘルプを表示します。 | 無効 |

位置引数は受け付けません。オプションに誤りがある場合は終了状態2を返します。位置引数が指定された場合は終了状態64を返します。

## 開発方法

テストを実行します。

```bash
./bin/test
```

静的検査を実行します。

```bash
./bin/lint
```

すべての検査を実行します。

```bash
./bin/check
```

Makeを使用する場合も、同じ検査を実行できます。

```bash
make test
make lint
make check
```

## ディレクトリ構成

| パス | 役割 |
|---|---|
| `bin/` | 利用者と開発者が直接実行するコマンドを格納します。 |
| `libexec/` | コマンドから内部的に呼び出す実行ファイルを格納します。 |
| `src/cli/` | オプション定義、入力検査、実行順序を管理します。 |
| `src/library.sh` | 標準ライブラリ99関数を依存順に読み込みます。 |
| `src/aws/` | 任意で読み込むAWS 14関数を格納します。 |
| `src/platform/` | macOS、Ubuntu、Fedoraの内部処理を格納します。 |
| `src/output/` | 標準エラー出力を管理します。 |
| `src/settings/` | 製品名とバージョンを管理します。 |
| `test/` | Batsの自動テストを格納します。 |
| `vendor/` | バージョンを固定した外部依存を格納します。 |
| `docs/` | 設計判断を格納します。 |

## 設計

詳しい設計は[設計判断](docs/design.md)に記載しています。

## ライセンス

このリポジトリの独自コードはMIT Licenseで提供します。shFlagsはApache License 2.0で提供され、ライセンス本文は`vendor/shflags/LICENSE`に格納されています。Bats-coreのライセンス本文はサブモジュール内に格納されています。
