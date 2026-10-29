# BashStock

BashStockは、macOS、Ubuntu、FedoraのBashスクリプトと対話型Bashから読み込んで使う関数ライブラリです。
文字列、パス、ファイル、時刻、OS設定、パッケージ導入、Git、Android機器の操作などを、同じ名前規則と終了状態で呼び出せます。

配布物は単一のファイル`bashstock.sh`です。
各関数は説明、引数、終了状態、例を持ち、端末からも参照できます。

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
結果は標準出力へ書かれ、成否は終了状態で返ります。

```bash
string::upper 'hello'
path::normalize './foo/../bar'
regex::is-match 'v1.2.3' '^v[0-9]+' && printf 'version tag\n'
```

macOSを常時稼働させ、画面だけを設定時間後に消す場合は、`mac::sleep::disable-automatic`を実行します。システムスリープを無効にし、電源接続時とバッテリー使用時のディスプレイ消灯時間は維持します。

```bash
mac::sleep::disable-automatic
```

複数の設定値を受け取る関数は、`--name VALUE`形式の名前付き引数を使います。
対話型Bashでは、引数名と一部の値をTab補完できます。

```bash
archive::compress-tar-gzip --output backup.tar.gz Documents Pictures
```

関数の説明、引数、終了状態、例は、読み込んだ後に`help::show`で表示できます。

```bash
help::show string::trim
```

## 対応環境

| 対象 | 対応範囲 |
| --- | --- |
| シェル | Bash 3.2以上 |
| OS | macOS、Ubuntu、Fedora |

外部コマンドを使う関数は、そのコマンドがない場合に終了状態69を返します。
必要なコマンドとOSは、[関数リファレンス](docs/reference/functions.md)の各関数の終了状態に記載しています。

## ドキュメント

| 文書 | 内容 |
| --- | --- |
| [関数リファレンス](docs/reference/functions.md) | 公開関数の一覧と、モジュールごとの引数、出力、終了状態、例です。 |
| [ライブラリ仕様](docs/specifications/library.md) | 読み込み、名前空間、Docコメント、入出力、終了状態、シェル状態の契約です。 |
| [名前付き引数とTab補完の仕様](docs/specifications/named-arguments.md) | 引数の表記と補完関数の契約です。 |
| [アーキテクチャ](docs/explanation/architecture.md) | ソース、配布物、モジュール、OS別実装の関係です。 |
| [導入関数のテスト](docs/testing/installers.md) | 導入関数を検査する環境、条件、期待結果です。 |
| [リリース手順](docs/how-to/release.md) | GitHub Releaseへ配布物を公開する手順です。 |

関数の選定根拠は、[bash-commons](docs/explanation/function-selection/bash-commons.md)、[Lobash](docs/explanation/function-selection/lobash.md)、[Pure Bash Bible](docs/explanation/function-selection/pure-bash-bible.md)、[util-scripts](docs/explanation/function-selection/util-scripts.md)、[PSWinUtil](docs/explanation/function-selection/pswinutil.md)ごとに整理しています。

## 貢献方法

開発環境、開発コマンド、実装規則、PRの作成方法は[CONTRIBUTING.md](CONTRIBUTING.md)を参照してください。
脆弱性の報告方法は[SECURITY.md](SECURITY.md)に記載しています。

## ライセンス

BashStockは[MIT License](LICENSE)で提供します。
開発に使うBats-coreとshdocのライセンス本文は、それぞれ`vendor/bats-core`と`vendor/shdoc`に格納されています。
