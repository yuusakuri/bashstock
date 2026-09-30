# PSWinUtilとの導入・Android機能の比較

PSWinUtilの公開関数から、取得元と版の選択、OS・CPUの判定、導入後の実行確認を参考にします。BashStockはLinuxとmacOSのパッケージ管理、シェル設定、終了状態を用います。Windowsのwinget、レジストリ、実行ファイル形式はそのまま使いません。

| 対象 | BashStockでの扱い |
| --- | --- |
| `node::versions`、`node::install` | `SOURCE`でOS標準か公式配布物を選び、完全な版番号を指定します。選んだ取得元に要求版がなければエラーを返します。Corepackとpnpmの起動に必要なNode.jsの版も検査します。 |
| `docker::versions`、`docker::install` | 各OSの公式リポジトリからEngineまたはCLIを導入します。Linuxではサービスを有効にし、CLI、Compose、Buildxを使える状態にします。 |
| `ruby::install`、`go::install`、`git-credential-manager::install`、`opencode::install` | OS別の依存関係と配布物を選びます。Git Credential ManagerはCPUに対応する公式配布物を使い、OpenCodeは公式npmパッケージを利用者の領域に導入します。 |
| `flutter::install` | SDKの取得と既存の作業内容の保全を扱い、FlutterとDartの起動を検査します。 |
| JDK、pipx、GUIアプリなどの導入関数 | 対象OSの提供パッケージとCPUを確認します。対象外のOS・CPUや要求版がない場合は、別の製品や版へ黙って切り替えません。 |
| `android::cli::install`、`android::sdk::install` | Android CLIの公式配布物をOS・CPUで選びます。LinuxではAndroid Studioと同じ `$HOME/Android/Sdk`、macOSでは `$HOME/Library/Android/sdk` を使います。 |
| Android SDK構成要素の各導入関数 | Platform Tools、SDK Platform、Build Tools、Command-line Tools、Emulatorを個別に導入し、実行ファイルまたは `android.jar` を確認します。導入時のライセンスは非対話で受諾します。 |
| `android::system-images::versions`、`android::avd::create` | API、tag、ABI、改訂版を区別します。同名AVDは明示指定なしに置き換えず、導入済みイメージの版を下げません。作成と起動は別の関数です。 |
| `android::avd::start`、`android::avd::stop`、`android::avd::delete` | ポートと接続状態を検査し、起動完了を待ちます。停止と削除はそれぞれ公開関数で実行します。 |
| 既存のADB操作 | 端末の指定、失敗時の終了状態、パスの引用を保持します。再起動後は既定60秒で再接続を待ち、bootloader解除にはfastbootを使います。wake lockは対応端末のsysfsを操作します。 |

導入関数のOS別の確認条件と実行結果は[導入関数のテスト](../../testing/installers.md)とIssue #14～#28で管理します。Windows版と同じ関数名や引数形式を採用することより、各OSで要求した版を安全に導入して使えることを優先します。
