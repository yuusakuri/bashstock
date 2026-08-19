# utilスクリプトの関数選定

## 対象

この文書は、[util.bash](sources/util.bash)と[setup-util.bash](sources/setup-util.bash)に含まれる各関数の選定結果を定義します。

採用する関数には、BashStockの名前空間、引数、出力、終了状態を定め、独立した実装を提供します。

区分の「既存」は現在利用できる公開APIを表します。「標準」と「任意」は実装時の配置先を表します。現在利用できる公開APIは[関数リファレンス](../../reference/functions.md)、公開契約は[ライブラリ仕様](../../specifications/library.md)に記載します。

引数名が`DIRECTORY`の場合は、別の規定値を明記した関数を除き、規定値として`.`を使用します。

標準APIは、Bash 3.2、macOS、Ubuntu、Fedoraで同じ引数、出力、終了状態を使用します。OS固有の実装は`platform`配下へ隠します。外部コマンドに依存する関数は、その依存関係を関数リファレンスへ記載します。

コマンド短縮APIは、受け取った値を`eval`や`bash -c`へ渡さず、引数配列として外部コマンドへ渡します。外部コマンドの出力と終了状態は変換せずに返します。`-as-root`は、通常権限と管理者権限のどちらで実行するかを呼び出し側が選択できる場合だけ名前に含めます。操作自体が管理者権限を必要とする関数と、permission不足の場合だけ自動昇格する関数には付けません。全対象を明示する`-all`関数を除き、操作対象を必須引数にします。強制操作であるかどうかは関数名ではなく、機能とDocコメントに明記します。

参照元に安全で意味が明確な規定値がある場合は、その規定値を維持します。対象の誤選択、意図しない削除、認証対象の取り違えを防ぐ必要がある場合だけ引数を必須にします。

導入関数の`VERSION`は任意です。省略時は、対応する提供元またはpackage managerが公開する候補から、実行環境に対応する最新の安定版を自動選択します。版を固定する利用者は`VERSION`を指定できます。候補を公開できる対象には版一覧を返す関数も提供します。downloadした内容について、呼び出し側によるSHA-256などのhash指定と照合は要求しません。公式のHTTPS配布元またはpackage repositoryを使用し、必要なlicenseへの自動同意を許可します。

## 採用する関数

| 参照元の関数 | BashStockの関数 | 区分 | 機能 | 変更点 | 設計 |
|---|---|---|---|---|---|
| `pause` | `prompt::pause [MESSAGE]` | 標準 | Enterキーが入力されるまで待機します。 | <ul><li>標準入力の`read -p`ではなく、利用可能な制御端末から一行を読みます。</li><li>固定messageは未指定時の既定値とし、任意のmessageで上書きできます。</li></ul> | 利用可能な制御端末から一行を読みます。非対話環境では終了状態69を返します。 |
| `datetime-for-filename` | `time::local-date-time-seconds-basic` | 既存 | ローカル日時を`YYYYMMDDTHHMMSS`形式で出力します。 | <ul><li>OSの`date`ではなく、BashStockの実時間時計と日時formatterを使用します。</li></ul> | ファイル名へ使用できる固定長のASCII文字列を出力し、UTC offsetは含めません。 |
| `sleep-hour` | `time::sleep-hours HOURS` | 標準 | 時間を秒へ変換して`sleep`します。 | <ul><li>算術展開の前に、時間が0以上の10進整数であることを検証します。</li></ul> | 0以上の10進整数を検証してから待機します。 |
| `storage-usage` | `storage::usage [PATH]` | 任意 | `df`の人間向け表示から一部のファイルシステムを除外します。 | <ul><li>OSへ直接依存する`df`と`grep`の組合せを、OS別adapter経由の`df`実行へ置き換えます。</li></ul> | OS別の`df`へ委譲して人間向け出力を返します。 |
| `storage-usage-top` | `storage::largest-entries [DIRECTORY] [MAX_ENTRIES]` | 任意 | ディレクトリ直下の使用量上位を人間向け形式で表示します。 | <ul><li>BSD版とGNU版で異なる`du`の深さ指定をOS別adapterで吸収します。</li><li>固定上限10件を、上書き可能な既定値10件へ変更します。</li></ul> | 指定directory自身と直下の項目を表示します。各directoryの容量は配下全体を再帰集計し、降順に並べて既定で10項目まで出力します。BSD版とGNU版の`du`差は内部で吸収します。 |
| `memory-show` | `mem::physical-total-bytes`<br>`mem::physical-total-gibibytes`<br>`mem::swap-total-bytes`<br>`mem::swap-total-gibibytes` | 標準 | 物理メモリーとswapの総容量を取得します。 | <ul><li>Linuxの`free -h`による一括表示を、物理memoryとswapを個別取得するOS別処理へ置き換えます。</li><li>人間向け文字列ではなく、byte整数または小数第2位までのGiBを出力します。</li></ul> | byte関数は0以上の整数を出力します。GiB関数は`1 GiB = 1,073,741,824 bytes`として小数第2位まで出力します。macOS、Ubuntu、Fedoraの取得方法の差は内部へ隠します。 |
| `file-edit-as-root` | `file::edit FILE` | 標準 | ファイルを編集します。 | <ul><li>編集前に、既存の通常fileまたは作成可能な新規pathであることを検証します。</li><li>現在の権限で編集できない場合だけ`sudoedit`を使用します。</li></ul> | 通常fileまたは新規pathだけを受け付け、permissionを事前確認してeditorまたは`sudoedit`の終了状態を返します。 |
| `net-monitor-by-host` | `net::capture-host HOST [INTERFACE]` | 任意 | 指定hostのpacketを取得します。 | — | `INTERFACE`の規定値は`any`です。現在の権限で`tcpdump`を実行できない場合だけ管理者権限を使用します。captureを標準出力、診断を標準エラー出力へ返します。 |
| `net-unused-port` | `net::unused-port` | 任意 | OSが未使用として選んだTCPポート番号を出力します。 | <ul><li>`shuf`で無作為に選んだ番号を`ss`で照合するloopを、loopbackのport 0へのbindへ置き換えます。</li></ul> | Perlの標準socket APIでloopbackアドレスのport 0へ一時的にbindし、OSが割り当てた番号を出力してsocketを閉じます。 |
| `user-name` | `user::name` | 既存 | 現在の実効利用者名を出力します。 | <ul><li>`whoami`をcommand substitutionして`echo`する処理を、`id -un`の直接実行へ置き換えます。</li></ul> | 同じ目的を安全な終了状態で提供します。 |
| `tty-open` | `serial::configure DEVICE [BAUD_RATE]` | 任意 | シリアルデバイスの通信条件を設定します。 | <ul><li>設定前にdevice保持processをSIGKILLする処理を行いません。</li></ul> | 既定のbaud rateは115200です。LinuxとmacOSの`stty`差を内部へ隠し、設定処理の終了時にdeviceを閉じます。 |
| `tty-close` | `serial::release DEVICE [TIMEOUT_SECONDS]` | 任意 | Pythonや別プロセスがシリアルデバイスを開けるように、現在の使用プロセスからdeviceを解放します。 | <ul><li>最初からSIGKILLを送らず、device保持processへ先にSIGTERMを送ります。</li><li>固定0.5秒のsleepを、100ミリ秒間隔で解放状態を確認するloopへ置き換えます。</li><li>timeoutまでに閉じないprocessへSIGKILLを送り、解放状態を再確認します。</li><li>timeoutの既定値は2秒です。</li></ul> | 正確に一致するdeviceを開いているPIDへSIGTERMを送り、100ミリ秒間隔で解放状態を確認します。timeoutまでに閉じなければ残っているPIDへSIGKILLを送り、解放状態を再確認します。SIGKILL後も開いていれば終了状態75を返します。`TIMEOUT_SECONDS`の既定値は2です。実装関数内には、参照元が`file-close "$device_file"`で全保持processを強制終了していた処理をコメントとして残します。 |
| `tty-write` | `serial::write DEVICE DATA`<br>`serial::write-command DEVICE DATA [TERMINATOR] [WAIT_SECONDS]` | 任意 | シリアルデバイスへデータを書きます。 | <ul><li>`printf %b`によるDATA内のescape展開を行わず、DATAをliteralとして書きます。</li><li>終端文字付き書込みと終端文字なし書込みを個別の処理に分離します。</li></ul> | 生データは変換しません。command書込みの終端文字は`none`、`cr`、`lf`、`crlf`から選び、既定値は`cr`です。待機時間の既定値は0秒です。 |
| `screen-new` | `screen::open [NAME]` | 任意 | GNU Screenセッションを開始します。 | — | `NAME`の規定値は`default`です。GNU Screenの対話セッションを開始します。 |
| `archive-compress-tar-gz` | `archive::compress-tar-gzip PATH... [-Output OUTPUT]` | 任意 | 一つ以上の入力をgzip圧縮したtar archiveへまとめます。 | <ul><li>固定出力先`archive.tar.gz`を、最初の入力pathへ`.tar.gz`を付けたpathへ変更します。</li><li>未quoteの一つの入力ではなく、一つ以上のpathを個別の引数として`tar`へ渡します。</li></ul> | 出力先の規定値は、最初の入力pathへ`.tar.gz`をそのまま付けたpathです。`-Output`で明示した出力先を使用できます。 |
| `archive-remove-broken` | `archive::verify [PATH]`<br>`archive::remove-broken [PATH]` | 任意 | アーカイブを検査し、壊れていれば削除します。 | <ul><li>検査だけを行う処理と、検査失敗時に削除する処理を個別に提供します。</li></ul> | `PATH`の規定値は`.`です。通常fileを指定した場合は一件を、directoryを指定した場合は配下の対応archiveを再帰検査します。`archive::verify`は標準出力へ何も書かず、すべて正常なら終了状態0、一件でも壊れていれば終了状態1を返し、診断だけを標準エラー出力へ書きます。`archive::remove-broken`は同じ検査を行い、壊れたarchiveだけを削除します。 |
| `_archive-find` | `archive::_find [DIRECTORY]` | 任意 | 対応拡張子のアーカイブを再帰列挙します。 | <ul><li>`DIRECTORY`の規定値を`.`にします。</li></ul> | NUL区切りでpathを保持し、公開APIにはしません。 |
| `_archive-remove-broken` | `archive::_remove-broken-file PATH` | 任意 | 一つのarchiveを形式別に検査し、壊れていれば削除します。 | <ul><li>検査前に対象が通常fileであることを確認します。</li></ul> | 検査失敗を確認してから、受け取った一つの通常fileだけを削除します。 |
| `_archive-expand` | `archive::extract-file PATH [DESTINATION]` | 任意 | 一つのアーカイブを同じ場所の派生ディレクトリへ抽出します。 | <ul><li>展開前にarchive entry内の絶対path、親参照、出力先外を指すlinkを拒否します。</li></ul> | `DESTINATION`を省略した場合は、入力archiveと同じdirectoryに、認識したarchive拡張子を除いた名前のdirectoryを作ります。指定した場合はその出力先を使用します。入力archiveと出力先の絶対pathは受け付けます。archive entry内の絶対pathは出力先外へ書き込めるため拒否します。ZIPを含め、既存fileは自動上書きします。 |
| `diff-dir` | `diff::directories LEFT RIGHT` | 任意 | 二つのディレクトリへ`diff -uprN`を実行します。 | — | 外部`diff`の出力と終了状態をそのまま返します。 |
| `git-clone` | `git::clone-shallow URL [DIRECTORY] [-Branch BRANCH]` | 任意 | 履歴の深さを1に固定してリポジトリを複製します。 | — | `DIRECTORY`を省略した場合は、Gitによる出力directory名の自動決定を使用します。branchは位置引数の曖昧さを避けるため`-Branch`で指定します。 |
| `git-rebase-abort` | `git::rebase-abort [DIRECTORY]` | 任意 | 進行中のrebaseを中止します。 | — | 進行中のrebaseへ`git rebase --abort`を実行します。 |
| `git-rebase-continue` | `git::rebase-continue [DIRECTORY]` | 任意 | 進行中のrebaseを続行します。 | — | 進行中のrebaseへ`git rebase --continue`を実行します。 |
| `git-rebase-for-edit` | `git::commit::edit-via-rebase REVISION [DIRECTORY]` | 既存 | 指定コミットを編集するため、対話的rebaseを開始して対象コミットで停止します。 | <ul><li>動的な`GIT_SEQUENCE_EDITOR`のshell文字列とOS依存の`sed -i`を、BashStock CLIの固定した非公開sequence editor commandへ置き換えます。</li><li>指定revisionがcommitであり、`HEAD`の祖先であることを開始前に検証します。</li><li>root commitとそれ以外の開始方法を分けます。</li><li>通常の対話的rebaseで対象行を一意に特定できないmerge commitを開始前に拒否します。</li></ul> | 非公開commandはrebase todoから対象commitの省略hashを特定し、`file::replace-text`でその行の`pick`または`p`だけを`edit`へ変更します。対象がroot commitなら`git rebase -i --root`、単一parentのcommitなら対象の親から対話的rebaseを開始します。`GIT_SEQUENCE_EDITOR`には固定commandだけを設定し、revisionをshell codeへ連結しません。merge commitは終了状態65で拒否します。 |
| `git-commit-amend` | `git::commit::amend [DIRECTORY]` | 任意 | メッセージを変えず直前のcommitを修正します。 | — | `git commit --amend --no-edit`を実行します。 |
| 該当なし | `git::commit::create MESSAGE [DIRECTORY]` | 任意 | messageを指定して新しいcommitを作成します。 | — | messageを必須とし、Gitのcommit作成処理へ委譲します。 |
| 該当なし | `git::commit::uncommit [DIRECTORY]` | 任意 | 最新commitを外し、その変更をstage済みの状態で残します。 | — | `git reset --soft HEAD^`を実行します。対象は既定で`HEAD`であるため、関数名へ`latest`を含めません。 |
| `git-current-branch` | `git::branch::current [DIRECTORY]` | 任意 | 現在のブランチ名を出力します。 | <ul><li>detached HEADで文字列`HEAD`を出力せず、出力なしで終了状態1を返します。</li></ul> | detached HEADでは出力せず終了状態1を返します。 |
| `git-create-branch` | `git::branch::create BRANCH [START_POINT] [DIRECTORY]` | 任意 | 基準revisionから新しいブランチを作ります。 | <ul><li>開始revisionの必須指定を廃止し、既定値を`HEAD`にします。</li></ul> | `START_POINT`の既定値は`HEAD`です。 |
| 該当なし | `git::branch::list [DIRECTORY]` | 任意 | local branchとremote-tracking branchの一覧を表示します。 | — | `git branch -a`の一覧を標準出力へ書きます。 |
| `git-diff-name-only` | `git::diff::files FROM [TO] [DIRECTORY]` | 任意 | 二つのrevision間で変わったファイル名を表示します。 | <ul><li>比較先revisionの必須指定を廃止し、既定値を`HEAD`にします。</li></ul> | `TO`の既定値は`HEAD`です。一行につき一つのfile pathを出力します。 |
| 該当なし | `git::diff::patch FROM [TO] [DIRECTORY]` | 任意 | 二つのrevision間のpatchを表示します。 | — | `TO`の既定値は`HEAD`です。Gitのpatch形式を標準出力へ書きます。 |
| 該当なし | `git::diff::uncommitted-patch [DIRECTORY]` | 任意 | 最新commitに対する未commit変更のpatchを表示します。 | — | `HEAD`とworking treeを比較し、stage済みと未stageの追跡対象fileを含むpatchを標準出力へ書きます。未追跡fileは含めません。 |
| `git-diff-current-name-only` | `git::diff::uncommitted-files [DIRECTORY]` | 任意 | 最新commitに対して未commit変更があるファイル名を表示します。 | <ul><li>working treeとindexの比較から、`HEAD`とworking treeの比較へ変更し、stage済み変更も対象にします。</li></ul> | stage済みと未stageの追跡対象fileを一行につき一つ出力します。未追跡fileは含めません。 |
| `git-diff-latest` | `git::diff::latest-patch [DIRECTORY]` | 任意 | 最新commitが導入したpatchを表示します。 | <ul><li>root commitでも空treeとの差分を表示できる処理にします。</li></ul> | 最新commitと第一parentを比較し、patchを標準出力へ書きます。最新commitがroot commitの場合は空treeと比較します。 |
| `git-diff-latest-name-only` | `git::diff::latest-files [DIRECTORY]` | 任意 | 最新commitで変わったファイル名を表示します。 | <ul><li>root commitでも空treeとの差分を表示できる処理にします。</li></ul> | 最新commitと第一parentを比較し、一行につき一つのfile pathを出力します。最新commitがroot commitの場合は空treeと比較します。 |
| `git-format-patch-by-hash` | `git::commit::patch REVISION [REMOTE] [DIRECTORY]` | 任意 | 一つのcommitが導入した変更をunified diff形式で標準出力へ書きます。 | <ul><li>毎回`origin`からfetchせず、revisionがlocalに存在しない場合だけfetchします。</li><li>fetch結果を常に`FETCH_HEAD`から読む処理を廃止し、指定revisionを検証してからpatchを生成します。</li><li>`git format-patch`によるmailbox形式から、commitと第一parentを比較するunified diff形式へ変更します。</li></ul> | revisionをrepositoryのobject databaseで確認し、存在しない場合だけ`REMOTE`から取得します。`REMOTE`の既定値は`origin`です。指定commitと第一parentを比較したunified diffを標準出力へ書きます。root commitは空treeと比較します。 |
| `git-revert-latest-no-commit` | `git::commit::revert-without-commit [REVISION] [DIRECTORY]` | 任意 | revisionの変更をcommitせずworking treeとindexへ反映します。 | <ul><li>任意revisionを指定できるようにします。</li><li>`REVISION`の既定値は`HEAD`です。</li></ul> | 指定revisionへ`git revert --no-commit`を実行します。 |
| `git-revert` | `git::commit::revert [REVISION] [DIRECTORY]` | 任意 | revisionを打ち消すcommitを作ります。 | <ul><li>呼び出し元へ残るglobal変数`commit_hash`を作成せず、引数をlocal値として扱います。</li><li>`REVISION`の既定値は`HEAD`です。</li></ul> | 指定revisionへ`git revert`を実行します。 |
| `git-fetch` | `git::fetch [REMOTE] [DIRECTORY]` | 任意 | remote branchとtagを取得します。 | <ul><li>全remoteを対象にする元の処理に加え、一つのremoteだけを対象にできます。</li></ul> | `REMOTE`を省略した場合は全remoteを対象にします。 |
| `git-fetch-unshallow` | `git::fetch-unshallow [REMOTE] [DIRECTORY]` | 任意 | shallow cloneを完全履歴へ変換します。 | <ul><li>全remoteを対象にする元の処理に加え、一つのremoteだけを対象にできます。</li></ul> | `REMOTE`を省略した場合は全remoteを対象にします。 |
| `git-stash-show-latest` | `git::stash::patch [STASH] [DIRECTORY]` | 任意 | stashのpatchを表示します。 | <ul><li>最新stashだけでなく、指定されたstashも表示できます。</li></ul> | `STASH`の既定値は`stash@{0}`です。`git stash show --patch`のpatchを標準出力へ書きます。 |
| 該当なし | `git::stash::list [DIRECTORY]` | 任意 | stashの一覧を表示します。 | — | `git stash list`の一覧を標準出力へ書きます。 |
| `git-stash-push` | `git::stash::push [MESSAGE] [DIRECTORY]` | 任意 | 未追跡ファイルを含めてstashへ保存します。 | <ul><li>任意のstash messageを指定できます。</li></ul> | 未追跡ファイルを含めます。messageを省略できます。 |
| `git-stash-pop` | `git::stash::pop [STASH] [DIRECTORY]` | 任意 | stashを適用して削除します。 | <ul><li>最新stashだけでなく、指定されたstashも適用して削除できます。</li></ul> | `STASH`の既定値は最新の`stash@{0}`とします。 |
| `git-stash-drop` | `git::stash::drop [STASH] [DIRECTORY]` | 任意 | stashを削除します。 | <ul><li>最新stashだけでなく、指定されたstashも削除できます。</li></ul> | `STASH`の既定値は最新の`stash@{0}`とします。 |
| `git-reset-by-hash` | `git::reset REVISION [DIRECTORY]` | 任意 | 指定コミットへhard resetします。 | — | working treeとindexを指定revisionへ`git reset --hard`で強制的に一致させます。 |
| `git-pull-origin` | `git::pull-rebase [BRANCH] [REMOTE] [DIRECTORY]` | 任意 | branchをremoteからrebase付きで更新します。 | <ul><li>固定remoteの`origin`と現在branchだけでなく、指定されたbranchとremoteも対象にできます。</li></ul> | `BRANCH`の既定値は現在のbranch、`REMOTE`の既定値は`origin`です。 |
| `git-cherry-pick` | `git::cherry-pick REVISION [REMOTE] [DIRECTORY]` | 任意 | originを取得して指定コミットを適用します。 | <ul><li>毎回`origin`をprune付きでfetchせず、revisionがlocalに存在しない場合だけfetchします。</li><li>fetch後にrevisionが存在することを確認してからcherry-pickします。</li></ul> | revisionをrepositoryのobject databaseで確認し、存在しない場合だけ`REMOTE`をfetchします。`REMOTE`の既定値は`origin`です。取得後も存在しなければ適用しません。 |
| `git-cherry-pick-continue` | `git::cherry-pick-continue [DIRECTORY]` | 任意 | cherry-pickを続行します。 | — | `git cherry-pick --continue`の出力と終了状態を返します。 |
| `git-cherry-pick-abort` | `git::cherry-pick-abort [DIRECTORY]` | 任意 | cherry-pickを中止し、無視対象を含む未追跡ファイルを削除します。 | — | `git cherry-pick --abort`の成功後に`git clean -fdx`を実行し、無視対象を含む未追跡fileとdirectoryを削除します。 |
| `git-push-current-branch` | `git::push [BRANCH] [REMOTE] [DIRECTORY]` | 任意 | branchをremoteへforce-with-leaseで送信します。 | <ul><li>固定remoteの`origin`と現在branchだけでなく、指定されたbranchとremoteも対象にできます。</li></ul> | `BRANCH`の既定値は現在branch、`REMOTE`の既定値は`origin`です。送信には`--force-with-lease`を使用します。 |
| `git-push-current-branch-for-gerrit` | `gerrit::push-review [BRANCH] [REMOTE] [DIRECTORY]` | 任意 | Gerritのレビュー参照へbranchを送信します。 | <ul><li>固定remoteの`origin`と現在branchだけでなく、指定されたbranchとremoteも対象にできます。</li></ul> | `BRANCH`の既定値は現在のbranch、`REMOTE`の既定値は`origin`です。 |
| `git-push-current-branch-for-gerrit-as-wip` | `gerrit::push-review-wip [BRANCH] [REMOTE] [DIRECTORY]` | 任意 | GerritへWIPとしてbranchを送信します。 | <ul><li>固定remoteの`origin`と現在branchだけでなく、指定されたbranchとremoteも対象にできます。</li></ul> | `BRANCH`の既定値は現在branch、`REMOTE`の既定値は`origin`です。`refs/for/BRANCH%wip`へ送信します。 |
| `git-delete-branch` | `git::remote::delete-branch [BRANCH] [REMOTE] [DIRECTORY]` | 任意 | remote上のbranchを削除します。 | <ul><li>固定remoteの`origin`と現在branchだけでなく、指定されたbranchとremoteも対象にできます。</li></ul> | `BRANCH`の既定値は現在branch、`REMOTE`の既定値は`origin`です。Git remoteのbranch削除へ委譲します。 |
| `git-submodule-update-all` | `git::submodule::update-all [DIRECTORY]` | 任意 | 全サブモジュールを再帰初期化して更新します。 | — | 全submoduleを再帰的に初期化して更新します。 |
| `repo-init` | `repo::init URL BRANCH MANIFEST [DIRECTORY]` | 任意 | Google Repo workspaceを浅い履歴で初期化します。 | <ul><li>任意の作業directoryで実行できます。</li></ul> | Google Repo CLIを明示読込モジュールから呼び出します。 |
| `repo-sync` | `repo::sync PATH [JOBS] [DIRECTORY]` | 任意 | 指定パスを固定並列数と強制同期で更新します。 | <ul><li>任意の作業directoryで実行できます。</li></ul> | `JOBS`の規定値は4です。常に`--force-sync`を付け、指定pathを同期します。 |
| `repo-manifest` | `repo::write-manifest [OUTPUT] [DIRECTORY]` | 任意 | 固定名へ現在のマニフェストを書き出します。 | <ul><li>任意の作業directoryで実行できます。</li></ul> | `OUTPUT`の規定値は`./manifest.xml`です。現在のmanifestを指定した出力先へ書きます。 |
| `repo-check` | `repo::check [DIRECTORY]` | 任意 | 全プロジェクトで`git fsck`を実行します。 | <ul><li>任意の作業directoryで実行できます。</li></ul> | Google Repo CLIと各repositoryのGit検査結果を返します。 |
| `docker-ps` | `docker::container::list-running` | 任意 | 実行中のcontainerを表示します。 | — | `docker ps`の出力と終了状態を返します。 |
| `docker-ps-all` | `docker::container::list` | 任意 | 停止中を含む全containerを表示します。 | — | `docker ps --all`の出力と終了状態を返します。 |
| `docker-pull` | `docker::container::pull CONTAINER CONTAINER_PATH [HOST_PATH]`<br>`docker::container::push CONTAINER HOST_PATH [CONTAINER_PATH]` | 任意 | containerとhostの間でpathをコピーします。 | <ul><li>containerからhostへの取得に加え、hostからcontainerへの送信を提供します。</li></ul> | pullの`HOST_PATH`とpushの`CONTAINER_PATH`の規定値は`.`です。各pathを変換せず`docker cp`へ渡します。 |
| `docker-exec` | `docker::container::shell CONTAINER [COMMAND] [ARG...]` | 任意 | containerで対話shellまたは任意commandを実行します。 | — | `COMMAND`を省略した場合はBashが利用可能ならBash、それ以外はshを対話実行します。指定した場合はcommandと引数を変換せず実行します。 |
| `docker-logs` | `docker::container::logs CONTAINER` | 任意 | containerのログを追尾します。 | — | `docker logs --follow`の出力と終了状態を返します。 |
| `docker-stop` | `docker::container::stop CONTAINER` | 任意 | containerを停止します。 | — | 対象を必須にします。 |
| `docker-start` | `docker::container::start CONTAINER` | 任意 | containerを起動します。 | — | 対象を必須にします。 |
| `adb-wait-for-device` | `adb::device::wait [-Serial SERIAL]` | 任意 | ADB端末の接続を待ちます。 | — | `SERIAL`を省略した場合はADBの既定の端末選択を使用します。 |
| `adb-pull` | `adb::device::pull REMOTE_PATH [LOCAL_PATH] [-Serial SERIAL]`<br>`adb::device::push LOCAL_PATH [REMOTE_PATH] [-Serial SERIAL]` | 任意 | hostと端末の間でpathを転送します。 | <ul><li>端末からの取得に加え、端末への送信を提供します。</li></ul> | pullの`LOCAL_PATH`とpushの`REMOTE_PATH`の規定値は`.`です。`SERIAL`を省略した場合はADBの既定の端末選択を使用します。 |
| `adb-logcat-clear` | `adb::logcat::clear [-Serial SERIAL]` | 任意 | logcatバッファーを消去します。 | — | `SERIAL`を省略した場合はADBの既定の端末選択を使用します。 |
| `adb-logcat` | `adb::logcat::once [FILTER...] [-Serial SERIAL]`<br>`adb::logcat::continuous [FILTER...] [-Serial SERIAL]` | 任意 | logcatを一度取得するか継続表示します。 | <ul><li>任意のfilter引数をADBへ渡せます。</li><li>一度だけ取得する処理を追加します。</li></ul> | onceは`adb logcat --dump`、continuousは`adb logcat`を実行します。追加引数を配列で渡し、`SERIAL`を省略した場合はADBの既定選択を使用します。 |
| `adb-reboot` | `adb::device::reboot [-Serial SERIAL]` | 任意 | 端末を再起動し、再接続を待ちます。 | <ul><li>再接続後のwake lock設定を行いません。</li></ul> | 再起動と再接続待機だけを行います。`SERIAL`を省略した場合はADBの既定の端末選択を使用します。 |
| `adb-first-device` | `adb::device::first`<br>`adb::device::list` | 任意 | 接続済み端末のIDを出力します。 | <ul><li>最初の端末だけでなく、接続済み端末の一覧も提供します。</li></ul> | listは`adb devices`で状態が`device`の端末IDを一行ずつ出力します。firstはその先頭を出力し、端末がなければ出力せず終了状態1を返します。 |
| 該当なし | `adb::device::set-default SERIAL` | 任意 | 以後のADB呼出しで使用する既定端末を設定します。 | — | 現在のshellで`ANDROID_SERIAL`へ検証済みのSERIALを設定してexportします。各関数の`-Serial`はこの既定値より優先します。 |
| 該当なし | `adb::server::start`<br>`adb::server::stop`<br>`adb::server::restart` | 任意 | host側のADB serverを開始、停止、再起動します。 | — | startは`adb start-server`、stopは`adb kill-server`を実行します。restartは停止が成功してから開始し、各commandの出力と終了状態を返します。 |
| `adb-wait-for-file` | `adb::device::wait-for-path REMOTE_PATH [TIMEOUT_SECONDS] [-Serial SERIAL]` | 任意 | 指定パスが現れるまで待機します。 | <ul><li>host側の`-f`検査を、ADB device内のpath検査へ置き換えます。</li></ul> | `TIMEOUT_SECONDS`の規定値は30です。`SERIAL`を省略した場合はADBの既定の端末選択を使用します。 |
| `adb-screencap` | `adb::device::screen::capture-once [OUTPUT_PATH] [-Serial SERIAL]` | 任意 | 日時付きスクリーンショットを保存し、保存pathを出力します。 | <ul><li>`WORK_DIR`が未設定の場合に`.`を使用します。</li><li>保存したpathを標準出力へ書きます。</li></ul> | `OUTPUT_PATH`を省略した場合は`${WORK_DIR:-.}/YYYYMMDDTHHMMSS/YYYYMMDDTHHMMSS-adb-image.png`へ保存します。指定時は指定pathを使用します。`SERIAL`を省略した場合はADBの既定選択を使用します。 |
| `process-id-by-cmd` | `process::ids-by-name NAME` | 任意 | `pidof`で実行名に一致するPIDを出力します。 | <ul><li>Linuxの`pidof`直接実行を、OS別のprocess検索処理へ置き換えます。</li></ul> | OS別実装から全PIDを一行ずつ出力します。 |
| `process-id-by-cmd-regex` | `process::ids-by-name-regex EXPRESSION` | 任意 | コマンドライン正規表現に一致するPIDを出力します。 | <ul><li>OSごとの`pgrep`差を内部で吸収します。</li></ul> | 各OSの`pgrep`で評価する正規表現契約を明記します。 |
| `process-trace-by-pid` | `process::threads-by-pid PID` | 任意 | Linuxの`ps -T`でスレッド一覧を表示します。 | <ul><li>Linuxの`ps -T`直接実行を、OS別のthread一覧処理へ置き換えます。</li></ul> | OS別の`ps`から人間向けスレッド一覧を返します。 |
| `process-trace-by-cmd` | `process::threads-by-name NAME` | 任意 | 実行名に一致するprocessのthread一覧を表示します。 | <ul><li>Linux版`ps`の固定optionを、OS別のthread一覧処理へ置き換えます。</li></ul> | `process::ids-by-name`の最初のPIDを`process::threads-by-pid`へ渡します。一致するprocessがなければ失敗します。 |
| `systemcall-trace-by-pid` | `syscall::trace-by-pid PID` | 任意 | PIDへ`strace`を接続します。 | — | Linux専用`strace`の終了状態を返します。permission不足の場合だけ管理者権限で再実行します。 |
| `library-trace-by-pid` | `lib::trace-by-pid PID` | 任意 | PIDへ`ltrace`を接続します。 | — | Linux専用`ltrace`を現在の権限で実行し、permission不足の場合だけ管理者権限で再実行します。 |
| `gdb-attach-pid` | `gdb::attach-pid PID` | 任意 | PIDへGDBをバッチ接続して全スレッドのバックトレースを出力します。 | — | GDBをbatch modeで接続し、全threadのbacktraceを出力します。 |
| `gdb-server` | `gdb::server::start PORT COMMAND [ARG...]` | 任意 | 指定ポートで`gdbserver`からコマンドを起動します。 | — | コマンド引数を配列で渡します。 |
| `gdb-remote` | `gdb::connect ELF HOST PORT` | 任意 | ELFを読み込み、リモートGDBサーバーへ接続します。 | — | 接続先を必須にします。 |
| `gdb-break` | `gdb::run-until ELF SYMBOL [ARG...]` | 任意 | ELFをGDBで起動し、指定シンボルへbreakpointを置きます。 | <ul><li>debug対象programへ任意の追加引数を渡せます。</li></ul> | 対象を明示します。 |
| `gdb-coredump` | `gdb::core::open ELF CORE_FILE` | 任意 | ELFとcore dumpをGDBで開きます。 | — | 両ファイルを必須にします。 |
| `device-tree` | `device-tree::node::list` | 任意 | LinuxのDevice Treeに含まれるnode pathを列挙します。 | — | Linux専用人間向け一覧を返します。 |
| `i2c-buses` | `i2c::bus::list` | 任意 | I2C busを列挙します。 | — | Linux専用`i2cdetect -l`へ委譲します。 |
| `i2c-devices` | `i2c::device::list BUS` | 任意 | 指定I2C bus上のdeviceを列挙します。 | — | Linux専用`i2cdetect -y`へ検証済みのBUSを渡します。 |
| `gpio-devices` | `gpio::chip::list`<br>`gpio::line::list [CHIP]` | 任意 | GPIO chipまたはlineを列挙します。 | <ul><li>line一覧に加え、chip一覧を提供します。</li></ul> | chipは`gpiodetect`、lineは`gpioinfo`へ委譲します。`CHIP`を省略した場合は全chipのlineを表示します。 |
| `usb-devices` | `usb::device::list` | 任意 | USB deviceを表示します。 | — | Linux専用`lsusb`へ委譲します。 |
| `pci-devices` | `pci::device::list` | 任意 | PCI deviceを表示します。 | — | Linux専用`lspci`へ委譲します。 |
| `adoc-generate-html` | `asciidoc::html INPUT [OUTPUT_DIRECTORY]` | 任意 | AsciiDocを図対応のHTMLへ変換します。 | — | `OUTPUT_DIRECTORY`の規定値は`.`です。`asciidoctor`へ委譲します。 |
| `flutter-run-chrome-release` | `flutter::run-chrome-release [DIRECTORY]` | 任意 | FlutterをChrome向けreleaseモードで実行します。 | <ul><li>任意の作業directoryで実行できます。</li></ul> | Flutter CLIへ委譲します。 |
| `flutter-run-linux-release` | `flutter::run-linux-release [DIRECTORY]` | 任意 | FlutterをLinux向けreleaseモードで実行します。 | <ul><li>任意の作業directoryで実行できます。</li></ul> | 対応対象を名前へ明示します。 |
| `flutter-test` | `flutter::test [DIRECTORY] [ARG...]` | 任意 | Flutterテストを実行します。 | <ul><li>任意の作業directoryで実行できます。</li><li>追加のFlutter test引数を渡せます。</li></ul> | 追加引数を配列で渡します。 |
| `flutter-coverage` | `flutter::coverage [OUTPUT_DIRECTORY] [DIRECTORY]` | 任意 | FlutterテストとLCOV HTML生成を連続実行します。 | <ul><li>任意の作業directoryで実行できます。</li></ul> | `OUTPUT_DIRECTORY`の規定値は`coverage/html`です。 |
| `systemctl-path` | `systemd::file UNIT` | 任意 | systemd unitのファイルパス情報を表示します。 | <ul><li>`FragmentPath=VALUE`ではなく、`VALUE`だけを出力します。</li></ul> | Linux専用`FragmentPath`の値だけを出力します。 |
| `systemctl-depends` | `systemd::dependencies UNIT` | 任意 | systemd unitの依存情報を表示します。 | <ul><li>不要な`cat`へのpipeを除きます。</li><li>`After`、`Requires`、`Wants`の値だけを構造化して返します。</li></ul> | Linux専用`After`、`Requires`、`Wants`を返します。 |
| `systemctl-restart` | `systemd::restart UNIT` | 任意 | 管理者権限でunitを再起動します。 | <ul><li>未quoteのunit名を直接`sudo`へ渡さず、検証済みの一つのunit名を管理者実行helperへ渡します。</li></ul> | 操作自体に管理者権限が必要なため`-as-root`を付けません。Linux専用です。 |
| `systemctl-start` | `systemd::start UNIT` | 任意 | 管理者権限でunitを開始します。 | <ul><li>未quoteのunit名を直接`sudo`へ渡さず、検証済みの一つのunit名を管理者実行helperへ渡します。</li></ul> | 操作自体に管理者権限が必要なため`-as-root`を付けません。Linux専用です。 |
| `systemctl-stop` | `systemd::stop UNIT` | 任意 | 管理者権限でunitを停止します。 | <ul><li>未quoteのunit名を直接`sudo`へ渡さず、検証済みの一つのunit名を管理者実行helperへ渡します。</li></ul> | 操作自体に管理者権限が必要なため`-as-root`を付けません。Linux専用です。 |
| `systemctl-enable` | `systemd::enable UNIT` | 任意 | 管理者権限でunitを自動起動へ設定します。 | <ul><li>未quoteのunit名を直接`sudo`へ渡さず、検証済みの一つのunit名を管理者実行helperへ渡します。</li></ul> | 操作自体に管理者権限が必要なため`-as-root`を付けません。Linux専用です。 |
| `systemctl-disable` | `systemd::disable UNIT` | 任意 | 管理者権限でunitの自動起動を解除します。 | <ul><li>未quoteのunit名を直接`sudo`へ渡さず、検証済みの一つのunit名を管理者実行helperへ渡します。</li></ul> | 操作自体に管理者権限が必要なため`-as-root`を付けません。Linux専用です。 |
| `systemctl-is-enabled` | `systemd::status UNIT` | 任意 | unitの現在状態を表示します。 | <ul><li>自動起動の真偽だけを返す処理から、unitの現在状態を表示する処理へ変更します。</li></ul> | 検証済みのUNITへ`systemctl status`を実行し、人間向け状態と終了状態を返します。Linux専用です。 |
| `systemctl-list-service-units` | `systemd::service::list`<br>`systemd::service::list-running`<br>`systemd::service::list-failed` | 任意 | service unitを状態別に一覧表示します。 | <ul><li>全serviceの一覧に加え、runningとfailedだけを表示する処理を提供します。</li></ul> | listは停止中を含む全service、list-runningはrunning、list-failedはfailed状態を表示します。Linux専用です。 |
| `systemctl-list-service-unit-files` | `systemd::service::list-files` | 任意 | 全service unit fileを一覧表示します。 | — | Linux専用`systemctl list-unit-files --type=service`の出力と終了状態を返します。 |
| `file-write-as-root` | `file::write-text FILE TEXT` | 標準 | 文字列と改行をファイルへ上書きします。 | <ul><li>`echo`と`sudo tee`による直接上書きを、symlinkを拒否する原子的更新へ置き換えます。</li><li>既存fileのmetadataを保持します。</li><li>管理者権限を常に使用せず、permission不足の場合だけ使用します。</li></ul> | 対象fileと親directoryのpermissionを事前確認し、必要な場合だけ権限を昇格します。内容を変換せず原子的に更新します。 |
| `file-write` | `file::write-text FILE TEXT` | 標準 | 文字列と改行をファイルへ上書きします。 | <ul><li>`echo`による直接上書きを、symlinkを拒否する原子的更新へ置き換えます。</li><li>既存fileのmetadataを保持します。</li><li>permission不足の場合だけ管理者権限を使用します。</li></ul> | 対象fileと親directoryのpermissionを事前確認し、内容を変換せず原子的に更新します。 |
| `file-find-by-contents` | `file::find-by-content EXPRESSION [DIRECTORY] [MAX_PROCESSES] [BINARY_MODE]` | 任意 | file内容を並列検索して一致したpathを出力します。 | <ul><li>GNU `xargs -r`を使用するpipelineを、macOS、Ubuntu、Fedoraで同じ終了状態になる内部処理へ置き換えます。</li><li>改行区切りのpath出力をNUL区切りへ変更します。</li></ul> | `DIRECTORY`の規定値は`.`、`MAX_PROCESSES`の規定値は利用可能な論理CPU数、`BINARY_MODE`の規定値は`skip`です。`EXPRESSION`はBash EREではなく、検索backendが評価するEREです。pathはNUL区切りで出力します。 |
| 該当なし | `file::modified-time-unix-seconds FILE` | 標準 | fileの最終更新時刻をUnix時刻の秒整数で出力します。 | — | GNU版とBSD版で異なる`stat`のoptionをOS別実装へ隠し、macOS、Ubuntu、Fedoraで同じ形式と終了状態を返します。 |
| `file-find-last-by-name` | `file::latest-by-name EXPRESSION [DIRECTORY]` | 任意 | 名前に一致するfileのうち、更新日時が最新のpathを出力します。 | <ul><li>pathの文字列順で最後の行を選ぶ処理を、`file::modified-time-unix-seconds`による更新日時の比較へ置き換えます。</li><li>空白を含むpathを`awk`で分割する処理を行いません。</li><li>`DIRECTORY`の規定値を`.`にします。</li></ul> | 「latest」は最終更新日時が最も新しいことを表します。同時刻の場合はbyte単位のpath順で結果を一意に決めます。pathは変換せず一行で出力します。 |
| `file-replace-or-append-line-as-root` | `file::replace-text-or-append FILE EXPRESSION TEXT` | 既存 | 正規表現に一致する行をすべて削除し、一行を管理者権限で末尾へ追加します。 | <ul><li>`grep -E`と`sed`の組合せを、Bash EREによる原子的更新へ置き換えます。</li><li>各行の全一致を置換し、一件も一致しない場合だけ末尾へ追加します。</li><li>TEXTをliteralとして扱います。</li><li>管理者権限を常に使用せず、permission不足の場合だけ使用します。</li></ul> | `EXPRESSION`はBash ERE、`TEXT`はliteralです。対象fileと親directoryのpermissionを事前確認し、metadataを保持して原子的に更新します。 |
| `file-replace-or-append-line` | `file::replace-text-or-append FILE EXPRESSION TEXT` | 既存 | 正規表現に一致する箇所を置換し、一件も一致しない場合は一行を末尾へ追加します。 | <ul><li>`grep -E`と`sed`の組合せを、Bash EREによる原子的更新へ置き換えます。</li><li>各行の全一致を置換します。</li><li>TEXTをliteralとして扱います。</li></ul> | `EXPRESSION`はBash ERE、`TEXT`はliteralです。permissionを事前確認し、metadataを保持して原子的に更新します。 |
| `symlink-create` | `symlink::create SOURCE LINK` | 標準 | 実在パスの絶対パスを指すシンボリックリンクを強制更新します。 | <ul><li>空directoryを`rmdir`して置換する処理を行いません。</li><li>既存の通常fileとdirectoryを置換せず、既存symlinkだけを置換します。</li></ul> | 既存symlinkだけを置換し、通常fileとdirectoryを削除しません。permission不足の場合だけ管理者権限を使用します。 |
| `symlink-remove` | `symlink::remove PATH` | 標準 | シンボリックリンクを削除します。 | <ul><li>対象種別を確認せず管理者権限で`unlink`する処理を、symlinkだけを削除する処理へ変更します。</li><li>管理者権限を常に使用せず、permission不足の場合だけ使用します。</li></ul> | 対象がsymlinkの場合だけ削除します。親directoryのpermissionを事前確認します。 |
| `gpg-decrypt` | `gpg::decrypt PATH` | 任意 | GPGファイルを復号して標準出力へ書きます。 | <ul><li>復号結果の後へ追加の改行を出力しません。</li></ul> | GPGの復号結果と終了状態を返し、余分な改行を加えません。 |
| `gpg-public-key`（先の定義） | `gpg::public-key::armor [FINGERPRINT]` | 任意 | 指定鍵または最初の秘密鍵に対応する公開鍵をASCII armor形式で出力します。 | — | `FINGERPRINT`を省略した場合は、最初の秘密鍵に対応する公開鍵を出力します。 |
| `gpg-secret-key` | `gpg::secret-key::fingerprints` | 任意 | 最初の秘密鍵fingerprintを出力します。 | <ul><li>最初の秘密鍵fingerprintだけでなく、すべての秘密鍵fingerprintを出力します。</li></ul> | 全fingerprintを一行ずつ出力します。 |
| `gpg-keypair` | `gpg::secret-key::list` | 任意 | 秘密鍵一覧をGPGの人間向け形式で表示します。 | — | GPGの人間向け一覧をそのまま返します。 |
| `gpg-public-key`（後の定義） | `gpg::public-key::armor [FINGERPRINT]` | 任意 | 指定した鍵または最初の秘密鍵に対応する公開鍵をASCII armor形式で出力します。 | — | `FINGERPRINT`を省略した場合は、最初の秘密鍵に対応する公開鍵を出力します。 |
| `net-test-dns` | `net::dns::test NAME` | 任意 | 名前解決が成功するか確認します。 | <ul><li>OSごとの名前解決command差を内部で吸収します。</li><li>人間向け検索結果を返さず、成否を終了状態で返します。</li></ul> | 標準出力へ書かず、名前解決に成功した場合は終了状態0を返します。 |
| `net-test-connection` | `net::tcp::test HOST PORT [TIMEOUT_SECONDS]` | 任意 | TCP接続可能性を確認します。 | <ul><li>`nc -zv`の人間向け出力を返さず、接続可否を終了状態だけで返します。</li><li>無期限に待つ処理へ10秒のtimeoutを設定します。</li></ul> | `TIMEOUT_SECONDS`の規定値は10です。出力せず、接続可能なら終了状態0を返します。 |
| `distro-name` | `system::kernel-name`<br>`system::distribution-name` | 標準 | Linux distribution IDを`os-release`またはpackage managerから推定します。 | <ul><li>`/etc/os-release`をshell codeとして`source`せず、dataとして解析します。</li><li>`os-release`がない場合にpackage managerからdistributionを推定する処理を行いません。</li><li>kernel種別とLinux distribution IDを個別に取得します。</li></ul> | `darwin`、`linux`、`unknown`を返し、Linuxの`os-release`をデータとして解析します。ファイルを`source`せずpackage managerから推定しません。 |
| `user-add-to-group` | `user::add-to-group GROUP [USER]` | 標準 | 利用者を補助グループへ追加します。 | <ul><li>Linuxの`usermod`固定処理を、macOS、Ubuntu、FedoraのOS別処理へ置き換えます。</li></ul> | `USER`の規定値は現在の実効利用者です。操作自体に管理者権限が必要なため`-as-root`を付けません。 |
| `net-active-interface` | `net::interface::default` | 標準 | Linuxのdefault routeからインターフェース名を出力します。 | <ul><li>Linuxの`ip`直接実行を、macOS、Ubuntu、FedoraのOS別default route処理へ置き換えます。</li></ul> | OS別実装から一つの名前を出力します。 |
| `net-ipv4` | `net::ip::private-v4 [INTERFACE]` | 標準 | interfaceで優先度が最も高いprivate IPv4 addressを一つ出力します。 | — | `INTERFACE`を省略した場合はdefault interfaceを使用します。OS別のaddress優先順位に従い、RFC 1918範囲のprimary addressだけを出力します。 |
| `net-ipv6` | `net::ip::private-v6 [INTERFACE] [EXCLUDED_PREFIXES]` | 標準 | interfaceで優先度が最も高いprivate IPv6 addressを一つ出力します。 | <ul><li>固定prefixの除外を任意指定できる引数へ変更します。</li><li>複数addressではなくprimary addressだけを出力します。</li></ul> | `INTERFACE`を省略した場合はdefault interfaceを使用します。`EXCLUDED_PREFIXES`の規定値は`fe80,fda6`です。`fe80`はlink-local addressをrouted private addressとして選ばないために除外します。`fda6`は参照環境の補助的なULAをprimaryとして選ばないために除外し、別の環境では上書きできます。残るULA範囲`fc00::/7`からOS別の優先順位で一つを選びます。 |
| `user-dirs-create-english-link` | `user::directory::create-english-links [HOME_DIRECTORY]` | 任意 | 現在localeのXDG user directoryへ英語名のシンボリックリンクを作ります。 | <ul><li>日本語localeの固定対応を、`xdg-user-dir`が返す現在localeのdirectoryへ変更します。</li><li>localized directoryを作成する`xdg-user-dirs-update --force`を行いません。</li><li>localized directoryが存在しない項目は失敗せず処理を続けます。</li><li>既存の英語directoryは内容をlocalized directoryへ上書きmergeしてから削除します。</li></ul> | `HOME_DIRECTORY`の規定値は`$HOME`です。標準XDG項目を反復し、`xdg-user-dir`でlocalized pathを解決します。対象が存在しなければcontinueします。英語directoryが存在する場合は隠し項目を含む全内容を上書きmergeし、成功後に英語directoryを削除して同じpathへsymlinkを作ります。localized directoryは作成しません。 |
| `_android-build-tools-latest-version` | `android::build-tools::versions`<br>`android::build-tools::latest-version` | 任意 | 利用可能なAndroid build-toolsの安定版一覧または最新安定版を出力します。 | <ul><li>`sdkmanager`の人間向け一覧から文字列順で最後の値を選ぶ処理を、package metadataの版解析へ置き換えます。</li></ul> | `versions`はsemantic version順に一行ずつ出力します。`latest-version`は同じ一覧の最新値を出力します。導入関数が版を省略した場合は`latest-version`を使用します。 |
| `golang-installable-versions` | `go::version::list`<br>`go::version::latest` | 任意 | 実行環境へ導入できるGoの安定版一覧または最新安定版を出力します。 | <ul><li>Ubuntuのpackage名と人間向けapt出力の解析を、OS別package metadataの解析へ置き換えます。</li><li>package名らしい文字列ではなく、検証済みのsemantic versionを出力します。</li></ul> | macOS、Ubuntu、Fedoraのproviderから安定版を取得し、semantic version順に一行ずつ出力します。`latest`は同じ一覧の最新値を返します。 |
| `ruby-latest-version` | `ruby::version::list`<br>`ruby::version::latest` | 任意 | 導入できるRubyの安定版一覧または最新安定版を出力します。 | <ul><li>rbenvの表示順で最後の値を選ぶ処理を、semantic versionの解析と安定版の判定へ置き換えます。</li></ul> | `list`はpreview版を除いてsemantic version順に一行ずつ出力します。`latest`は同じ一覧の最新値を返します。導入関数が版を省略した場合は`latest`を使用します。 |
| `rosetta-install` | `rosetta::install` | 任意 | 必要な場合にlicenseへ自動同意してRosettaを導入します。 | <ul><li>既に利用可能な場合も常にinstallerを実行する処理を、必要性の検査後に実行する処理へ変更します。</li></ul> | Apple Silicon MacでRosettaが未導入の場合だけ、公式commandへlicense自動同意optionを付けて実行します。Intel Macと導入済み環境では何も変更せず成功します。 |
| `net-gateway` | `net::gateway::default` | 標準 | default routeのgatewayを出力します。 | <ul><li>Linuxの`ip`直接実行を、macOS、Ubuntu、FedoraのOS別default route処理へ置き換えます。</li></ul> | OS別実装からアドレスだけを出力します。 |
| `net-dns` | `net::dns::servers` | 標準 | 設定済みのDNS serverを出力します。 | <ul><li>Linuxの`resolvectl`直接実行を、macOS、Ubuntu、FedoraのOS別DNS設定取得へ置き換えます。</li><li>IPv4 addressだけでなく、IPv4とIPv6のDNS serverを出力します。</li></ul> | OS設定からIPv4とIPv6のaddressを一行ずつ出力します。 |
| `swap-show` | `swap::list` | 任意 | Linuxの有効なswapを表示します。 | — | Linux専用`swapon`の人間向け出力を返します。 |
| `memory-total-gb` | `mem::total-bytes`<br>`mem::total-gibibytes` | 標準 | 物理メモリーとswapの合計容量を取得します。 | <ul><li>`/proc/meminfo`の直接解析を、macOS、Ubuntu、FedoraのOS別容量取得へ置き換えます。</li><li>物理memoryとswapの合計を整数GiBへ切り捨てる処理に加え、byte整数と小数第2位までのGiBを出力します。</li></ul> | byte関数は0以上の整数を出力します。GiB関数は`1 GiB = 1,073,741,824 bytes`として小数第2位まで出力します。 |
| `utm-open` | `utm::open` | 任意 | UTMアプリを起動します。 | — | macOS専用UTMアプリを起動します。 |
| `mozc-config` | `mozc::config::open` | 任意 | Mozc設定画面を開きます。 | — | Linuxデスクトップ用設定画面を起動します。 |
| `file-close` | `file::release FILE [TIMEOUT_SECONDS]` | 任意 | fileを使用中のprocessを終了して解放します。 | <ul><li>最初からSIGKILLを送らず、保持processへ先にSIGTERMを送ります。</li><li>固定0.5秒のsleepを、100ミリ秒間隔の解放確認へ置き換えます。</li><li>timeoutまでに解放されないprocessだけへSIGKILLを送ります。</li><li>timeoutの既定値を2秒にします。</li></ul> | `serial::release`と同じ終了手順を使用します。signal permissionが不足する場合だけ管理者権限を使用し、SIGKILL後も使用中なら終了状態75を返します。 |
| `net-ip-global` | `net::ip::public` | 任意 | `ifconfig.me`から公開IP addressを取得します。 | <ul><li>案内文を標準出力へ書かず、IP addressだけを出力します。</li><li>応答が一つの正しいIPv4またはIPv6 addressであることを検証します。</li></ul> | 接続先は参照元と同じ`ifconfig.me`です。`curl`を優先し、なければ`wget`を使用します。 |
| `screen-kill-all` | `screen::kill-all` | 任意 | 全GNU Screen processを管理者権限で終了します。 | — | 操作自体が全利用者のprocessを対象にするため、`-as-root`を付けず管理者権限で`pkill screen`を実行します。 |
| `archive-expand` | `archive::extract [PATH]` | 任意 | directory以下の全archiveを再帰抽出します。 | <ul><li>各archiveを事前検査する`archive::extract-file`へ委譲します。</li></ul> | `PATH`の規定値は`.`です。通常fileなら一件を、directoryなら配下の対応archiveを再帰列挙して、それぞれ既定の派生directoryへ抽出します。 |
| `git-reset-prev` | `git::commit::discard [DIRECTORY]` | 任意 | 未commitの変更をstashへ保存し、最新commitとその変更を現在branchから破棄します。 | — | 参照元と同じ順序でstashを作成し、`git reset --hard HEAD^`を実行します。対象は既定で`HEAD`であるため、関数名へ`latest`を含めません。 |
| `git-reset-origin` | `git::reset-remote [REMOTE] [DIRECTORY]` | 任意 | 現在branchをremoteの同名branchへhard resetします。 | <ul><li>固定remoteの`origin`を任意指定できるようにします。</li><li>全remoteではなく対象remoteだけをfetchします。</li></ul> | `REMOTE`の規定値は`origin`です。対象remoteをfetchし、現在branchを`REMOTE/CURRENT_BRANCH`へ`git reset --hard`で一致させます。 |
| `git-pull-base-branch` | `git::pull-base-branch [BASE_BRANCH] [DIRECTORY]` | 任意 | 基準branchを更新し、元のbranchをrebaseします。 | — | `BASE_BRANCH`の規定値は`main`です。参照元と同じくbranchを切り替えて`origin`から更新し、元のbranchへ戻ってrebaseします。 |
| `docker-stop-all` | `docker::container::stop-all` | 任意 | 実行中の全containerを停止します。 | — | `docker ps -q`が返す全containerを停止し、対象がなければ成功します。 |
| `_docker-remove-all-containers` | `docker::container::remove-all` | 任意 | 全containerを強制削除します。 | <ul><li>改行区切りのIDをcommand substitutionへ展開せず、一件ずつ引数として渡します。</li></ul> | 全container IDへ`docker rm --force`を実行する公開関数です。 |
| `_docker-remove-all-volumes` | `docker::volume::remove-all` | 任意 | 全Docker volumeを強制削除します。 | <ul><li>改行区切りのIDを一件ずつ安全に処理します。</li></ul> | 全volume名へ`docker volume rm --force`を実行する公開関数です。 |
| `docker-remove-all` | `docker::remove-all` | 任意 | 全containerと全volumeを強制削除します。 | — | `docker::container::remove-all`の後に`docker::volume::remove-all`を実行します。途中で失敗した場合はその終了状態を返します。 |
| `_adb-pull-with-select` | `adb::device::select-and-pull PATH... [-OutputDirectory OUTPUT_DIRECTORY] [-Serial SERIAL]` | 任意 | 候補から一つを対話選択して端末から取得します。 | <ul><li>改行区切りtextとBash 4の配列構文を、個別のpath引数へ置き換えます。</li><li>shell組込み`select`を`prompt::select-one`へ置き換えます。</li></ul> | `OUTPUT_DIRECTORY`の規定値は`.`です。`SERIAL`を省略した場合はADBの既定の端末選択を使用します。 |
| 該当なし | `adb::device::bootloader::enter [-Serial SERIAL]` | 任意 | bootloaderへ再起動します。 | — | `adb reboot bootloader`を実行します。`SERIAL`を省略した場合はADBの既定選択を使用します。 |
| `adb-bootloader-unlock` | `adb::device::bootloader::unlock [-Serial SERIAL]` | 任意 | bootloaderへ再起動して端末lockを解除します。 | <ul><li>固定7秒のsleepを、`fastboot getvar version`が成功するまでの待機へ置き換えます。</li></ul> | bootloaderへ再起動した後、`fastboot getvar version`を250ミリ秒間隔で実行し、成功してから`fastboot flashing unlock`を実行します。待機上限は30秒で、超過時は終了状態75を返します。再起動後はADB接続を待ちます。`SERIAL`はADBとfastbootの両方へ渡します。 |
| `adb-disable-verity` | `adb::device::verity::disable [-Serial SERIAL]` | 任意 | dm-verityを無効にして端末を再起動します。 | — | root取得、verity無効化、再起動、ADB接続待機を順に実行します。 |
| `adb-remount` | `adb::device::partition::remount [-Serial SERIAL]` | 任意 | root権限を取得してsystem領域を書込み可能にします。 | — | `adb root`、`adb remount`、root filesystemのread-write remountを順に実行します。 |
| `adb-pkg-info` | `adb::device::build::fingerprint [-Serial SERIAL]`<br>`adb::device::build::date [-Serial SERIAL]`<br>`adb::device::slot::suffix [-Serial SERIAL]`<br>`adb::device::build::kernel-version [-Serial SERIAL]` | 任意 | 端末のbuild、slot、kernel情報を個別に出力します。 | <ul><li>説明付きの複数項目を一括表示せず、propertyごとに値だけを返します。</li><li>端末側で`grep`するshell文字列を、検証済みの固定commandへ置き換えます。</li></ul> | 各関数は一つの値だけを出力します。`SERIAL`を省略した場合はADBの既定の端末選択を使用します。 |
| `adb-screencap-loop` | `adb::device::screen::capture-continuous [OUTPUT_DIRECTORY] [INTERVAL_SECONDS] [MAX_COUNT] [-Serial SERIAL]` | 任意 | screenshotを一定間隔で反復取得します。 | <ul><li>個人directory内の外部script実行を、`adb::device::screen::capture-once`の反復へ置き換えます。</li></ul> | `OUTPUT_DIRECTORY`の規定値は`./screencap-loop`、`INTERVAL_SECONDS`は1、`MAX_COUNT`は0です。0は明示停止まで反復することを表します。各保存pathを一行ずつ出力します。 |
| `adb-partition-hash` | `adb::device::partition::sha256 PARTITION [-Serial SERIAL]` | 任意 | root端末で指定partitionのSHA-256を出力します。 | <ul><li>PARTITIONを端末側shell文字列へ連結せず、`/dev/block/`配下の絶対pathとして検証します。</li></ul> | 許可文字だけで構成されたblock device pathを端末側`sha256sum`へ渡します。`SERIAL`を省略した場合はADBの既定選択を使用します。 |
| `systemcall-trace-by-cmd` | `syscall::trace-by-name NAME` | 任意 | 実行名に一致する最初のprocessへ`strace`を接続します。 | <ul><li>global変数`PID`を作らず、最初のPIDをlocal値として扱います。</li></ul> | `process::ids-by-name`の最初のPIDを`syscall::trace-by-pid`へ渡します。Linux専用です。 |
| `library-trace-by-cmd` | `lib::trace-by-name NAME` | 任意 | 実行名に一致する最初のprocessへ`ltrace`を接続します。 | <ul><li>global変数`PID`を作らず、最初のPIDをlocal値として扱います。</li></ul> | `process::ids-by-name`の最初のPIDを`lib::trace-by-pid`へ渡します。permission不足の場合だけ管理者権限で再実行します。 |
| `gdb-attach-by-cmd` | `gdb::attach-by-name NAME` | 任意 | 実行名に一致する最初のprocessへGDBを接続します。 | <ul><li>誤った診断変数名を修正し、最初のPIDをlocal値として扱います。</li></ul> | `process::ids-by-name`の最初のPIDを`gdb::attach-pid`へ渡します。 |
| `jenkins-restart` | `jenkins::restart` | 任意 | Jenkins serviceを管理者権限で再起動します。 | — | `systemd::restart jenkins.service`へ委譲するapplication固有関数です。Linux専用です。 |
| `sudo-keep-alive` | `sudo::start-keep-alive` | 任意 | 呼び出し元processが生存している間、sudo認証期限をbackgroundで更新します。 | <ul><li>無期限loopを親processの生存確認で終了する処理へ置き換えます。</li><li>更新間隔の引数と停止関数を提供しません。</li></ul> | 更新間隔は60秒に固定します。親processが終了した時点でbackground processも終了します。 |
| `env-import`（両定義） | `env::dotenv::import FILE` | 標準 | dotenv fileの値を現在processの環境変数へ取り込みます。 | <ul><li>`source`によるshell code実行を、dotenv構文のdata解析へ置き換えます。</li><li>`set -a`によるshell option変更を行いません。</li></ul> | 変数名、引用符、escape、commentを検証し、許可したdotenv構文だけを`printf -v`と`export`で設定します。 |
| `env-add-variable` | `env::set-variable NAME VALUE [SHELLS]` | 標準 | 環境変数をshell設定へ永続化し、現在processへ設定します。 | <ul><li>`eval`による値取得を行いません。</li><li>設定file末尾への重複追記を、managed blockの原子的更新へ置き換えます。</li><li>現在processへ適用する動作を固定し、切替引数を設けません。</li></ul> | `SHELLS`の規定値は`bash,zsh`です。変数名を検証し、VALUEをliteralとして永続化して現在processへexportします。 |
| `env-add-path` | `env::add-path PATH [SHELLS]` | 標準 | 実在directoryをPATHの末尾へ追加し、shell設定と現在processへ反映します。 | <ul><li>文字列包含による重複判定を、PATH要素の完全一致判定へ置き換えます。</li><li>設定file末尾への重複追記を、managed blockの原子的更新へ置き換えます。</li><li>追加位置を末尾、現在processへの適用とdirectory存在確認を有効へ固定します。</li></ul> | `SHELLS`の規定値は`bash,zsh`です。PATHが実在directoryであることを確認し、重複しない場合だけ末尾へ追加します。 |
| `symlink-create-to-local-bin` | `symlink::create-in-local-bin SOURCE [LINK_NAME] [DIRECTORY]` | 標準 | local bin directoryへsymbolic linkを作成します。 | — | `LINK_NAME`の規定値はSOURCEのbasename、`DIRECTORY`は`$HOME/.local/bin`です。directoryを作成して`symlink::create`へ委譲します。 |
| `ssh-dir-setup` | `ssh::setup-directory` | 任意 | `.ssh`を作成し、所有者とfile modeを一括設定します。 | — | 参照元と同じく`$HOME/.ssh`を作成して再帰chownし、directoryを700、通常fileを644、秘密鍵、config、authorized_keysを600にします。 |
| `net-test-google` | `net::ping [HOST] [ATTEMPTS] [TIMEOUT_SECONDS]` | 任意 | 指定hostへICMP echoを送信します。 | <ul><li>固定host、試行回数、無期限待機を上書き可能な既定値へ変更します。</li><li>BSD版とGNU版のping option差をOS別処理へ置き換えます。</li></ul> | `HOST`の規定値は`google.com`、`ATTEMPTS`は3、`TIMEOUT_SECONDS`は5です。 |
| `swap-disable-all` | `swap::disable-all` | 任意 | 有効な全swapを無効にします。 | — | 操作自体に管理者権限が必要なため`-as-root`を付けません。UbuntuとFedoraで`swapoff --all`を実行します。 |
| `swap-remove-all-files` | `swap::remove-all-files` | 任意 | 全swap fileを無効化し、永続設定とfileを削除します。 | <ul><li>swap file削除後も残る`fstab` entryを同じ処理で削除します。</li><li>途中失敗時に残りの対象へ進まず、診断と終了状態を返します。</li></ul> | 引数なしで全swap fileを対象にします。操作自体に管理者権限が必要なため`-as-root`を付けません。 |
| `swap-create` | `swap::create [SIZE_BYTES] [PATH]` | 任意 | swap fileを作成して有効化し、永続設定へ登録します。 | <ul><li>GiB単位の入力をbyte単位へ変更します。</li><li>SIZE_BYTESに8,589,934,592の規定値を追加します。</li></ul> | `SIZE_BYTES`の規定値は8 GiB、`PATH`は`/swapfile`です。操作自体に管理者権限が必要なため`-as-root`を付けません。 |
| `sleep-disable` | `system::disable-sleep` | 標準 | system sleepを無効にします。 | <ul><li>macOS固定処理をOS別処理へ置き換えます。</li></ul> | 操作自体に管理者権限が必要なため`-as-root`を付けません。macOS、Ubuntu、FedoraのOS別処理を使用します。 |
| `sleep-enable` | `system::enable-sleep` | 標準 | system sleepを有効にします。 | <ul><li>macOS固定処理をOS別処理へ置き換えます。</li></ul> | 操作自体に管理者権限が必要なため`-as-root`を付けません。固定した有効状態へ変更します。 |
| `timezone-offset-to-posix-format` | `time::posix-timezone OFFSET` | 標準 | UTC offsetをPOSIXの`TZ`文字列へ変換します。 | <ul><li>符号だけを反転する文字列処理を、`Z`または`±HH:MM`形式の構文解析へ置き換えます。</li><li>時と分の範囲を検証し、分を失わずPOSIX規則の符号へ変換します。</li></ul> | `Z`、`+00:00`、`-00:00`は`UTC0`を出力します。それ以外は時を00から23、分を00から59として検証します。`+09:30`は`UTC-9:30`、`-05:00`は`UTC+5`を出力します。 |
| `dir-merge` | `directory::merge SOURCE DESTINATION` | 標準 | SOURCEの全内容をDESTINATIONへ移動して統合します。 | <ul><li>競合を保持する`mv -n`を、SOURCE側で上書きする再帰mergeへ置き換えます。</li><li>globによる通常項目と隠し項目の別処理を、全directory entryを扱う処理へ置き換えます。</li></ul> | SOURCEとDESTINATIONを必須にします。DESTINATIONがなければ作成します。directory同士は再帰mergeし、競合するfileとsymbolic linkはSOURCE側で上書きします。symbolic linkは追跡しません。各項目を移動し、すべて成功した場合は空になったSOURCEを削除します。途中で失敗した場合は直ちに終了します。 |
| `datetimes-continuous` | `time::status-continuous` | 任意 | 起動後秒数とローカル時刻を3秒間隔で無期限に表示します。 | <ul><li>`/proc/uptime`とOSの`date`を、BashStockの起動後時計とローカル日時処理へ置き換えます。</li></ul> | 引数は受け取りません。参照元と同じ説明付きの二行を出力し、3秒待機して無期限に繰り返します。呼び出しprocessへ送られた終了signalで停止します。 |
| `dir-create-with-datetime` | `directory::create-with-date-time [DIRECTORY]` | 標準 | ローカル日時を名前にしたdirectoryを作成し、そのpathを出力します。 | <ul><li>OSの`date`ではなく`time::local-date-time-seconds-basic`を使用します。</li><li>同じ秒に同名directoryが存在する場合は連番を付けます。</li></ul> | `DIRECTORY`配下へ`YYYYMMDDTHHMMSS`形式のdirectoryを作ります。重複時は`-2`から始まる連番を付け、作成したpathを一行で出力します。 |
| `dir-clear` | `directory::clear [DIRECTORY]` | 任意 | directory直下の全項目を再帰削除します。 | <ul><li>空文字、filesystem root、home directory、symbolic linkを拒否します。</li><li>削除対象の事前列挙は行いません。</li></ul> | `DIRECTORY`自体は残し、隠し項目を含む直下の全項目を削除します。symbolic linkをdirectoryとして受け入れると、名前で示したlinkではなく別の場所にあるlink先の内容を削除するため拒否します。 |
| `storage-clear-trash` | `storage::clear-trash` | 任意 | 現在利用者のLinuxデスクトップのごみ箱を管理者権限で空にします。 | — | `$HOME/.local/share/Trash/files`と`$HOME/.local/share/Trash/info`の直下を管理者権限で削除します。削除対象の事前列挙と保持期間による選別は行いません。 |
| `file-find` | `path::find EXPRESSION [DIRECTORY]` | 任意 | directory以下でpathが正規表現に一致する項目を検索します。 | <ul><li>改行区切りの`find`出力と`grep`の組合せを、NUL区切りのpath処理へ置き換えます。</li></ul> | `EXPRESSION`は大文字と小文字を区別しないBash EREとして評価します。一致したpathをNUL区切りで出力します。 |
| `file-tree-with-contents` | `file::tree-with-contents [PATH] [MIN_DEPTH] [MAX_DEPTH]` | 任意 | directory構造とtext fileの内容をまとめて出力します。 | <ul><li>内部関数を呼出しごとに再定義せず、非公開関数として分離します。</li></ul> | `PATH`の規定値は`.`、`MIN_DEPTH`は1です。`MAX_DEPTH`を省略した場合は深さを制限しません。除外式、最大byte数、機密file判定は設けません。通常fileはMIME typeが`text/*`の場合だけ内容を出力し、directoryはpathを出力します。 |
| `_print_file` | `file::_print-text FILE` | 任意 | text fileのpathと内容を区切り付きで出力します。 | <ul><li>親関数内の動的な関数定義を、file moduleの非公開関数へ分離します。</li></ul> | `file --brief --mime-type`が`text/*`を返す通常fileだけを出力します。`file::tree-with-contents`から使用し、公開APIにはしません。 |
| `usb-find-partition` | `usb::partition::select` | 任意 | LinuxでUSB接続のpartitionを選び、device pathを出力します。 | — | partitionが一つなら自動選択し、複数なら詳細を表示して対話選択します。partitionがないUSB diskはdisk自体を候補にします。 |
| `usb-fix` | `usb::filesystem::repair` | 任意 | 選択したUSB filesystemをunmountして修復します。 | — | `usb::partition::select`で対象を選び、filesystemに応じて`fsck.fat -a`、`fsck.exfat -a`、または`fsck -y`を管理者権限で実行します。 |
| `usb-format-fat32` | `usb::filesystem::format-fat32` | 任意 | 選択したUSB partitionをFAT32で初期化します。 | — | `usb::partition::select`で対象を選び、unmountしてから管理者権限で`mkfs.vfat -F 32`を実行します。 |
| `screen-tty-usb` | `screen::open-serial DEVICE [BAUD_RATE] [LOG_FILE]` | 任意 | serial deviceをGNU Screenで開き、通信内容をfileへ記録します。 | <ul><li>USB device番号からpathを組み立てる処理を、明示されたdevice pathの使用へ置き換えます。</li></ul> | `BAUD_RATE`の規定値は115200です。`LOG_FILE`の規定値は`${TTY_LOG_DIR:-.}`配下の日時付きfileです。GNU Screenを管理者権限で対話起動します。 |
| `git-pull-upstream-base-branch` | `git::rebase-base-branch [BRANCH] [REMOTE] [DIRECTORY]` | 任意 | remoteの基準branchを取得し、localの同名branchをrebaseします。 | — | `BRANCH`の規定値は`main`、`REMOTE`は`upstream`です。remoteをfetchし、基準branchへ切り替えて`REMOTE/BRANCH`へrebaseします。 |
| `repo-reset` | `repo::reset [DIRECTORY]` | 任意 | Google Repo workspaceの全projectへhard resetを実行します。 | — | 参照元と同じく`repo forall -c 'git reset --hard'`を実行します。全projectの未commit変更を破棄することをDocコメントへ明記します。 |
| `adb-wake-lock` | `adb::wake::lock [TAG] [-Serial SERIAL]` | 任意 | root端末のsysfs wake lockを取得します。 | <ul><li>固定tagを任意指定できるようにします。</li></ul> | `TAG`の規定値は`debug`です。`adb root`の後、`/sys/power/wake_lock`へtagを書き込みます。`SERIAL`を省略した場合はADBの既定選択を使用します。 |
| `adb-wake-unlock` | `adb::wake::unlock [TAG] [-Serial SERIAL]` | 任意 | root端末のsysfs wake lockを解放します。 | <ul><li>固定tagを任意指定できるようにします。</li></ul> | `TAG`の規定値は`debug`です。`adb root`の後、`/sys/power/wake_unlock`へtagを書き込みます。`SERIAL`を省略した場合はADBの既定選択を使用します。 |
| `adb-cat-wake-lock` | `adb::wake::list [-Serial SERIAL]` | 任意 | root端末のsysfs wake lock状態を表示します。 | — | `adb root`の後、`/sys/power/wake_lock`の内容を出力します。`SERIAL`を省略した場合はADBの既定選択を使用します。 |
| `selinux-generate-rule` | `selinux::generate-rule INPUT_FILE [OUTPUT_FILE]` | 任意 | 監査ログからSELinux許可規則を生成します。 | <ul><li>出力先を任意指定できるようにします。</li></ul> | `OUTPUT_FILE`の規定値は`INPUT_FILE`と同じdirectoryの`selinux.txt`です。`avc:`を含む行を`audit2allow`へ渡し、規則をfileへ書きます。 |
| `gnome-terminal-bash` | `terminal::gnome-bash [COMMAND] [ARG...]` | 任意 | GNOME Terminalで新しい対話的Bash processを起動します。 | <ul><li>利用者のcommand文字列を`bash -c`へ連結せず、commandと引数を個別に渡します。</li></ul> | `COMMAND`を省略した場合は`gnome-terminal -- bash -i`を実行します。指定した場合は固定したBash scriptがcommandと引数を配列として実行し、完了後に`exec bash -i`で対話shellを開始します。 |
| `editor-to-vscode` | `shell::editor::set-default [SHELLS]` | 任意 | BashとZshの既定editorを設定します。 | <ul><li>対象shellを任意指定できるようにします。</li></ul> | editorの規定値はVS Codeの`code --wait`、`SHELLS`の規定値は`bash,zsh`です。対象の起動fileへ`export EDITOR="code --wait"`を重複なく設定します。 |
| `env-register` | `env::dotenv::register FILE [SHELLS]` | 任意 | dotenv fileを今後起動するBashとZshでも自動的に読み込みます。 | <ul><li>相対pathを正規化した絶対pathへ置き換えます。</li><li>対象shellを任意指定できるようにします。</li></ul> | `SHELLS`の規定値は`bash,zsh`です。shell起動時にBashStockを読み込んでから`env::dotenv::import FILE`を一度だけ実行する行を各起動fileへ設定します。dotenvはshell codeとしてsourceしません。利用者の全shellで共通する環境変数を対象とし、projectごとに異なる環境変数には使用しません。 |
| `_dict-ensure-file`<br>`_dict-escape-key`<br>`_dict-replace-key`<br>`_dict-insert-key`<br>`dict-set-value` | `plist::set FILE KEY VALUE` | 任意 | plist dictionaryのkeyへ文字列値を設定します。 | <ul><li>正規表現escapeと行単位の置換・挿入を、macOSの`plutil`によるplist操作へ置き換えます。</li></ul> | fileがなければ空dictionaryのplistを作成します。既存keyは置換し、存在しないkeyは追加します。処理の前後で`plutil -lint`を実行するため、個別の文字列編集関数は公開しません。`key-binding-disable-option-t`はこの関数で`DefaultKeyBinding.dict`を更新します。 |
| `textproto-insert` | `textproto::set-scalar FILE FIELD VALUE` | 任意 | textprotoのtop-level scalar fieldを置換または追記します。 | <ul><li>正規表現による行置換を、comment、文字列、入れ子を区別する構文処理へ置き換えます。</li></ul> | top-levelに一つだけ存在できるscalar fieldを対象にします。既存fieldは置換し、存在しなければ末尾へ追記して、更新後に構文を検証します。 |
| `autocomplete-to-ignore-case`<br>`zsh-autocomplete-to-ignore-case`<br>`bash-autocomplete-to-ignore-case` | `shell::completion::enable-ignore-case [SHELLS]` | 任意 | BashとZshの補完で大文字と小文字を区別しないように設定します。 | <ul><li>三つの公開関数を一つへ統合します。</li><li>対象shellを任意指定できるようにします。</li></ul> | `SHELLS`の規定値は`bash,zsh`です。Bashは`.inputrc`へ`set completion-ignore-case on`、Zshは`.zshrc`へ対応する`zstyle`を重複なく設定します。 |
| `git-rm-credentials` | `git::credentials::remove` | 任意 | 保存されたGit資格情報fileを削除します。 | — | 参照元と同じく`~/.git-credentials`を存在しない場合も成功として削除します。 |
| `git-enable-origin-all-fetch` | `git::config::enable-origin-all-fetch [DIRECTORY]` | 任意 | originの全branchを取得するrefspecを現在repositoryへ設定します。 | — | `remote.origin.fetch`へ`+refs/heads/*:refs/remotes/origin/*`を設定します。 |
| `git-set-prune-fetch` | `git::config::enable-prune-fetch` | 任意 | fetch時のpruneをglobal設定で有効にします。 | — | `git config --global fetch.prune true`を実行します。 |
| `git-set-default-branch-to-main` | `git::config::set-default-branch [BRANCH]` | 任意 | 新規repositoryの既定branch名を設定します。 | <ul><li>固定値`main`を任意指定できる引数の規定値にします。</li></ul> | `BRANCH`の規定値は`main`です。`git config --global init.defaultBranch BRANCH`を実行します。 |
| `git-set-rebase-on-pull` | `git::config::enable-rebase-on-pull` | 任意 | pull時のrebaseをglobal設定で有効にします。 | — | `git config --global pull.rebase true`を実行します。 |
| `git-set-email` | `git::config::set-email [EMAIL]` | 任意 | global Gitメールアドレスを設定します。 | <ul><li>引数による指定を追加します。</li></ul> | 引数、`GIT_EMAIL`環境変数、利用可能な制御端末からの対話入力の順に値を選び、`user.email`へ設定します。 |
| `git-set-username` | `git::config::set-username [USERNAME]` | 任意 | global Git表示名を設定します。 | <ul><li>引数による指定を追加します。</li></ul> | 引数、`GIT_USERNAME`環境変数、利用可能な制御端末からの対話入力の順に値を選び、`user.name`へ設定します。 |
| `git-set-http-buffer-to-500-mb` | `git::config::set-http-buffer [SIZE_BYTES]` | 任意 | global Git HTTP送信bufferのbyte数を設定します。 | <ul><li>固定値500 MiBを任意指定できる引数の規定値にします。</li></ul> | `SIZE_BYTES`の規定値は500 MiBに相当する524288000です。0以上の整数を検証し、`git config --global http.postBuffer SIZE_BYTES`を実行します。 |
| `git-set-store-credential-with-gpg` | `git::config::use-gpg-credential-store` | 任意 | Git Credential Managerの保存先をGPGへ設定します。 | — | `git config --global credential.credentialStore gpg`を実行し、公開鍵登録の案内を表示します。 |
| `git-set-store-credential-with-manager` | `git::config::use-credential-manager` | 任意 | global Git credential helperをmanagerへ設定します。 | — | `git config --global credential.helper manager`を実行します。 |

| `pass-init-gpg` | `pass::store::remove [STORE_DIRECTORY]`<br>`pass::store::init [FINGERPRINT] [STORE_DIRECTORY]` | 任意 | 既存の秘密情報storeを削除する操作と、GPG鍵で`pass`を初期化する操作を個別に実行します。 | <ul><li>storeの削除と`pass init`を独立した関数へ分けます。</li><li>`FINGERPRINT`の規定値として最初の秘密鍵のfingerprintを使用します。</li><li>`STORE_DIRECTORY`の規定値として`PASSWORD_STORE_DIR`、未設定時は`$HOME/.password-store`を使用します。</li></ul> | `pass::store::remove`は確認せず対象storeを再帰削除します。`pass::store::init`はstoreを削除せず、`GPG_TTY`を利用可能な制御端末へ設定してから`pass init`を実行します。 |
| `gpg-generate-key` | `gpg::key::generate [-Usage USAGE] [-Algorithm ALGORITHM] [-Expires EXPIRES] [-UserId USER_ID] [-Pinentry \| -PassphraseFd FD]` | 任意 | 主鍵と副鍵からなるGPG鍵を生成します。 | <ul><li>鍵用途、algorithm、期限、利用者IDをoptionで上書きできるようにします。</li><li>passphraseをcommand引数へ含めず、pinentryまたは保護されたfile descriptorから受け取ります。</li><li>optionを省略した場合は、Ed25519署名主鍵、cv25519暗号化副鍵、5年期限、passphraseなしを使用します。</li><li>利用者IDを省略した場合はGitの利用者名とメールアドレスから生成します。</li></ul> | GnuPGのbatch parameter fileを保護された一時fileへ作成し、主鍵と副鍵を一回の操作で生成します。passphrase用file descriptorは読取り後に値を保持しません。 |
| `gpg-setup-new` | `gpg::setup [OPTIONS...]` | 任意 | GPG鍵生成、`pass`導入と初期化、Git資格情報設定、公開鍵表示を一括実行します。 | <ul><li>未定義のGit設定関数をBashStockの公開関数へ置き換えます。</li><li>受け取ったoptionを対応する個別関数へ渡せるようにします。</li><li>各処理が失敗した場合は、その時点で後続処理を停止します。</li></ul> | `gpg::key::generate`、`pass::install`、`pass::store::init`、Git資格情報設定、Git署名設定、GPG公開鍵表示を順に実行します。個別関数も単独で利用できます。 |
| `ssh-generate-key-rsa` | `ssh::key::generate-rsa4096 [-Comment COMMENT] [-Output FILE] [-PassphraseFd FD]` | 任意 | 4096-bit RSA SSH鍵を生成し、公開鍵を表示します。 | <ul><li>既存鍵を無確認で削除せず、既存pathを上書きする前に制御端末で確認します。</li><li>COMMENT、出力先、passphrase入力をoptionで上書きできるようにします。</li><li>COMMENTの規定値は空文字列、FILEの規定値は`$HOME/.ssh/id_rsa`、passphraseの規定値は空文字列です。</li></ul> | 秘密鍵または公開鍵が既存の場合だけ上書き確認を行います。passphraseは保護されたfile descriptorから読み取り、processのcommand引数へ含めません。 |
| `ssh-generate-key-ed25519` | `ssh::key::generate-ed25519 [-Comment COMMENT] [-Output FILE] [-PassphraseFd FD]` | 任意 | Ed25519 SSH鍵を生成し、公開鍵を表示します。 | <ul><li>既存鍵を無確認で削除せず、既存pathを上書きする前に制御端末で確認します。</li><li>COMMENT、出力先、passphrase入力をoptionで上書きできるようにします。</li><li>COMMENTの規定値は空文字列、FILEの規定値は`$HOME/.ssh/id_ed25519`、passphraseの規定値は空文字列です。</li></ul> | 秘密鍵または公開鍵が既存の場合だけ上書き確認を行います。passphraseは保護されたfile descriptorから読み取り、processのcommand引数へ含めません。 |
| `ssh-kill-all` | `ssh::kill-all` | 任意 | 現在の利用者が実行しているすべてのSSH processを終了します。 | — | `pkill -u "$(id -un)" ssh`を実行します。通常のSSH接続、port forwarding、master processを区別せず対象にします。 |
| `net-ip-to-static` | `net::ip::set-static [-Interface INTERFACE] [-Address ADDRESS] [-PrefixLength PREFIX_LENGTH] [-Gateway GATEWAY] [-Dns DNS_SERVERS] [-HostName HOST_NAME] [-File FILE] [-Renderer RENDERER]` | 既存 | Ubuntu Netplanの現在設定を静的IPv4設定へ置き換えて適用します。 | <ul><li>外部scriptのdownloadと実行を、review済みのlocal実装へ置き換えます。</li><li>未quoteの値、複数fileを一つのpathとして扱う処理、固定renderer、誤ったnetmask表示を除きます。</li><li>INTERFACE、ADDRESS、PREFIX_LENGTH、GATEWAY、HOST_NAMEの規定値は現在の設定値です。</li><li>DNS_SERVERSの規定値は`1.1.1.1,8.8.8.8`です。</li><li>FILEを省略した場合は、Netplan設定fileが一つだけ存在するときにそのfileを使用します。</li><li>RENDERERを省略した場合はNetplanの選択を使用します。</li></ul> | Ubuntuで`ip`から現在値を取得し、IPv4 address、prefix長、gateway、DNS server、host nameを検証します。複数のNetplan設定fileがある場合は`-File`を必須とし、生成内容をNetplanで検証してから対象fileへ書き込み、host nameとNetplanを適用します。 |
| `net-fix-resolv-from-systemd` | `net::dns::use-systemd-resolved` | 任意 | DNS管理方式をsystemd-resolvedへ切り替えます。 | <ul><li>`/etc/resolv.conf`が空の場合だけ処理する条件をなくします。</li><li>systemd-resolvedを有効化して起動します。</li><li>必要な場合だけ既存の`/etc/resolv.conf`をbackupします。</li><li>link設定後にDNS管理方式と名前解決を検証します。</li></ul> | `/etc/resolv.conf`を`/run/systemd/resolve/stub-resolv.conf`へのsymbolic linkにします。serviceの起動状態だけで管理方式を判定せず、link先とsystemd-resolvedの状態を組み合わせて確認します。 |
| `net-fix-resolv-from-network-manager` | `net::dns::use-network-manager` | 任意 | DNS設定と`/etc/resolv.conf`をNetworkManagerが直接管理する方式へ切り替えます。 | <ul><li>`/etc/resolv.conf`が空の場合だけ処理する条件をなくします。</li><li>systemd-resolvedをDNS backendへ固定するNetworkManager設定をlocal drop-inで上書きします。</li><li>必要な場合だけ既存の`/etc/resolv.conf`をbackupします。</li><li>link設定後にDNS管理方式と名前解決を検証します。</li></ul> | NetworkManagerの`dns=default`と`rc-manager=symlink`をlocal drop-inへ設定し、`/etc/resolv.conf`を`/run/NetworkManager/resolv.conf`へのsymbolic linkにします。systemd-resolvedが同時に起動していても、NetworkManagerの有効設定とlink先から管理方式を判定します。 |
| `net-fix-resolv-from-google` | `net::dns::use-google` | 任意 | 現在のDNS管理方式を維持してGoogle Public DNSを設定します。 | <ul><li>`/etc/resolv.conf`への直接書込みを行いません。</li><li>IPv4 DNSに`8.8.8.8`と`8.8.4.4`、IPv6 DNSに`2001:4860:4860::8888`と`2001:4860:4860::8844`を設定します。</li><li>systemd-resolvedとNetworkManagerで異なる設定処理を使用します。</li><li>設定反映後にDNS設定と名前解決を検証します。</li></ul> | systemd-resolved管理では`/etc/systemd/resolved.conf.d/`のlocal drop-inを使用します。NetworkManager管理ではVPN以外のactive connection profileへ`ipv4.dns`、`ipv4.ignore-auto-dns`、`ipv6.dns`、`ipv6.ignore-auto-dns`を設定して再適用します。管理方式が不明な場合は変更せず終了状態69を返します。 |
| `git-set-store-credential-with-osxkeychain` | `git::config::use-osx-keychain` | 任意 | global Git credential helperをmacOS Keychainへ設定します。 | — | macOSで`git config --global credential.helper osxkeychain`を実行します。 |
| `git-credential-manager-latest-url` | `git-credential-manager::version::list`<br>`git-credential-manager::_artifact-url [VERSION]` | 任意 | Git Credential Managerの利用可能な版一覧と、OS・architectureに対応するartifact URLを取得します。 | <ul><li>GitHub APIのJSONを文字列処理せずJSON parserで読み取ります。</li><li>amd64版debへの固定をやめ、実行OSとarchitectureからartifactを選びます。</li><li>VERSIONの規定値として最新の安定版を使用します。</li></ul> | 版一覧を公開関数として返し、artifact URLの決定は導入処理が使用する非公開関数へ分けます。GitHub release metadataに一致するartifactがなければ終了状態69を返します。 |
| `git-credential-manager-install` | `git-credential-manager::install [VERSION]` | 任意 | 実行環境に対応するGit Credential Managerを導入します。 | <ul><li>Linux amd64のdebだけを扱う処理を、対応OSとarchitectureに応じたartifactの導入へ置き換えます。</li><li>VERSIONの規定値として最新の安定版を使用します。</li></ul> | `git-credential-manager::_artifact-url`から取得した公式artifactを一時fileへdownloadし、OS別の導入処理を実行します。呼び出し側によるhash指定は要求しません。 |

## 採用セットアップ関数

| 参照元の関数 | BashStockの関数 | 区分 | 機能 | 変更点 | 設計 |
|---|---|---|---|---|---|
| `_git-setup-common` | `git::config::setup [EMAIL] [USERNAME]` | 任意 | 利用者情報と標準的なglobal Git設定をまとめて適用します。 | <ul><li>メールアドレスと表示名を引数でも指定できるようにします。</li></ul> | `git::config::set-email`、`git::config::set-username`、`git::config::set-default-branch`、`git::config::enable-rebase-on-pull`、`git::config::enable-prune-fetch`を順に実行します。 |

## DNS管理の契約

DNS管理方式の判定は非公開関数`net::dns::_manager`が行い、`systemd-resolved`、`network-manager`、`unknown`のいずれかを標準出力へ書きます。判定では`/etc/resolv.conf`のlink先、NetworkManagerの有効なDNS pluginと`rc-manager`、systemd-resolvedとの連携状態を確認します。`systemctl is-active systemd-resolved`の結果だけでは判定しません。公開関数からDNS管理方式を取得する要件が生じた場合は、同じ契約を持つ`net::dns::manager`を提供します。

| 非公開関数 | 責務 |
|---|---|
| `net::dns::_backup-resolv-conf` | DNS管理方式の切替えによって現在の`/etc/resolv.conf`が置き換わる場合だけ、既存内容またはlink情報をbackupします。 |
| `net::dns::_manager` | `resolv.conf`のlink先と各managerの有効設定から現在のDNS管理方式を判定します。 |
| `net::dns::_active-network-manager-connections` | NetworkManagerが管理するactive connectionからVPN profileを除いて列挙します。 |
| `net::dns::_restart-systemd-resolved` | systemd-resolvedを再起動し、active状態を確認します。 |
| `net::dns::_restart-network-manager` | NetworkManagerを再起動し、active状態とruntime `resolv.conf`の生成を確認します。 |
| `net::dns::_verify` | 期待する管理方式、設定されたDNS server、`resolv.conf`の状態、実際の名前解決を確認します。 |


## 検討中の関数

| 参照元の関数 | 機能 | 現状の課題 | 検討する設計 |
|---|---|---|---|
| `ssh-update-config` | SSH config内のHost節へキーを置換または追加します。 | `Include`、`Match`、複数Hostパターン、否定パターン、最初に得た値が優先される規則を正しく扱いません。 | 既存SSH構文を直接書き換えず、識別marker付きの管理対象Host blockだけを原子的に追加・置換します。 |
| `ssh-set-config` | `~/.ssh/config`を準備してHost設定を更新します。 | 採用しない文字列ベースのSSH config更新へ依存するためです。 | FILE、HOST、KEY、VALUEを必須にし、管理対象blockの更新関数を呼び、更新後に`ssh -G`で検証します。 |
| `ssh-enable-auto-add-keys` | 全Hostへ`AddKeysToAgent yes`を設定します。 | 利用者全体へ影響する個人設定だからです。 | 対象Host patternと設定fileを必須にし、そのmanaged blockだけへ`AddKeysToAgent yes`を設定します。 |
| `ssh-disable-host-key-checking` | 全Hostのhost key確認を無効にします。 | 中間者攻撃の検出を無効にする危険な既定設定だからです。 | 全Hostには設定せず、検証用の一時環境で対象Hostを必須にします。通常用途ではknown_hostsを正しく登録します。 |
| `ssh-private-key-files` | `~/.ssh`直下で`PRIVATE KEY`を含むファイルを列挙します。 | 鍵形式を網羅せず、通常ファイル内容の走査で秘密鍵を判定するためです。 | 通常ファイルとmodeを検査し、`ssh-keygen -y -f PATH`で秘密鍵として読めるpathだけを列挙します。 |
| `ssh-add-all-private-keys` | 検出した全秘密鍵をssh-agentへ追加します。 | 対象鍵、確認、保存時間を利用者が選べないためです。 | 追加する鍵pathを引数で明示し、各鍵のfingerprintを表示してから`ssh-add`へ一件ずつ渡します。 |
| `_android-commandlinetools-url` | Android StudioのHTMLからOS別command-line tools URLを抽出します。 | 非公開のHTML構造を正規表現で解析するためです。 | Googleの配布metadataからOS、architecture、任意の`VERSION`に対応するURLを決定します。`VERSION`を省略した場合は最新安定版を選びます。 |
| `android-commandlinetools-install` | `ANDROID_HOME`を削除してAndroid SDK一式を最新版で再作成します。 | 既存SDKを無確認で削除するためです。 | `android::command-line-tools::install [VERSION] [INSTALL_DIRECTORY]`とし、版を省略した場合は最新安定版を選びます。既存SDKを保持したまま一時directoryへ展開し、成功後に切り替えます。hash指定は要求しません。 |
| `golang-install`（共通定義） | PPAを追加してaptからGoを導入します。 | Ubuntu固有のPPA追加と管理者更新を導入処理へ連結するためです。 | `go::install [VERSION]`と`go::version::list`を提供し、版を省略した場合はOS別の公式提供元から最新安定版を選びます。repository登録が必要な場合は別の管理関数へ分けます。hash指定は要求しません。 |
| `rust-install` | rustupのネットワークスクリプトを直接シェルへ渡します。 | 取得内容を一時fileとして確認できないままshellへ直接渡すためです。 | `rust::install [VERSION]`と`rust::versions`を提供します。版を省略した場合は最新安定版を選び、公式installerを一時fileへ取得してから非対話設定で実行します。hash指定は要求しません。 |
| `flutter-set-version` | Flutter SDKのGit作業ツリーを指定版またはstable最新版へ変更します。 | 共有SDKの未保存変更を検査せず作業treeを切り替えるためです。 | `flutter::use-version [VERSION] [SDK_DIRECTORY]`と`flutter::versions`を提供します。版を省略した場合は最新stableを選び、専用SDK directoryがcleanであることを確認してから対象tagまたはcommitへ切り替えます。 |
| `jfrog-config-clear` | JFrog CLIの設定を消去します。 | 対象設定を明示しない削除だからです。 | SERVER_IDを必須にし、対象設定だけを削除します。 |
| `jfrog-setup` | JFrog CLIへ認証情報を登録して接続確認します。 | 秘密値をコマンド引数へ渡し、永続化方式がJFrog CLI設定に依存するためです。 | SERVER_ID、URL、USERを引数化し、tokenは標準入力または保護されたfile descriptorから渡してprocess引数へ含めません。 |
| `antigravity-cli-install` | ネットワークスクリプトでCLIを導入し、対話ログインします。 | 導入と認証を一つの関数へ連結するためです。 | `antigravity::install [VERSION]`と版一覧関数を提供し、版を省略した場合は最新安定版を選びます。認証は別関数へ分け、hash指定は要求しません。 |
| `codex-install` | npmのglobal領域へCodexを導入してログインします。 | global packageの導入と認証を一つの関数へ連結するためです。 | `codex::install [VERSION]`と版一覧関数を提供し、版を省略した場合はnpmの最新安定版を選びます。認証は別関数へ分け、hash指定は要求しません。 |
| `claude-code-install` | npmのglobal領域へClaude Codeを導入して起動します。 | global packageの導入と対話起動を一つの関数へ連結するためです。 | `claude-code::install [VERSION]`と版一覧関数を提供し、版を省略した場合は最新安定版を選びます。起動は別関数へ分け、hash指定は要求しません。 |
| `opencode-install` | npmのglobal領域へOpenCodeを導入します。 | 利用者が選ぶglobal package managerを固定するためです。 | `opencode::install [VERSION]`と版一覧関数を提供し、版を省略した場合は選択したpackage managerの最新安定版を選びます。hash指定は要求しません。 |
| `docker-login-artifactory` | ArtifactoryのDocker registryへログインしようとします。 | 元の実装は`docker login`を呼ばず、秘密情報とregistry認証は製品の資格情報管理に属します。 | `docker login REGISTRY --username USER --password-stdin`を使用し、tokenを標準入力だけから渡します。 |
| `chrome-export-bookmarks` | ChromeプロファイルのBookmarksを指定先へ複製します。 | Chrome内部fileの整合性、実行中更新、個人情報の保護がbackup製品の責務だからです。 | `PROFILE_DIRECTORY [OUTPUT_PATH]`とし、`OUTPUT_PATH`の規定値は`./bookmarks.json`です。Chrome停止または整合したsnapshotを確認し、mode 600で複製します。 |
| `chrome-export-preferences` | ChromeプロファイルのPreferencesを指定先へ複製します。 | application内部形式と個人情報を扱うbackup処理だからです。 | `PROFILE_DIRECTORY [OUTPUT_PATH]`とし、`OUTPUT_PATH`の規定値は`./preferences.json`です。Chrome停止または整合したsnapshotを確認し、mode 600で複製します。 |
| `chrome-get-profile-email` | Preferencesを正規表現で検索して最初のメールアドレスを出力します。 | JSONを構文解析せず、Chrome内部スキーマへ依存するためです。 | JSON parserで既知fieldを読み、schemaと値の型を検証してliteral emailだけを返します。 |
| `chrome-find-profile-by-email` | メールアドレス正規表現に一致するChromeプロファイルを検索します。 | 利用者入力を正規表現として扱い、個人情報を基準に内部プロファイルを列挙するためです。 | EMAILをliteralとして完全一致比較し、JSON parserで各profileを検査します。正規表現として評価しません。 |
| `chrome-export-user-data-by-email` | メールアドレスでプロファイルを選び、設定とbookmarkを複製します。 | 採用しないChrome内部ファイル操作を組み合わせるためです。 | literal emailで一つのprofileを確定し、export対象、出力mode、上書き方針を明示して個別export関数を呼びます。 |
| `git-setup`（Linux定義） | 共通Git設定とCredential Manager設定を適用します。 | global Git設定と資格情報方式は利用者または組織の方針だからです。 | `git::config::setup`を実行してから、Linuxで利用できるCredential Managerを設定します。 |
| `swap-ensure-total-size` | 物理メモリーとswapの合計が固定基準に届くようswap fileを追加します。 | 物理メモリーとswapを同じ容量基準へ合算する運用判断が製品固有だからです。 | 物理memoryと合算せず、必要なswap容量と最大追加容量を明示し、作成前に計画だけを返す関数と適用関数を分離します。 |
| `keyboard-setup-lang-keys` | 特定USBキーボードのusage IDを変換・無変換キーへ割り当てます。 | ハードウェア、キー配列、udev設定が個人環境固有だからです。 | device matchとkey mappingを引数化し、hwdbの構文を検証してから明示適用します。 |
| `android-commandlinetools-url`（Linux定義） | Android command-line toolsのLinux用URLを選びます。 | 採用しないHTML解析helperへ依存するためです。 | 共通のmetadata解析関数へLinuxとarchitectureと任意の`VERSION`を渡し、版を省略した場合は最新安定版のURLを返します。 |
| `vscode-remove-user-data`（Linux共通定義） | LinuxのVS Code利用者データを再帰削除します。 | 利用者の設定、拡張、状態を一括削除するためです。 | PROFILE_DIRECTORYを必須にし、VS Code停止を確認してから指定directoryを削除します。 |
| `aws-vpn-client-log-files` | AWS VPN ClientのLinuxログファイルを列挙します。 | 特定デスクトップアプリの内部パスとファイル名に依存するためです。 | LOG_DIRECTORYを必須にし、通常ファイルだけをNUL区切りで列挙します。 |
| `aws-vpn-client-log-clear` | AWS VPN ClientのLinuxログを削除します。 | 対象期間や保存ポリシーを指定しない一括削除だからです。 | LOG_DIRECTORY、保持期間、最大使用量を必須にし、該当する通常ファイルだけを削除します。 |
| `aws-vpn-client-log-open` | AWS VPN ClientログをVS Codeで開きます。 | 特定アプリとエディターを結合した個人診断処理だからです。 | EDITORと明示されたlog path一覧を引数で受け、各pathを配列引数として起動します。 |
| `node-install` | HomebrewでNode.jsを導入し、Corepackとpnpm storeを設定します。 | Node.jsの導入とpnpmの個人設定を一つの関数へ連結するためです。 | `node::install [VERSION]`と`node::versions`へ導入を分け、版を省略した場合は最新LTSを選びます。Corepack有効化とpnpm store設定は別関数にし、hash指定は要求しません。 |
| `docker-install` | HomebrewでDocker CLI群とColimaを導入し、リンク作成後に起動します。 | 複数toolの導入、仮想化方式の選択、daemon起動を一つの関数へ連結するためです。 | Docker CLIとColimaに個別の`install [VERSION]`と版一覧関数を提供し、版を省略した場合は最新安定版を選びます。daemon起動は別関数へ分け、hash指定は要求しません。 |
| `command-line-tools-upgrade` | Xcode Command Line Toolsを削除して再導入UIを開きます。 | 開発環境を破壊して対話インストールへ移るためです。 | 現在版と必要版を検査し、削除を行わず、利用者が公式installerを完了した後に状態を再検証します。 |
| `android-commandlinetools-url`（macOS定義） | Android command-line toolsのmacOS用URLを選びます。 | 採用しないHTML解析helperへ依存するためです。 | 共通のmetadata解析関数へmacOSとarchitectureと任意の`VERSION`を渡し、版を省略した場合は最新安定版のURLを返します。 |
| `ruby-install` | Homebrewでrbenvを導入し、Zsh設定を書き換えてRubyを導入します。 | package導入、shell設定、Ruby導入を一つの関数へ連結するためです。 | `ruby::install [VERSION]`と`ruby::version::list`を提供し、版を省略した場合は最新安定版を選びます。shell設定は別関数へ分け、hash指定は要求しません。 |
| `java-ensure-path` | Homebrew OpenJDKをシステムへリンクし、`JAVA_HOME`と`PATH`を永続設定します。 | JDK選択とシェル設定が製品または利用者の責務だからです。 | JDK_HOMEと対象shell設定fileを必須にし、既存JDK選択を保持してmanaged blockへ設定します。 |
| `golang-install`（macOS定義） | HomebrewでGoを導入し、Bash設定へGOPATHのbinを追加します。 | Go導入と利用者のPATH設定を一つの関数へ連結するためです。 | 共通の`go::install [VERSION]`と`go::version::list`を使用し、版を省略した場合は最新安定版を選びます。PATH設定は別関数へ分け、hash指定は要求しません。 |
| `pipx-install` | Homebrewでpipxを導入し、PATH設定を更新します。 | pipx導入と利用者のPATH設定を一つの関数へ連結するためです。 | `pipx::install [VERSION]`と版一覧関数を提供し、版を省略した場合は最新安定版を選びます。PATH設定は別関数へ分け、hash指定は要求しません。 |
| `qmk-install` | HomebrewでQMK Toolboxを導入し、QMK公式installerでQMK CLIと依存toolを導入してから`qmk doctor`で環境を診断します。 | GUI applicationとCLIの導入を一つの関数へ連結し、取得したshell scriptを確認可能なfileへ保存せず直接実行するためです。 | `qmk::toolbox::install [VERSION]`と`qmk::cli::install [VERSION]`へ分けます。QMK CLIは`https://install.qmk.fm`から一時fileへ取得し、HTTP取得の成功と通常fileであることを確認してから`sh`で実行し、成功後に`qmk doctor`を実行します。版を省略した場合は各公式提供元の最新安定版を選び、hash指定は要求しません。 |
| `supabase-install` | Homebrew tapからSupabase CLIを導入します。 | Homebrew tapの登録とpackage導入を一つの関数へ連結するためです。 | `supabase::install [VERSION]`と`supabase::versions`を提供し、版を省略した場合は最新安定版を選びます。必要なtap登録は内部で冪等に行い、hash指定は要求しません。 |
| `vscode-remove-user-data`（macOS定義） | macOSのVS Code利用者データを再帰削除します。 | 利用者の設定、拡張、状態を一括削除するためです。 | PROFILE_DIRECTORYを必須にし、VS Code停止を確認してから指定directoryを削除します。 |
| `vscode-to-default-app` | 多数の拡張子とUTIの既定アプリをVS Codeへ変更します。 | 個人のmacOS関連付け設定だからです。 | 対象拡張子とUTIを引数で受け、macOSの関連付けtoolでVS Codeを既定applicationへ設定します。 |
| `iina-to-default-app` | 多数の動画拡張子の既定アプリをIINAへ変更します。 | 個人のmacOS関連付け設定だからです。 | 対象拡張子とUTIを引数で受け、macOSの関連付けtoolでIINAを既定applicationへ設定します。 |
| `utm-install` | 最新UTMのDMGを取得、mount、コピーして導入します。 | mountの解除と一時fileの後始末を失敗時に保証しないためです。 | `utm::install [VERSION] [APPLICATION_DIRECTORY]`と`utm::versions`を提供し、版を省略した場合は最新安定版を選びます。trapでmount解除と一時領域の削除を保証し、hash指定は要求しません。 |
| `utm-download-ubuntu-server-24-arm` | 固定URLのUbuntu ISOをDownloadsへ取得して案内を表示します。 | 保存先と仮想machine設定の案内を固定するためです。 | `ubuntu::download-server-iso [VERSION] [ARCHITECTURE] [OUTPUT_PATH]`と版一覧関数を提供します。版は最新LTS、architectureは実行環境に対応する値、保存先は現在directory内の公式file名を規定値とし、hash指定は要求しません。 |
| `docker-desktop-install` | Rosettaと最新Docker Desktopを導入します。 | Rosetta導入、Docker Desktop導入、application起動を一つの関数へ連結するためです。 | `docker-desktop::install [VERSION] [APPLICATION_DIRECTORY]`と版一覧関数を提供し、版を省略した場合は最新安定版を選びます。Rosettaが必要なら自動導入し、licenseへ自動同意します。起動は別関数へ分け、hash指定は要求しません。 |
| `rancher-desktop-install` | HomebrewでRancher Desktopを導入します。 | package managerをHomebrewへ固定するためです。 | `rancher-desktop::install [VERSION]`と版一覧関数を提供します。版を省略した場合はOS別package managerの最新安定版を選び、hash指定は要求しません。 |
| `key-binding-disable-option-t` | macOSの個人キーバインドでOption+Tを無効にします。 | 個人設定であり、適用範囲がmacOSに限定されるためです。 | `plist::set "$HOME/Library/KeyBindings/DefaultKeyBinding.dict" '~t' 'noop:'`を実行します。plist操作のため、専用の文字列編集関数は使用しません。 |
| `git-setup`（macOS定義） | 共通Git設定とosxkeychain設定を適用します。 | global Git設定と資格情報方式は利用者の方針だからです。 | `git::config::setup`を実行してから、credential helperをosxkeychainへ設定します。 |
| `mac-setup` | macOS設定、アプリ削除、パッケージ導入、セキュリティ緩和を一括実行します。 | 個人設定を固定し、Gatekeeper無効化と広範囲な削除を含むためです。 | 設定、削除、導入を個別関数へ分けます。導入関数の版は任意とし、省略時は最新安定版を選びます。hash指定は要求しません。 |
| `apt-search-latest` | apt-cacheから名前に版を含む最新パッケージを選びます。 | package名に版が含まれるという前提で人間向け出力を解析するためです。 | machine-readableなcandidateからpackage名とversionを別fieldで列挙する関数と、最新安定版を返す関数に分けます。導入関数はlatestを規定値にします。 |
| `dpkg-install-from-url` | URLからdebを取得し、`dpkg`と依存修復を実行します。 | `dpkg`失敗後の依存修復を別commandで連結し、途中状態を残すためです。 | `deb::install-from-url URL [EXPECTED_ARCHITECTURE]`とし、一時fileへ取得してarchitectureを確認し、管理者権限で`apt install`へlocal pathを直接渡します。hash指定は要求しません。 |
| `pass-install` | aptで`pass`を導入します。 | Ubuntuのaptだけへ固定するためです。 | `pass::install [VERSION]`と版一覧関数を提供し、版を省略した場合はOS別package managerの最新安定版を選びます。hash指定は要求しません。 |
| `plantuml-install` | aptでGraphvizと既定JDKを導入します。 | Ubuntuのaptへ固定し、複数packageを一括導入するためです。 | PlantUML、Graphviz、JDKごとに`install [VERSION]`と版一覧関数を提供し、版を省略した場合は各OSの最新安定版を選びます。hash指定は要求しません。 |
| `flutter-sdk-install` | 依存パッケージとFlutter stableを導入し、リンクを作成します。 | SDK導入、依存package導入、個人link作成を一つの関数へ連結するためです。 | `flutter::install [VERSION] [INSTALL_DIRECTORY]`と`flutter::versions`を提供し、版を省略した場合は最新stableを選びます。依存導入とlink作成は別関数へ分け、hash指定は要求しません。 |
| `vlc-set-to-default-app` | VLCのMIME typeをすべて既定アプリへ設定します。 | デスクトップの個人関連付け設定だからです。 | VLCが対応するMIME typeを取得し、各typeの既定applicationをVLCへ設定します。 |
| `mozc-server-2-28-4715-install` | Ubuntu 22向け固定amd64版Mozc serverを導入します。 | 古いdistribution、版、architectureへ限定されるためです。 | `mozc::server::install [VERSION]`と版一覧関数を提供し、版を省略した場合はOSとarchitectureに対応する最新安定版を選びます。hash指定は要求しません。 |
| `ibus-mozc-2-28-4715-install` | Ubuntu 22向け固定amd64版IBus Mozcを導入します。 | 古いdistribution、版、architectureへ限定されるためです。 | `mozc::ibus::install [VERSION]`と版一覧関数を提供し、版を省略した場合はOSとarchitectureに対応する最新安定版を選びます。hash指定は要求しません。 |
| `mozc-set-hiragana-as-default` | Mozc textproto設定を変更してIBusを再起動します。 | 個人の入力方式設定であり、textprotoを正しく解析しないためです。 | `textproto::set-scalar`で対象fieldを更新してからIBusを再読込します。 |
| `gnome-remove-settings` | GSettingsの文字列配列らしい値から項目をsedで除きます。 | GVariantを構文解析せず文字列置換するためです。 | GVariantを文字列置換せず、型を検査して配列をparseし、対象値だけを除いた正しいGVariantを生成します。 |
| `gnome-set-settings` | GSettingsの文字列配列らしい値へ重複を避けて項目を追加します。 | Bashの正規表現へ引用済み値を渡し、GVariantを構文解析しないためです。 | GVariant配列をparseしてliteral値の重複を検査し、型を保持した値を`gsettings set`へ渡します。 |
| `gnome-set-custom-keybinding` | 競合するGNOME shortcutを除き、新しいshortcutを登録します。 | 個人のデスクトップ設定であり、GNOMEの現在設定へ影響するためです。 | GSettingsの配列を構文として読み、競合するshortcutを除いてから新しいshortcutを登録します。 |
| `gnome-keyboard-layout-to-us` | MozcとUS配列を設定し、システムkeyboard設定をUSへします。 | 個人入力設定と管理者file更新を一括実行するためです。 | GNOME input sourceの更新とsystem keyboard fileの更新を分けます。keyboard fileは`file::replace-text FILE 'XKBLAYOUT="[^"]*"' 'XKBLAYOUT="us"'`でpermissionを判定して原子的に更新します。 |
| `gnome-keyboard-layout-to-jp` | MozcとJP配列を設定し、システムkeyboard設定をJPへします。 | 個人入力設定と管理者file更新を一括実行するためです。 | GNOME input sourceの更新とsystem keyboard fileの更新を分けます。keyboard fileは`file::replace-text FILE 'XKBLAYOUT="[^"]*"' 'XKBLAYOUT="jp"'`でpermissionを判定して原子的に更新します。 |
| `gnome-setup-input-source-switcher-shortcut` | GNOMEの入力切替shortcutと独自shortcutを設定します。 | 固定キー割当てを利用者環境全体へ適用するためです。 | 入力切替shortcutと独自shortcutを引数で受け、GSettingsへ設定します。 |
| `gnome-set-mozc-priority` | 現在のXKB配列を保持してMozcを先頭へします。 | 個人のGNOME入力方式設定だからです。 | 現在のinput source一覧を読み、XKB項目を保持したままMozcを先頭へ設定します。 |
| `mozc-tool-install` | Mozc GUIツールを導入して個人binへリンクします。 | package導入と個人binへのlink作成を一つの関数へ連結するためです。 | `mozc::tool::install [VERSION]`と版一覧関数を提供し、版を省略した場合は最新安定版を選びます。link作成は別関数へ分け、hash指定は要求しません。 |
| `ssh-server-install` | OpenSSH serverを導入して自動起動を有効にします。 | package導入とnetwork serviceの有効化を一つの関数へ連結するためです。 | `ssh-server::install [VERSION]`と版一覧関数を提供し、版を省略した場合はOS別package managerの最新安定版を選びます。自動起動と開始は別関数へ分け、hash指定は要求しません。 |
| `vscode-install` | Microsoft repositoryを追加してVS Codeを導入します。 | repository登録とapplication導入を一つの関数へ連結するためです。 | `vscode::install [VERSION]`と`vscode::versions`を提供し、版を省略した場合は最新安定版を選びます。repository登録は内部で冪等に行い、hash指定は要求しません。 |
| `vscode-remove-user-data`（Ubuntu定義） | UbuntuのVS Code利用者データを再帰削除します。 | 利用者の設定、拡張、状態を一括削除するためです。 | PROFILE_DIRECTORYを必須にし、VS Code停止を確認してから指定directoryを削除します。 |
| `_slack-url` | SlackのWebページから版を抽出し、amd64 deb URLを組み立てます。 | 元の代入構文に誤りがあり、HTML構造とarchitectureを固定するためです。 | vendor repositoryまたはrelease metadataから、OS、architecture、任意の`VERSION`に対応するURLを返します。版を省略した場合は最新安定版を選びます。 |
| `slack-install` | Slackのdebを取得して導入します。 | Linux amd64のdebへ固定するためです。 | `slack::install [VERSION]`と版一覧関数を提供し、版を省略した場合は実行OSとarchitectureに対応する最新安定版を選びます。hash指定は要求しません。 |
| `chrome-install` | Google Chromeのlatest amd64 debを導入します。 | Linux amd64のdebへ固定するためです。 | `chrome::install [VERSION]`と版一覧関数を提供し、版を省略した場合は実行OSとarchitectureに対応する最新安定版を選びます。hash指定は要求しません。 |
| `gimp-install` | aptでGIMPとpluginを導入します。 | Ubuntuのaptへ固定し、GIMPとpluginを一括導入するためです。 | GIMPとpluginに個別の`install [VERSION]`と版一覧関数を提供し、版を省略した場合はOS別package managerの最新安定版を選びます。hash指定は要求しません。 |
| `_microsoft-edge-latest-url` | repository HTMLからlatest amd64 Edge deb名を抽出します。 | HTML構造とarchitectureを固定するためです。 | vendor repositoryのpackage metadataから、OS、architecture、任意の`VERSION`に対応するartifactを返します。版を省略した場合は最新安定版を選びます。 |
| `microsoft-edge-install` | latest Edge debを取得して導入します。 | Linux amd64のdebへ固定するためです。 | `microsoft-edge::install [VERSION]`と版一覧関数を提供し、版を省略した場合は実行OSとarchitectureに対応する最新安定版を選びます。hash指定は要求しません。 |
| `ubuntu-setup` | 環境読込、エディター、補完、user directory、group、Git、SSHを一括設定します。 | 個人設定と管理処理を一つの固定構成で適用するためです。 | 各設定関数を独立して提供し、選択された関数を順に適用します。 |
| `ubuntu-setup-for-desktop` | Ubuntu共通設定にkeyboard、Mozc、VLC設定を加えます。 | 個人のデスクトップ構成だからです。 | desktop設定を個別関数として提供し、選択された関数を順に適用します。 |
| `ubuntu-22-setup-for-desktop` | Ubuntu desktop設定に固定版Mozcとwindow button設定を加えます。 | 特定distribution版と個人設定へ限定されるためです。 | 対応distributionを検証し、選択されたMozcとwindow設定を直接適用します。 |
採用するAPIは、BashStockの引数規則、終了状態、英語のDocコメント、Batsテスト、macOS・Ubuntu・FedoraのCIを満たす独立実装として提供します。

## 採用しない関数

| 参照元の関数 | 機能 | 不採用の理由 | 目的を達成する設計 |
|---|---|---|---|
| `foreach-line` | 各入力行を環境変数へ入れ、文字列として受け取ったコマンドを`eval`で実行します。 | 入力とコマンドをシェルコードとして結合するためです。呼び出し側が`while IFS= read -r`で関数を直接呼びます。 | コールバック関数名を検証し、各行を第一引数として直接呼び出します。文字列コマンドと`eval`は使用しません。 |
| `datetimes` | Linuxの起動後秒数と現在時刻を説明付きで出力します。 | `time::boot-time-milliseconds`とローカル日時APIを呼び出し側が目的に合う表示へ整形します。 | 起動後時間とローカル日時を別々の時刻APIから取得し、表示関数が固定形式へ整形します。 |
| `net-netmask` | default interfaceの最初のIPv4 prefix長を表示します。 | `net::ip::private-v4`は利用時に必要なprimary addressだけを返し、prefix長を別の公開関数として固定しないためです。 | prefix長が必要な製品は、OS別のinterface詳細取得処理からaddressとprefix長を同時に取得します。 |
| `log-error-regex` | エラーらしい語を集めた正規表現を出力します。 | 対象製品、言語、ログ形式によって分類規則が変わるためです。 | 製品ごとに正規表現と対象fieldを設定ファイルへ定義し、実際のerror例と通常例を使うテストで誤検知を検証します。 |
| `log-warn-regex` | 警告らしい語を集めた正規表現を出力します。 | 誤検知と見落としの基準が製品要件に依存するためです。 | 製品ごとにwarning用の正規表現と対象fieldを定義し、error規則との優先順位と重複をテストします。 |
| `storage-defrag` | ext4の断片化を確認して最適化します。 | Linuxのext4専用であり、長時間の管理処理を暗黙に開始するためです。 | 対象mount pointを必須にし、ext4、mount状態、空き容量、`e4defrag`の存在を検証して、確認と実行を別関数にします。 |
| `git-set-store-credential-with-plaintext` | Git資格情報を平文保存する設定へします。 | 秘密情報を暗号化せず永続化するためです。 | 平文保存は提供せず、OS credential storeまたは暗号化されたCredential Managerを明示選択します。 |
