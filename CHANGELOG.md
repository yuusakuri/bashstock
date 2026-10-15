# 変更履歴

このプロジェクトの主な変更を記録します。
形式は[Keep a Changelog](https://keepachangelog.com/ja/1.1.0/)に、バージョンは[セマンティックバージョニング](https://semver.org/lang/ja/)に従います。

## [Unreleased]

### Added

- `util.sh`に、ストレージ、メモリ、Git、SSH、Docker、ADB、デバッガー、systemd、GPG、pass、シリアル通信、USB、DNSなどの日常操作の関数を追加しました。
- `install.sh`と`package.sh`に、macOSのHomebrew、UbuntuのAPT、FedoraのDNFを使う導入関数を追加しました。対象はDocker、Node.js、JDK、Go、Rust、Ruby、pipx、VS Code、Google Chrome、Microsoft Edge、Brave、GIMP、Graphviz、PlantUML、Supabase、QMKなどです。
- Claude Code、Codex、ChatGPT、Claude Desktop、OpenCodeの導入関数を追加しました。これらは常に最新版を導入します。
- Android CLI、SDKの構成要素、AVDの作成・起動・停止・削除を扱う`android.sh`と`android-avd.sh`を追加しました。
- macOSとGNOMEの設定、キーボード、入力ソースを扱う`desktop.sh`と、`mac::setup`、`ubuntu::setup`を追加しました。macOSの設定は1機能1関数で呼び出せます。
- `sudo::passwordless::enable`と`sudo::passwordless::disable`を追加しました。
- アーカイブの検査、削除、展開で、`.tar`、`.tar.xz`、`.tar.bz2`、`.tar.zst`、`.7z`、単体の`.gz`、`.xz`、`.bz2`、`.zst`を扱えるようにしました。
- すべての関数にshdoc形式のDocコメントと実行例を付け、`help::show`で端末に表示できるようにしました。
- `scripts/docs`（`just docs`）で`docs/reference/functions.md`と`docs/reference/modules/`を生成するようにしました。
- 名前付き引数を持つすべての公開関数に、Tab補完用の関数を追加しました。
- 導入関数をベンダーの配布物で検査する手動実行のワークフローと、その条件を記した[導入関数のテスト](docs/testing/installers.md)を追加しました。

### Changed

- 名前付き引数の表記を`-Name`から`--name`形式へ変更しました。
- Docコメントを`###`形式からshdoc形式へ変更し、`scripts/lint`で必須のタグと生成済みリファレンスとの差分を検査するようにしました。
- 開発環境にGNU Awk（`gawk`）が必要になりました。

### Fixed

- `archive::remove-broken`が、検査ツールがない場合や暗号化されている場合にもアーカイブを削除していた問題を修正しました。

[Unreleased]: https://github.com/yuusakuri/bashstock/commits/main
