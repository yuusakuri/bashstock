# BashStock

BashStockは、macOS、Ubuntu、FedoraのBashスクリプトと対話型Bashから読み込んで使う関数ライブラリです。
文字列、パス、ファイル、時刻、OS設定、AWS操作などを、同じ名前と終了状態で呼び出せます。

## インストール

[Releases](https://github.com/yuusakuri/bashstock/releases)から`bashstock.sh`を取得します。
このファイルには全機能とMIT Licenseの本文が含まれ、単独で配置できます。

```bash
installation_directory="${XDG_DATA_HOME:-$HOME/.local/share}/bashstock"
mkdir -p "${installation_directory}"
curl --fail --location \
  --output "${installation_directory}/bashstock.sh.download" \
  https://github.com/yuusakuri/bashstock/releases/latest/download/bashstock.sh &&
  mv "${installation_directory}/bashstock.sh.download" "${installation_directory}/bashstock.sh"
```

スクリプトからは、配置したファイルを読み込みます。
読み込みが失敗した場合は、そのスクリプトを終了します。

```bash
source "${XDG_DATA_HOME:-$HOME/.local/share}/bashstock/bashstock.sh" || exit "$?"
```

対話型Bashでは、`.bashrc`から読み込むとTab補完も自動で有効になります。

```bash
source "${XDG_DATA_HOME:-$HOME/.local/share}/bashstock/bashstock.sh"
```

自動化で使用するバージョンを固定する場合は、特定のリリースから取得した`bashstock.sh`をスクリプトと一緒に管理します。
配布ファイルの実行権限は必要ありません。

## 使い方

公開関数は名前空間を含む名前で呼び出します。

```bash
string::upper 'hello'
path::normalize './foo/../bar'
```

名前付き引数を持つ関数は、`-Name VALUE`形式の引数とTab補完を提供します。

```bash
example::run -Name sample -Count 3 -Force
```

## 対応環境

公開APIが対応する実行環境は次のとおりです。
各関数が必要とするコマンドとOS機能は[関数リファレンス](docs/reference/functions.md)に記載します。

| 対象 | 対応範囲 |
| --- | --- |
| シェル | Bash 3.2以上 |
| OS | macOS、Ubuntu、Fedora |

## API

[ライブラリ仕様](docs/specifications/library.md)では、読み込み、名前空間、入出力、終了状態、シェル状態の契約を定義します。
[名前付き引数とTab補完の仕様](docs/specifications/named-arguments.md)では、引数の表記と補完関数の契約を定義します。
[関数リファレンス](docs/reference/functions.md)では、公開関数を名前空間ごとに確認できます。
[アーキテクチャ](docs/explanation/architecture.md)では、ソース、配布物、モジュール、OS別実装の関係を説明します。

関数の選定根拠は、[bash-commons](docs/explanation/function-selection/bash-commons.md)、[Lobash](docs/explanation/function-selection/lobash.md)、[Pure Bash Bible](docs/explanation/function-selection/pure-bash-bible.md)ごとに整理しています。

## コントリビューション

開発環境、開発コマンド、実装規則、PRの作成方法は[CONTRIBUTING.md](CONTRIBUTING.md)を参照してください。

## ライセンス

BashStockは[MIT License](LICENSE)で提供します。
Bats-coreのライセンス本文はサブモジュール内に格納されています。
