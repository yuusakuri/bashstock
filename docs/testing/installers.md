# 導入関数のテスト

導入関数は、公開関数の戻り値だけでなく、選んだ版の実体、再実行後の状態、生成した設定、起動結果を確認します。失敗する入力では、終了状態と既存のデータが保たれることを確認します。

## 実行環境

| 環境 | 対象 |
| --- | --- |
| Ubuntu 18.04、20.04、22.04、24.04、26.04 の amd64 コンテナ | Docker、公式 Node.js、JDK、Go、Rust、Ruby の導入・再実行・起動とAPTリポジトリ |
| Fedora 34、44 の amd64 コンテナ | Docker、公式 Node.js、JDK、Go、Rust、Ruby の導入・再実行・起動とDNFリポジトリ |
| Ubuntu 22.04、24.04 の GitHub Actions 実行環境 | Docker サービス、デーモン、コンテナ実行 |
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
| J01 | 公式配布物から Node.js 16.20.2 を導入し、同じ版で再実行する | 両方成功し、Node.js、npm、Corepack、pnpm が起動する | `scripts/test-node-container` |
| J02 | OSのJDK最新版を導入・再実行し、小さなJavaプログラムをコンパイルして動かす | 版とJAVA_HOMEが一致し、実行結果が期待値になる | `scripts/test-jdk-go-container` |
| J03 | OSのGoを導入・再実行し、小さなGoプログラムを動かす | 両方成功し、実行結果が期待値になる | 同上 |
| R01 | 公式 Rust ツールチェーンを導入・再実行し、小さなプログラムをコンパイルして動かす | rustc と cargo が現在・再ログイン後のシェルで起動し、実行結果が期待値になる | `scripts/test-rust-container` |
| R02 | Ruby 3.4.5 を導入・再実行し、小さなプログラムを動かす | 選んだ版の Ruby と gem が現在・再ログイン後のシェルで起動し、実行結果が期待値になる | `scripts/test-ruby-container` |
| A01 | 専用のホームと SDK に Android CLI、Platform Tools、SDK Platform、Build Tools、Command-line Tools、Emulator を導入する | 各実行ファイルが起動し、`android.jar` が存在する | `scripts/test-android-macos` |
| A02 | Platform Tools と Build Tools の導入を繰り返す | 二度目も成功し、実行ファイルが使える | 同上 |
| A03 | API 35 の AVD を作り、同名でもう一度作る | 初回は成功し、二度目は既存の AVD を保持して失敗する | 同上 |
| A04 | AVD を起動し、停止して削除する | Android の起動完了を確認でき、削除後に一覧から消える | `scripts/test-android-linux`、仮想化が使えるmacOS上の`scripts/test-android-macos` |
| A05 | 起動したAVDへ空白を含む名前のファイルを送受信し、画面を保存して再起動する | 内容が一致し、画像が保存され、再起動後に端末が再接続する | `scripts/test-android-linux` |
| N01 | 不正な引数、未対応 CPU、異なる SDK パスを渡す | 対応するエラーを返し、既存の導入先を変更しない | `test/android-install.bats` など |

GitHub Actions の各ジョブは一つでも期待結果と異なれば失敗します。ジョブのログには選択した Docker の版と導入コマンドの結果が残ります。OS ごとの結果は `Installer integration` のジョブ名で区別します。
