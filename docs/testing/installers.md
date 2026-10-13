# 導入関数のテスト

導入関数は、公開関数の戻り値だけでなく、選んだ版の実体、再実行後の状態、生成した設定、起動結果を確認します。失敗する入力では、終了状態と既存のデータが保たれることを確認します。

## 実行環境

| 環境 | 対象 |
| --- | --- |
| Ubuntu 18.04、20.04、22.04、24.04、26.04 の amd64・arm64 コンテナ | Docker、公式 Node.js、JDK、Go、Rust、Ruby、pipx、VS Code、Google Chrome、Microsoft Edge の導入・再実行・起動とAPTリポジトリ |
| Ubuntu 20.04、22.04、24.04、26.04 の amd64・arm64 コンテナ | Claude Desktop の導入・更新とAnthropicのAPTリポジトリ |
| Ubuntu 18.04〜26.04、Fedora 34・43・44 の amd64・arm64 コンテナ（別ジョブ） | Flutter SDK の導入・版の切替と Linux アプリのビルド・起動 |
| Fedora 34、43、44 の amd64・arm64 コンテナ | Docker、公式 Node.js、JDK、Go、Rust、Ruby、pipx、VS Code、Google Chrome、Microsoft Edge の導入・再実行・起動とDNFリポジトリ |
| Ubuntu 18.04〜26.04、Fedora 34・43・44 の amd64・arm64 で systemd を PID 1 にした特権コンテナ | Docker サービスの有効化・起動と一般ユーザーのコンテナ実行。Ubuntu では `ubuntu::setup` と再ログイン後の設定 |
| Ubuntu 22.04、24.04 の amd64・arm64 GitHub Actions 実行環境 | Docker サービス、デーモン、コンテナ実行。DNS 管理方式の切替と Google Public DNS の設定 |
| macOS の GitHub Actions 実行環境（Apple silicon と Intel） | `mac::setup` の二度の実行、設定・既定アプリ・導入アプリの確認、Xcode Command Line Tools と Rosetta |
| macOS の GitHub Actions 実行環境 | Android SDK 構成要素、AVD の作成・削除。Hypervisor.Frameworkが使える実行環境では起動・停止も確認する |
| Ubuntu 24.04 の GitHub Actions 実行環境 | Android SDK 構成要素、KVMを使うAVDの作成・起動・停止・削除 |
| macOS、Ubuntu、Fedora の Bats テスト | 引数境界、失敗時の状態、Git と Android の公開動作 |

コンテナでは systemd が PID 1 ではないため、Docker サービスの操作だけを検査用コマンドに置き換えます。Docker パッケージ、実行ファイル、リポジトリの検査には実物を使います。サービスとデーモンは Ubuntu の実行環境で確認します。

## テスト条件と期待結果

| ID | 条件と操作 | 期待結果 | 実行箇所 |
| --- | --- | --- | --- |
| D01 | 対象 OS で `docker::versions` を呼ぶ | 導入可能な版が一つ以上返る | `scripts/test-docker-package-container` |
| D02 | 返された最新版を指定して `docker::install` を呼ぶ | 終了状態が 0 で、導入済みの Docker Engine が指定版と一致する | 同上 |
| D03 | 同じ版で二度目の導入を行う | 終了状態が 0 で、版が変わらない | 同上 |
| D04 | 導入済みの Docker CLI、Compose、Buildx を起動する | 各コマンドが版を表示して終了する | 同上 |
| D05 | リポジトリ定義と鍵を検査する | 権限が 0644 で、APT は定義を読み込める | 同上 |
| D06 | Ubuntu の systemd 上で同じ版を二度導入する | サービスが有効かつ起動中である | `Installer integration / docker-service` |
| D07 | Docker デーモンで `hello-world` を動かす | イメージの取得とコンテナの実行が成功する | 同上 |
| D08 | 一つ前の版を指定して導入し、最新版を再び指定する | 両方の導入が成功し、各段階で実際の版が指定値と一致する | `scripts/test-docker-package-container` |
| D09 | systemd を PID 1 にした各 OS のコンテナで、sudo を使う一般ユーザーが最新版を二度導入する | 導入済みの版が指定値と一致し、サービスが有効かつ起動中である | `scripts/test-docker-service-container` |
| D10 | 導入後に始めたログインセッションで、sudo を使わずに `hello-world` を動かす | 利用者が docker グループに入り、コンテナの実行が成功する | 同上 |
| S01 | sudo を使う一般ユーザーが、日本語名の XDG ディレクトリがある状態で `ubuntu::setup` を二度実行する | 起動ファイルの各行が一つだけで、新しいログインセッションで `.env` の値、`EDITOR`、補完の大文字小文字無視が有効になる | `scripts/test-ubuntu-setup-container` |
| S02 | S01 の後に利用者ディレクトリ、グループ、Git、SSH を確認する | 英語名のリンクが日本語名のディレクトリを指し、既存の内容が残る。新しいセッションで `dialout` に属し、Git の各設定と `.ssh` の 700 が設定される | 同上 |
| S03 | GNOME の入力ソースが JP 配列だけの状態で、`ubuntu::setup-desktop`（22.04 では `ubuntu::setup-desktop-22`）を D-Bus セッション内で実行する | 新しいセッションで入力ソースが Mozc と US の順になり、`/etc/default/keyboard` が US 配列、hwdb で USB キーボードの変換・無変換キーが henkan・muhenkan になる。Mozc はひらがなで始まり、VLC が動画の既定アプリになる。22.04 ではボタン配置も変わり、ほかの版では `ubuntu::setup-desktop-22` が終了状態 69 を返す | `scripts/test-ubuntu-desktop-container` |
| M01 | 使い捨ての macOS 実行環境で `mac::setup` を二度実行する | 失敗する手順があっても残りを続け、最初に失敗した手順の終了状態を返す。Hypervisor.framework がない実行環境で失敗してよいのは Colima の起動と、起動中のエンジンを要求する `docker::install` だけ | `scripts/test-macos-setup` |
| M02 | M01 の後に設定と起動ファイルを読む | キー・Dock・trackpad の defaults、`DefaultKeyBinding.dict` の Option+T、Git の設定が変わり、新しい Zsh と Bash のセッションで `.env` の値と `EDITOR` が有効になる。起動ファイルの各行は一つだけ | 同上 |
| M03 | M01 の後に導入物と既定アプリを確認する | 各 formula と cask が導入済みで、標準アプリが削除され、アプリに quarantine 属性が残らない。テキストとソースは VS Code、動画は IINA で開く設定になり、QMK Toolbox と IINA が起動する | 同上 |
| M04 | QMK Toolbox を現在の版・古い版で指定し、Command Line Tools を更新し、Rosetta を導入する | 現在の版は成功し、古い版は終了状態 69。clang で C プログラムをビルドして実行でき、Apple silicon では x86_64 のコマンドが動く | 同上 |
| J01 | 公式配布物から Node.js 16.20.2 を導入し、同じ版で再実行する | 両方成功し、Node.js、npm、Corepack、pnpm が起動する | `scripts/test-node-container` |
| J04 | J01 の Node.js で OpenCode を二度導入する | 両方成功し、`$HOME/.local/bin/opencode --version` が版番号を表示する | 同上 |
| J02 | OSのJDK最新版を導入・再実行し、小さなJavaプログラムをコンパイルして動かす | 版とJAVA_HOMEが一致し、実行結果が期待値になる | `scripts/test-jdk-go-container` |
| J03 | OSのGoを導入・再実行し、小さなGoプログラムを動かす | 両方成功し、実行結果が期待値になる | 同上 |
| R01 | 公式 Rust ツールチェーンを導入・再実行し、小さなプログラムをコンパイルして動かす | rustc と cargo が起動し、プログラムが期待値を返す。起動設定を読んだ新しい Bash でも cargo が使える | `scripts/test-rust-container` |
| R02 | Ruby 3.4.5 を導入・再実行し、小さなプログラムを動かす | 指定版の Ruby と gem が起動し、プログラムが期待値を返す。起動設定を読んだ新しい Bash でも Ruby が使える | `scripts/test-ruby-container` |
| P01 | Ubuntu 18.04 以外で OS のパッケージから pipx を導入・再実行する | 両方成功し、起動設定を読んだ新しい Bash の `pipx --version` が最新の提供版と一致し、`pipx list` が動く。pipx で導入したアプリケーションが起動設定の PATH から起動する | `scripts/test-pipx-container` |
| P02 | Ubuntu 18.04 で配布元を省略して導入し、続けて `official` を指定して二度導入する | 省略時は終了状態 69 を返す。`official` では Python 3.6 で動く最新の pipx が入り、`pipx list` が動く | 同上 |
| V01 | 各 OS で版を省略して VS Code を導入し、`vscode::versions` の最新版を指定して再実行する | 導入済みの版が一覧の最新版と一致し、`code --version` が同じ版を表示する。Ubuntu 18.04 では glibc 2.27 で動く 1.85 系が選ばれる | `scripts/test-vscode-container` |
| B01 | 仮想ディスプレイで VS Code を起動する | VS Code のウィンドウが表示される | `scripts/test-browsers-container` |
| B02 | Google Chrome を導入し、ヘッドレスで HTML を描画してから仮想ディスプレイで起動する | 描画結果に元の要素が含まれ、ウィンドウが表示される | 同上 |
| B03 | amd64 で Microsoft Edge を導入し、仮想ディスプレイで起動する。arm64 では導入を試す | amd64 ではウィンドウが表示される。arm64 では Microsoft が Linux 版を公開していないため終了状態 69 を返す | 同上 |
| C01 | Ubuntu 22.04 以降で `claude-desktop::versions` の一つ前の版を指定して二度導入する | 両方成功し、導入済みの版が指定値と一致する | `scripts/test-claude-desktop-container` |
| C02 | 版を省略して再び導入する | 最新版へ更新され、`claude-desktop` コマンドが存在する | 同上 |
| C03 | リポジトリ定義と鍵を検査する | 公式手順と同じ定義が一件だけあり、鍵の権限が 0644 で、`apt-get update` がエラーも警告も出さない | 同上 |
| C04 | Ubuntu 20.04 で導入する | 終了状態 69 を返し、リポジトリを登録せず、パッケージも導入しない | 同上 |
| C05 | 公開指紋と異なる署名鍵を受け取る | 終了状態 65 を返し、リポジトリを登録せず、パッケージも導入しない | `test/setup.bats` |
| N01 | systemd-resolved の実行環境で `net::dns::use-systemd-resolved` と `net::dns::use-google` をそれぞれ二度実行し、systemd-resolved を再起動する | `resolv.conf` が stub を指し、不要なバックアップを作らない。drop-in は 0644 で systemd-resolve 利用者が読め、再起動後も 8.8.8.8・8.8.4.4 が設定され、名前解決できる | `scripts/test-dns-host` |
| N02 | NetworkManager を入れ、ダミー接続と WireGuard 接続がある状態で `net::dns::use-network-manager` と `net::dns::use-google` を実行し、NetworkManager を再起動する | `resolv.conf` が NetworkManager の実行時ファイルを指し、元のリンクがバックアップされる。ダミー接続だけに Google Public DNS と ignore-auto-dns が設定され、WireGuard 接続と、Docker が管理する docker0 の DNS は変わらない。再起動後も設定が残る | 同上 |
| N03 | `net::dns::use-systemd-resolved` で戻す | systemd-resolved が管理し、Google Public DNS で名前解決できる | 同上 |
| N04 | DNS 管理方式を判別できないコンテナで `net::dns::use-google` を実行する | 終了状態 69 を返し、設定ファイルを作らない | `Installer integration / dns` |
| T01 | 各 OS で pass を二度導入し、使い捨ての鍵で項目を暗号化して取り出す | 両方の導入が成功し、取り出した値が保存した値と一致する | `scripts/test-tools-container` |
| T02 | Graphviz と PlantUML を導入し、DOT とシーケンス図を SVG に変換する | 生成した SVG に図の要素が含まれる | 同上 |
| T03 | GIMP と G'MIC プラグインを導入する。OS にプラグインのパッケージがない Ubuntu 26.04 では、配布元を省略した場合と `official` を指定した場合を試す | `gimp --version` が動き、G'MIC が GIMP のプラグインディレクトリに入る。Ubuntu 26.04 の省略時は終了状態 69、`official` では amd64 に GIMP 3 用のプラグインが入り、公式配布物のない arm64 では終了状態 69 を返す | 同上 |
| T04 | Ubuntu で URL の deb を導入する | 依存関係を解決して導入され、コマンドが動く | 同上 |
| T05 | Git Credential Manager を二度導入する | 公式配布物の版が動き、Git の credential helper に登録される | 同上 |
| T06 | Ubuntu の実行環境で SSH サーバーを二度導入し、鍵で localhost に接続する | サービスが有効かつ起動中で、接続したコマンドの結果が返る | `scripts/test-tools-host` |
| T07 | Supabase CLI を二度導入し、使い捨てのプロジェクトで `supabase init`・`start`・`status`・`stop` を実行する | すべて成功する | 同上 |
| T08 | 最新の Ubuntu Server ISO を取得する | 公式 `SHA256SUMS` と一致した ISO が保存される | 同上 |
| F01 | Flutter を二度導入し、起動設定を読んだ新しい Bash から `flutter` を探す | 導入先の `flutter` が見つかり、最新の安定版を表示し、Dart も起動する | `scripts/test-flutter-container` |
| F02 | 一つ前の安定版へ `flutter::use-version` で切り替え、版を省略して `flutter::install` で戻す | 各段階の版が指定どおりになる | 同上 |
| F03 | Linux 向けアプリを作り、テストを実行し、リリースビルドして仮想ディスプレイで起動する | テストとビルドが成功し、アプリが終了せずに動き続ける。Flutter が Linux デスクトップに対応しない Ubuntu 18.04 ではテストまで行う | 同上 |
| T09 | QMK CLI を二度導入し、ファームウェアの作業ツリーを用意して小さなキーボードのファームウェアをビルドする | 導入と起動確認が成功し、HEX ファイルが作られる | `scripts/test-tools-host` |
| A01 | 専用のホームと SDK に Android CLI、Platform Tools、SDK Platform、Build Tools、Command-line Tools、Emulator を導入する | 各実行ファイルが起動し、`android.jar` が存在する | `scripts/test-android-macos` |
| A02 | Platform Tools と Build Tools の導入を繰り返す | 二度目も成功し、実行ファイルが使える | 同上 |
| A03 | API 35 の AVD を作り、同名でもう一度作る | 初回は成功し、二度目は既存の AVD を保持して失敗する | 同上 |
| A04 | AVD を起動し、停止して削除する | Android の起動完了を確認でき、削除後に一覧から消える | `scripts/test-android-linux`、仮想化が使えるmacOS上の`scripts/test-android-macos` |
| A05 | 起動したAVDへ空白を含む名前のファイルを送受信し、画面を保存して再起動する | 内容が一致し、画像が保存され、再起動後に端末が再接続する | `scripts/test-android-linux` |
| N01 | 不正な引数、未対応 CPU、異なる SDK パスを渡す | 対応するエラーを返し、既存の導入先を変更しない | `test/android-install.bats` など |

GitHub Actions の各ジョブは一つでも期待結果と異なれば失敗します。ジョブのログには選択した Docker の版と導入コマンドの結果が残ります。OS ごとの結果は `Installer integration` のジョブ名で区別します。
