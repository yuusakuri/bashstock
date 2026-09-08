# BashStockのリリース手順

この文書では、保守担当者がGitHub Releaseへ配布物を公開する手順を説明します。

## バージョン

バージョンは`major.minor.patch`形式のセマンティックバージョニングに従います。
Gitタグはバージョンの先頭へ`v`を付けた`v<major>.<minor>.<patch>`形式にします。

## 公開前の確認

`main`の最新コミットを取得し、開発時と同じ検査を実行します。

```bash
git switch main
git pull --ff-only
just verify
```

`just build`は`dist/bashstock/`と`dist/bashstock.tar.gz`を生成します。
ローカルで配布内容を確認する場合は、生成された`dist/bashstock/bashstock.sh`を新しいBashプロセスから読み込みます。

## 公開

確認した`main`のコミットへバージョンタグを作成し、GitHubへpushします。

```bash
git tag -a v1.2.3 -m 'Release 1.2.3'
git push origin v1.2.3
```

タグのpushによりReleaseワークフローが開始します。
ワークフローは静的検査、配布物の生成、全テストを実行し、成功後に`bashstock.tar.gz`を添付したGitHub Releaseを作成します。
