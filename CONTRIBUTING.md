# BashStockへのコントリビューション

この文書では、開発環境の準備、検証、実装、PR作成の手順を説明します。

## 開発環境

次のツールはBashStockの開発と検証に使用します。
利用者向けの実行環境は[ライブラリ仕様](docs/specifications/library.md)で定義します。

| ツール | 用途 |
| --- | --- |
| Bash 3.2以上 | ビルドスクリプト、検査スクリプト、テスト、配布物を実行します。 |
| Git | ソース、履歴、Bats-coreサブモジュールを取得します。 |
| just 1.58.0 | 開発コマンドを実行します。 |
| ShellCheck | Bashソースを静的解析します。 |
| Perl、`Time::HiRes`、`POSIX`、`JSON::PP` | 時刻処理とJSON処理を含むテストを実行します。 |
| tar | 配布用アーカイブを生成します。 |

## セットアップ

リポジトリを取得し、Bats-coreサブモジュールを初期化します。

```bash
git clone https://github.com/yuusakuri/bashstock.git
cd bashstock
git submodule update --init --recursive
```

## 開発コマンド

`just`を引数なしで実行すると、利用できるコマンドを表示します。

| コマンド | 実行内容 |
| --- | --- |
| `just build` | `src/*.sh`と`libexec/`から利用者向け配布物`dist/bashstock/`とRelease用アーカイブ`dist/bashstock.tar.gz`を生成します。 |
| `just lint` | Bash構文、ShellCheck、Docコメント、差分の空白エラーを検査します。 |
| `just test` | 配布物を生成してからBatsテストを実行します。 |
| `just verify` | 静的検査、配布物の生成、全テストを順に実行します。 |

開発では`src/*.sh`と`libexec/`を編集します。
`dist/`はローカルとCIで生成するため、Gitの追跡対象には含めません。

## 実装規則

公開関数の名前空間、内部関数、入出力、終了状態は[ライブラリ仕様](docs/specifications/library.md)に従います。
名前付き引数を持つ関数は[名前付き引数とTab補完の仕様](docs/specifications/named-arguments.md)に従います。

- 変数と引数は引用符で囲みます。
- ファイルパスの列挙にはヌル文字区切りを使用します。
- 利用者の入力を`eval`へ渡しません。
- 外部コマンドを使わずに実装できる処理は、Bashの組み込み機能を使用します。
- ライブラリの読み込みと公開関数の実行では、呼び出し元のシェルオプション、`IFS`、カレントディレクトリを保持します。
- 新しい動作には正常系と異常系のテストを用意します。

## PRの作成

PRは一つの目的へ絞り、変更後の動作と確認方法を説明します。
ブランチ名、コミットメッセージ、レビュー、マージは[Git規則](https://github.com/yuusakuri/dev-rules/blob/main/guidelines/development/git-guidelines.md)に従います。

```bash
just verify
```
