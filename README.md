# modern-bash-cli

このリポジトリは、macOSとLinuxで同じ動作をするBash製CLIの実装例です。コマンドは、名前を受け取り、挨拶を指定回数だけ出力します。

## 特徴

- Bash 3.2以上で動作します。
- `errexit`、`nounset`、`pipefail`を有効にします。
- shFlags 1.3.0がオプションを定義します。
- 移植可能な引数アダプターが、macOSとLinuxの`getopt`の差を吸収します。
- 利用者の入力を`eval`による変数代入へ渡しません。
- 関数は`feature::command-name`形式で命名します。
- 機能ごとにソースを分割します。
- Bats-core 1.14.0が正常系、異常系、入力の安全性を検査します。
- ShellCheckとBashの構文検査を一つのコマンドで実行できます。

## 動作環境

| 用途 | 条件 |
|---|---|
| 実行 | Bash 3.2以上 |
| 取得 | Git |
| テスト | Gitサブモジュール内のBats-core |
| 静的検査 | ShellCheck |
| 短縮コマンド | Make |

## 取得方法

リポジトリをサブモジュールと一緒に取得します。

```bash
git clone --recurse-submodules <repository-url>
cd modern-bash-cli
```

通常の`git clone`を実行した場合は、次のコマンドでBats-coreを取得します。

```bash
git submodule update --init --recursive
```

## 使用方法

引数を付けずに実行すると、既定の名前を出力します。

```bash
./bin/mytool
```

このコマンドは次の内容を出力します。

```text
Hello, World!
```

名前を指定します。

```bash
./bin/mytool --name 'Ada Lovelace'
```

同じ挨拶を3回出力します。

```bash
./bin/mytool --name 'Alice' --times 3
```

短いオプションも使用できます。

```bash
./bin/mytool -n 'Alice' -t 3
```

ヘルプとバージョンを表示します。

```bash
./bin/mytool --help
./bin/mytool --version
```

## オプション

| 短い名前 | 長い名前 | 値 | 説明 | 既定値 |
|---|---|---|---|---|
| `-n` | `--name` | 制御文字を含まない文字列 | 挨拶に含める名前を指定します。 | `World` |
| `-t` | `--times` | 1から100までの整数 | 出力する行数を指定します。 | `1` |
| `-v` | `--version` | なし | バージョンを表示します。 | 無効 |
| `-h` | `--help` | なし | ヘルプを表示します。 | 無効 |

位置引数は受け付けません。オプションに誤りがある場合は終了状態2を返します。値の範囲や内容に誤りがある場合は終了状態64を返します。

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
| `src/greeting/` | 挨拶の出力を管理します。 |
| `src/output/` | 標準エラー出力を管理します。 |
| `src/settings/` | 製品名、バージョン、既定値、上限値を管理します。 |
| `src/text/` | Bash組み込み機能による文字列処理を管理します。 |
| `test/` | Batsの自動テストを格納します。 |
| `vendor/` | バージョンを固定した外部依存を格納します。 |
| `docs/` | 設計判断を格納します。 |

## 設計

詳しい設計は[設計判断](docs/design.md)に記載しています。

## ライセンス

このリポジトリの独自コードはMIT Licenseで提供します。shFlagsはApache License 2.0で提供され、ライセンス本文は`vendor/shflags/LICENSE`に格納されています。Bats-coreのライセンス本文はサブモジュール内に格納されています。
