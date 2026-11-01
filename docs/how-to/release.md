# BashStockのリリース手順

この文書では、保守担当者がGitHub Releaseへ配布物を公開する手順を説明します。
保守担当者はローカルでバージョンを決め、リリース用のPRで`main`へ取り込みます。
PRのマージ以降の公開はReleaseワークフローが行います。

## バージョン

バージョンは`major.minor.patch`形式のセマンティックバージョニングに従います。
プレリリースは`2.0.0-preview1`のように、英字で始まる英数字のラベルを付けます。
Gitタグはバージョンの先頭へ`v`を付けた`v<version>`形式にします。
`src/settings.sh`の`BASHSTOCK_VERSION`は、最後にリリースしたバージョンを示します。

## 事前準備

GitHub CLIをインストールし、`gh auth login`でサインインします。
Releaseワークフローは`GITHUB_TOKEN`でタグとGitHub Releaseを作成するため、追加のシークレットは不要です。

## リリースPRの作成

作業ツリーに未コミットの変更がない最新の`main`で実行します。

```bash
git switch main
git pull --ff-only
just bump 1.2.3
```

`just bump`は`scripts/release bump`を実行し、次の場合は何も変更せずに終了します。

- バージョンの形式が正しくない場合
- 追跡中のファイルに未コミットの変更がある場合
- 現在のブランチが`main`でない場合、または`origin/main`と一致しない場合
- `v<version>`タグまたは`release/<version>`ブランチが既に存在する場合
- 既存のどのリリースタグよりも新しいバージョンでない場合

確認に成功すると、`release/<version>`ブランチで`BASHSTOCK_VERSION`を書き換えてコミットし、pushしてPRを作成します。
`src/settings.sh`が既にそのバージョンを宣言している場合は、空のコミットでPRを作成します。
`--dry-run`を付けると、確認だけを実行し、残りの手順を表示します。

```bash
just bump 1.2.3 --dry-run
```

## 公開

リリースPRをマージすると、Releaseワークフローが開始します。
ワークフローはマージコミットで`just verify`を実行し、`scripts/release publish <merge-commit> --branch release/<version>`で次の順に公開します。

1. チェックアウトがマージコミットであり、作業ツリーに変更がなく、そのコミットが`origin/main`に含まれることを確認します。
2. マージコミットの`BASHSTOCK_VERSION`がブランチ名のバージョンと一致し、既存のリリースタグより新しいことを確認します。
3. `v<version>`タグとGitHub Releaseの状態を読み取り、タグが別のコミットを指す場合は終了します。
4. マージコミットへ注釈付きタグを作成してpushし、`bashstock.sh`を添付したGitHub Releaseを作成します。プレリリースはGitHub Releaseをプレリリースとして作成します。

GitHub CLIはGitHub Releaseを下書きとして作成し、配布物を添付してから公開します。
そのため、同じタグの下書きが残っている場合は、`bashstock.sh`を添付し直して公開します。

最後に、公開した`bashstock.sh`のビルド来歴をattestationとして記録します。
各手順は同じリリースコミットで既に完了している処理を省略するため、途中で失敗した場合はワークフローを再実行すると続きから公開します。

## ローカルでの実行

GitHub Actionsを利用できない場合は、マージコミットをチェックアウトしてローカルで公開できます。

```bash
git switch --detach <merge-commit>
just verify
./scripts/release publish <merge-commit> --branch release/1.2.3 --dry-run
./scripts/release publish <merge-commit> --branch release/1.2.3
```

ローカルでの公開ではビルド来歴のattestationを記録しないため、通常はワークフローで公開します。
