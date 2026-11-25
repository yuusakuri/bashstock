# BashStock

BashStockは、macOS、Ubuntu、FedoraのBashスクリプトと対話型Bashから読み込んで使う関数ライブラリです。
文字列、パス、ファイル、時刻、OS設定、パッケージ導入、Git、Android機器の操作などを、同じ名前規則と終了状態で呼び出せます。

配布物は単一のファイル`bashstock.sh`です。
各関数は説明、引数、終了状態、例を持ち、端末からも参照できます。

## インストール

次のコードブロックを端末へ貼り付けて実行します。
初回はインストール、2回目以降は[最新のリリース](https://github.com/yuusakuri/bashstock/releases/latest)への更新になります。
新しく開いたBashとZshの端末から、すべての公開関数を使えます。

```bash
bash <<'BASHSTOCK'
set -eu
directory="${XDG_DATA_HOME:-$HOME/.local/share}/bashstock"
mkdir -p "${directory}"
curl --fail --location \
  --output "${directory}/bashstock.sh.download" \
  https://github.com/yuusakuri/bashstock/releases/latest/download/bashstock.sh
mv "${directory}/bashstock.sh.download" "${directory}/bashstock.sh"

# ZshはBashのライブラリを直接読み込めないため、各関数をBashで実行するファイルを作る。
cat >"${directory}/bashstock.zsh" <<'ZSH'
_bashstock_file="${${(%):-%x}:A:h}/bashstock.sh"
_bashstock() { bash -c 'source "$1" && "${@:2}"' bashstock "${_bashstock_file}" "$@"; }
() {
  local name
  for name in $(_bashstock declare -F); do
    [[ "${name}" != *::* || "${name}" == *::_* ]] || functions[$name]="_bashstock ${name} \"\$@\""
  done
}
ZSH

# .bashrcと.zshrcに次の行を追記する。追記済みの場合は何もしない。
#   .bashrc: source ~/.local/share/bashstock/bashstock.sh
#   .zshrc:  source ~/.local/share/bashstock/bashstock.zsh
register() {
  local line
  printf -v line 'source %q' "$2"
  grep -Fqsx -- "${line}" "$1" || printf '\n# BashStock\n%s\n' "${line}" >>"$1"
}
register "$HOME/.bashrc" "${directory}/bashstock.sh"
register "$HOME/.zshrc" "${directory}/bashstock.zsh"
BASHSTOCK
```

対話型BashではTab補完も有効になります。
Zshの関数は別プロセスのBashで動作するため、環境変数やカレントディレクトリの変更はZshへ反映されません。
Zshから管理者権限が必要な関数を呼び出す場合は、先に`sudo -v`で認証します。

`bashstock.sh`には全機能とMIT Licenseの本文が含まれ、単独で配置できます。
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
| Python | 3.6.9以上 |
| OS | macOS、Ubuntu、Fedora |

外部コマンドを使う関数は、そのコマンドがない場合に終了状態69を返します。
必要なコマンドとOSは、[関数リファレンス](docs/reference/functions.md)の各関数の終了状態に記載しています。

## ドキュメント

| 文書 | 内容 |
| --- | --- |
| [関数リファレンス](docs/reference/functions.md) | 公開関数の一覧と、名前空間ごとの引数、出力、終了状態、例です。 |
| [ライブラリ仕様](docs/specifications/library.md) | 読み込み、名前空間、Docコメント、入出力、終了状態、シェル状態の契約です。 |
| [名前付き引数とTab補完の仕様](docs/specifications/named-arguments.md) | 引数の表記と補完関数の契約です。 |
| [アーキテクチャ](docs/explanation/architecture.md) | ソース、配布物、モジュール、OS別実装の関係です。 |
| [導入関数のテスト](docs/testing/installers.md) | 導入関数を検査する環境、条件、期待結果です。 |
| [HHKB の IME 設定](docs/how-to/qmk-ime-keys.md) | [yuusakuri/qmk_firmware](https://github.com/yuusakuri/qmk_firmware) の HHKB（`hhkb/ansi`）で、GNOME の左右 Alt 単押しを英数入力と日本語入力に設定します。 |
| [リリース手順](docs/how-to/release.md) | リリース用のPRからGitHub Releaseへ配布物を公開する手順です。 |

関数の選定根拠は、[bash-commons](docs/explanation/function-selection/bash-commons.md)、[Lobash](docs/explanation/function-selection/lobash.md)、[Pure Bash Bible](docs/explanation/function-selection/pure-bash-bible.md)、[util-scripts](docs/explanation/function-selection/util-scripts.md)、[PSWinUtil](docs/explanation/function-selection/pswinutil.md)ごとに整理しています。

## 貢献方法

開発環境、開発コマンド、実装規則、PRの作成方法は[CONTRIBUTING.md](CONTRIBUTING.md)を参照してください。
脆弱性の報告方法は[SECURITY.md](SECURITY.md)に記載しています。

## ライセンス

BashStockは[MIT License](LICENSE)で提供します。
開発に使うBats-coreとshdocのライセンス本文は、それぞれ`vendor/bats-core`と`vendor/shdoc`に格納されています。
