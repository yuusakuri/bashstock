# BashStockのアーキテクチャ

この文書では、開発ソースから配布物を生成し、利用者のシェルへ読み込むまでの構成を説明します。
公開APIの契約は[ライブラリ仕様](../specifications/library.md)で定義します。

## 配布の流れ

`src/*.sh`は関数本体、`libexec/`は権限分離が必要な内部コマンドを保持します。
`scripts/build`は両方を`dist/bashstock/`へ集め、GitHub Releaseへ添付する`dist/bashstock.tar.gz`を生成します。

```mermaid
flowchart LR
  Source[src/*.sh]
  Helpers[libexec/]
  Build[scripts/build]
  Directory[dist/bashstock/]
  Archive[dist/bashstock.tar.gz]
  CI[CI]
  Release[GitHub Release]
  Shell[利用者のBash]

  Source --> Build
  Helpers --> Build
  Build --> Directory
  Directory --> Archive
  Archive --> CI
  Archive --> Release
  Directory --> Shell
```

PRと`main`へのpushでは、CIがソースから配布物を生成して検査し、ワークフローの成果物として保存します。
`v<major>.<minor>.<patch>`形式のタグでは、Releaseワークフローが同じ検査を実行し、`bashstock.tar.gz`をGitHub Releaseへ添付します。

## 配布物

配布用アーカイブは次の構成を持ちます。

| パス | 内容 |
| --- | --- |
| `bashstock/bashstock.sh` | 利用者が`source`する関数ライブラリです。 |
| `bashstock/libexec/` | 管理者権限などを分離して実行する内部コマンドです。 |
| `bashstock/LICENSE` | 配布物の利用許諾条件です。 |

`bashstock.sh`は`src/*.sh`を依存順に結合し、多重読み込み防止とTab補完登録を加えたファイルです。
開発ソースと配布物の役割を分けるため、生成先の`dist/`はGitの追跡対象から外します。

## モジュールの依存順

`scripts/build`は、下位の機能から上位の機能へ向かう順序でモジュールを結合します。
上位モジュールは、表の上側にあるモジュールだけを呼び出します。

| 順序 | モジュール | 責務 |
| --- | --- | --- |
| 1 | `settings`、`console`、`number`、`string`、`regex`、`array` | 製品識別、診断、数値、文字列、正規表現、値の列を扱います。 |
| 2 | `arguments`、`completion` | 名前付き引数の検査とTab補完を扱います。 |
| 3 | `system`、`command`、`shell`、`terminal`、`path` | 実行環境、コマンド、シェル、端末、パスを扱います。 |
| 4 | `prompt`、`time`、`log` | 対話入力、時計、ログを扱います。 |
| 5 | `json`、`option`、`file` | 値の条件、選択条件、ファイル更新を扱います。 |
| 6 | `os`、OS別プロバイダー、`user` | OS差分、利用者、所有者を扱います。 |
| 7 | `aws`、`git`、`net` | IMDS、EC2、Auto Scaling、Gitリポジトリ、Ubuntuのネットワーク設定を扱います。 |

## OS別プロバイダー

生成された`bashstock.sh`は、macOS、Ubuntu、Fedoraの実装を一つのファイルに保持します。
読み込み時に`platform::_identifier`がOSを判定し、該当するプロバイダーだけを定義します。

公開関数は`platform`名前空間の内部関数を呼び出します。
この依存方向により、呼び出し側はOSごとのコマンド名やオプションを扱わずに同じ公開APIを使用できます。

## 関連文書

- [ライブラリ仕様](../specifications/library.md)
- [名前付き引数とTab補完の仕様](../specifications/named-arguments.md)
- [関数リファレンス](../reference/functions.md)
- [リリース手順](../how-to/release.md)
