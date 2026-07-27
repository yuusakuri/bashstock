# bash-commonsの関数選定

## 対象

この文書は、bash-commons v1.0.0の公開関数88個を対象とします。本プロジェクトはbash-commons全体を実行時依存として読み込まず、選定した振る舞いを一般基盤29関数と任意AWSモジュール24関数の合計53関数としてBash 3.2互換で実装します。

参照対象は、v1.0.0のタグが指すコミット`953e675d1a279ddd62b338dc3fc8e6c39baa0c61`です。参照元のライセンスはApache License 2.0です。本プロジェクトは参照元のコードを複製せず、関数の責務を本プロジェクトの名前空間、引数規則、終了状態、安全性、対応環境に合わせて実装します。

## 選定結果

| 名前空間 | 関数数 | 本プロジェクトの関数 |
|---|---:|---|
| `log` | 3 | `log::info`、`log::warn`、`log::error` |
| `command` | 2 | `command::require`、`command::run-as-root` |
| `option` | 1 | `option::require-single` |
| `array` | 1 | `array::prepend-to-each` |
| `string` | 4 | `string::require-non-empty`、`string::require-empty`、`string::require-allowed`、`string::slice` |
| `json` | 1 | `json::require-present` |
| `file` | 10 | `file::contains-match`、`file::verify-sha256`、`file::append-text`、`file::append-text-as-root`、`file::replace-text`、`file::replace-text-as-root`、`file::replace-text-in-files`、`file::replace-text-in-files-as-root`、`file::replace-or-append-text`、`file::replace-or-append-text-as-root` |
| `path` | 1 | `path::change-owner-recursively-as-root` |
| `user` | 6 | `user::current-name`、`user::current-primary-group`、`user::is-root`、`user::exists`、`user::create-system-as-root`、`user::create-login-as-root` |
| `aws` | 24 | IMDS、EC2、Auto Scalingの任意モジュールに24関数を配置します。 |
| 合計 | 53 | 一般基盤29関数と任意AWSモジュール24関数を採用します。 |

## 共通規則

採用関数は、利用者の値を`eval`へ渡しません。関数は、グローバル変数、現在のディレクトリ、`IFS`、ロケール、シェルオプションを呼び出し後に変更しません。値を返す関数は結果だけを標準出力へ書きます。述語関数は、条件が成立すると終了状態0、成立しないと1を返し、標準出力と標準エラー出力へ書きません。

引数の個数または形式が契約と異なる場合は終了状態64を返します。入力ファイルが存在しない場合または読み取れない場合は66、必要な実行環境を利用できない場合は69、作成できない場合は73、入出力に失敗した場合は74、一時的な失敗または待機時間超過では75、権限がない場合は77を返します。診断が必要な関数は、診断だけを標準エラー出力へ書きます。

すべての関数は、macOSの標準Bash 3.2、Ubuntu 18.04以降、Fedoraで同じ引数、出力形式、終了状態を使用します。GNU版とBSD版で異なるコマンドのオプションは公開契約に含めません。

## 採用する53関数

### ログ

| 参照元 | 本プロジェクトの関数 | 引数 | 機能 | Bash 3.2での実装規則と必須テスト |
|---|---|---|---|---|
| `log_info`、`log` | `log::info` | `MESSAGE` | 現在のローカル日時、`INFO`、コマンド名、メッセージを一行ずつ標準エラー出力へ書きます。 | 組み込みの`printf`と`time::local-date-time-milliseconds`を使用します。通常文字列、空文字、複数行、バックスラッシュ、書式指定文字、引数過多を確認します。 |
| `log_warn`、`log` | `log::warn` | `MESSAGE` | 現在のローカル日時、`WARN`、コマンド名、メッセージを一行ずつ標準エラー出力へ書きます。 | 組み込みの`printf`と`time::local-date-time-milliseconds`を使用します。通常文字列、空文字、複数行、バックスラッシュ、書式指定文字、引数過多を確認します。 |
| `log_error`、`log` | `log::error` | `MESSAGE` | 現在のローカル日時、`ERROR`、コマンド名、メッセージを一行ずつ標準エラー出力へ書きます。関数自体はプロセスを終了しません。 | 組み込みの`printf`と`time::local-date-time-milliseconds`を使用します。通常文字列、空文字、複数行、バックスラッシュ、書式指定文字、引数過多を確認します。 |

ログの一行は、`YYYY-MM-DDTHH:MM:SS.sss+HH:MM [LEVEL] [COMMAND] MESSAGE`形式または負のUTCオフセットを使う同じ形式です。`COMMAND`には`MYTOOL_NAME`を使用します。メッセージが複数行の場合は、空の行を含む各行へ日時、レベル、コマンド名を付けます。メッセージ内の`\n`や`\t`を制御文字へ変換せず、受け取った文字をそのまま出力します。

参照元の`log`は、三つのログ関数に共通する内部処理として参照します。任意のログレベルを受け取る公開関数にはしません。

### 必須条件の検査

| 参照元 | 本プロジェクトの関数 | 引数 | 機能 | Bash 3.2での実装規則と必須テスト |
|---|---|---|---|---|
| `assert_is_installed` | `command::require` | `COMMAND` | コマンドを現在の実行環境から解決できることを検査します。解決できない場合は診断を書き、終了状態69を返します。 | `command::exists`を使用し、入力を実行しません。外部コマンド、組み込み、関数、未知の名前、空文字、引数過多を確認します。 |
| `assert_not_empty` | `string::require-non-empty` | `NAME VALUE` | `VALUE`が空でないことを検査します。空の場合は`NAME`を含む診断を書き、終了状態64を返します。 | `[[ -n ]]`を使用し、値を診断へ出力しません。通常値、空文字、空白、改行、空の名前、引数の不足と過多を確認します。 |
| `assert_empty` | `string::require-empty` | `NAME VALUE` | `VALUE`が空であることを検査します。空でない場合は`NAME`を含む診断を書き、終了状態64を返します。 | `[[ -z ]]`を使用し、値を診断へ出力しません。空文字、通常値、空白、改行、空の名前、引数の不足と過多を確認します。 |
| `assert_not_empty_or_null` | `json::require-present` | `NAME VALUE` | JSONから取得した`VALUE`が空文字でも文字列`null`でもないことを検査します。条件を満たさない場合は`NAME`を含む診断を書き、終了状態64を返します。 | 値をコードや正規表現として評価せず、空文字と`null`を完全一致で検査します。通常値、数値、`false`、空文字、`null`、`NULL`、空の名前、引数の不足と過多を確認します。 |
| `assert_value_in_list` | `string::require-allowed` | `NAME VALUE ALLOWED...` | `VALUE`が一つ以上の`ALLOWED`のいずれかと完全一致することを検査します。一致しない場合は診断を書き、終了状態64を返します。 | `array::contains`を使用し、配列名の間接参照とパターン比較を使用しません。先頭と末尾の一致、不一致、空値、空の許可値、重複、空白、パターン記号、許可値なしを確認します。 |
| `assert_exactly_one_of` | `option::require-single` | `NAME VALUE [NAME VALUE]...` | 二組以上のオプション名と値を受け取り、空でない値が一つだけであることを検査します。条件を満たさない場合は候補名を含む診断を書き、終了状態64を返します。 | 位置引数を二つずつ処理し、配列名の間接参照を使用しません。一つだけ設定、すべて空、複数設定、空白値、空の名前、奇数個の引数、一組だけ、引数なしを確認します。 |

必須条件を検査する関数は、対象を表す`command`、`string`、`json`、`option`名前空間に置きます。条件を満たす場合は出力せず、終了状態0を返します。関数は`exit`を呼び出しません。呼び出し側は終了状態を返すか、製品の規則に従って処理を継続します。`NAME`は空でない一行の表示名とし、改行を含む場合は終了状態64を返します。

### 配列

| 参照元 | 本プロジェクトの関数 | 引数 | 機能 | Bash 3.2での実装規則と必須テスト |
|---|---|---|---|---|
| `array_prepend` | `array::prepend-to-each` | `PREFIX [VALUE...]` | 各`VALUE`の先頭へ`PREFIX`を付け、一要素ずつ標準出力へ書きます。値がない場合は何も出力しません。 | 名前参照、連想配列、単語分割、パス名展開を使用せず、位置引数を順番に処理します。空配列、一要素、複数要素、空要素、空の接頭辞、空白、パターン記号、改行を確認します。 |

`PREFIX`または`VALUE`に改行が含まれる場合は、行単位の出力で要素の境界を保持できないため終了状態64を返します。

### 文字列

| 参照元 | 本プロジェクトの関数 | 引数 | 機能 | Bash 3.2での実装規則と必須テスト |
|---|---|---|---|---|
| `string_substr` | `string::slice` | `VALUE START [END]` | `VALUE`から0始まりの`START`以降、`END`未満の文字を出力します。`END`を省略した場合は末尾までを出力します。 | Bash 3.2の部分文字列展開を使用します。ASCII、日本語、空文字、先頭、末尾、空の範囲、`END`省略、負数、整数以外、逆転した範囲、範囲外、引数の不足と過多を確認します。 |

`START`と`END`は0以上の10進整数です。`START`は`END`以下であり、両方とも現在のUTF-8ロケールで数えた文字数以下でなければなりません。条件を満たさない場合は終了状態64を返します。この契約は、参照元の第三引数を長さとして扱う実装上の不一致を引き継ぎません。

### ファイル

| 参照元 | 本プロジェクトの関数 | 引数 | 機能 | Bash 3.2での実装規則と必須テスト |
|---|---|---|---|---|
| `file_contains_text` | `file::contains-match` | `PATH EXPRESSION` | 読み取れる通常ファイルのいずれかの行がPerl互換正規表現に一致すれば終了状態0、一致しなければ1を返します。標準出力へは書きません。 | 内部Perlアダプターを使用し、式をPerlコードへ連結しません。一致、不一致、空ファイル、改行で終わらない最終行、空の式、無効な式、存在しないパス、ディレクトリ、読取不可を確認します。 |
| `os_validate_checksum` | `file::verify-sha256` | `PATH EXPECTED` | 読み取れる通常ファイルのSHA-256値が64桁の`EXPECTED`と一致すれば終了状態0、一致しなければ1を返します。標準出力へは書きません。 | macOSでは`shasum -a 256`、UbuntuとFedoraでは`sha256sum`を内部アダプターから使用します。一致、不一致、空ファイル、大文字と小文字の期待値、不正な期待値、空白を含むパス、存在しないパス、ディレクトリ、読取不可、実行環境不足を確認します。 |
| `file_append_text` | `file::append-text` | `PATH TEXT` | `TEXT`を変換せず、現在の利用者の権限で`PATH`の末尾へ正確に追記します。ファイルが存在しない場合は現在の`umask`で作成します。 | 組み込みの`printf '%s'`を使用し、`echo -e`、`eval`、権限昇格を使用しません。空文字、改行、バックスラッシュ、書式指定文字、新規ファイル、既存ファイル、シンボリックリンク、書込不可を確認します。 |
| `file_append_text` | `file::append-text-as-root` | `PATH TEXT` | `file::append-text`と同じ内容を管理者権限で追記します。 | `command::run-as-root`と安全な内部書込アダプターを使用します。通常権限では書き込めないファイル、認証成功、認証拒否、rootでの直接実行、シンボリックリンクを確認します。 |
| `file_replace_text` | `file::replace-text` | `PATH EXPRESSION REPLACEMENT` | 各行でPerl互換正規表現に最初に一致する部分を、リテラルの`REPLACEMENT`へ置換します。一件も一致しない場合はファイルを変更せず終了状態1を返します。 | 同じディレクトリの一時ファイルへ書き、権限と所有者を保持して原子的に置き換えます。置換値をPerlコードとして評価しません。一致、不一致、複数行、複数一致、無効な式、空の置換、末尾改行、メタデータ保持を確認します。 |
| `file_replace_text` | `file::replace-text-as-root` | `PATH EXPRESSION REPLACEMENT` | `file::replace-text`と同じ置換を管理者権限で実行します。 | `command::run-as-root`を使用し、処理全体を同じ権限で実行します。通常権限では書き込めないファイル、認証拒否、原子的置換、所有者と権限の保持を確認します。 |
| `file_replace_text_in_files` | `file::replace-text-in-files` | `EXPRESSION REPLACEMENT PATH...` | 一つ以上のファイルへ`file::replace-text`と同じ置換を適用します。 | 全入力と正規表現を検証してから一時ファイルを作成し、すべての作成に成功した後で置換します。途中で失敗した場合は保存した元ファイルから復元します。一件、複数件、入力不正、途中失敗、復元失敗を確認します。 |
| `file_replace_text_in_files` | `file::replace-text-in-files-as-root` | `EXPRESSION REPLACEMENT PATH...` | `file::replace-text-in-files`と同じ複数ファイル置換を管理者権限で実行します。 | `command::run-as-root`を使用し、検証、一時ファイル作成、置換、復元を同じ権限で行います。認証拒否、複数所有者、途中失敗、復元を確認します。 |
| `file_replace_or_append_text` | `file::replace-or-append-text` | `PATH EXPRESSION REPLACEMENT` | 一致する行があれば`file::replace-text`と同じ置換を行い、一致しなければ`REPLACEMENT`を新しい一行として末尾へ追加します。 | 置換または追記後の全内容を一時ファイルへ作成して原子的に置き換えます。空ファイル、一致、不一致、末尾改行ありとなし、空の置換、無効な式を確認します。 |
| `file_replace_or_append_text` | `file::replace-or-append-text-as-root` | `PATH EXPRESSION REPLACEMENT` | `file::replace-or-append-text`と同じ処理を管理者権限で実行します。 | `command::run-as-root`を使用し、通常権限では書き込めないファイル、認証拒否、原子的置換、所有者と権限の保持を確認します。 |

ファイルの検索関数と置換関数は、同じPerl互換正規表現を一行の範囲で評価します。式と置換値に改行またはNUL文字がある場合は終了状態64を返します。通常権限版は権限を昇格しません。管理者権限版だけが`command::run-as-root`を使用します。すべての更新関数はシンボリックリンクを拒否し、既存ファイルの所有者、グループ、モード、ACL、拡張属性を保持します。メタデータを保持できない場合は元ファイルを変更せず終了状態74を返します。

`file::verify-sha256`は、16進英字の大小を区別しません。MD5は安全な完全性検査に適さないため、対応する公開関数を設けません。

### 利用者

| 参照元 | 本プロジェクトの関数 | 引数 | 機能 | Bash 3.2での実装規則と必須テスト |
|---|---|---|---|---|
| `os_get_current_users_name` | `user::current-name` | なし | 現在のプロセスを実行する実効利用者の名前を標準出力へ書きます。 | `id -un`を使用します。一般利用者、root、空でない出力、引数過多、`id`の失敗を確認します。 |
| `os_get_current_users_group` | `user::current-primary-group` | なし | 現在のプロセスを実行する実効利用者のプライマリーグループ名を標準出力へ書きます。 | `id -gn`を使用します。一般利用者、root、空でない出力、引数過多、`id`の失敗を確認します。 |
| `os_user_is_root_or_sudo` | `user::is-root` | なし | 現在のプロセスの実効利用者IDが0なら終了状態0、それ以外は1を返します。標準出力と標準エラー出力へは書きません。 | Bash 3.2の`EUID`を数値として比較します。root、一般利用者、`sudo`の呼び出し元を示す環境変数だけがある状態、引数過多を確認します。 |
| `os_user_exists` | `user::exists` | `NAME` | OS上に`NAME`と完全一致する利用者が存在すれば終了状態0、存在しなければ1を返します。標準出力と標準エラー出力へは書きません。 | `id`を使用し、名前をコマンドまたはオプションとして評価しません。現在の利用者、root、存在しない名前、空文字、ハイフンで始まる値、空白、改行、引数過多を確認します。 |
| `os_create_user` | `user::create-system-as-root` | `NAME` | パスの所有者として使用できる、ログイン不能なローカルシステムアカウントを管理者権限で作成します。既存の利用者名は終了状態73を返します。 | macOSでは役割アカウント、UbuntuとFedoraではシステムアカウントとして作成します。パスワード、管理者グループ、Secure Token、ホームディレクトリを付与しません。正常作成、既存名、不正名、認証拒否、OS別コマンド失敗を確認します。 |
| `os_create_user` | `user::create-login-as-root` | `NAME FULL_NAME` | 人がログインするためのローカル一般利用者を管理者権限で作成し、OS標準のホームディレクトリ、`/bin/bash`、対話入力したパスワードを設定します。管理者権限は付与しません。 | パスワードは引数、環境変数、標準入力へ渡さず、制御端末上のOS標準パスワード入力だけで設定します。正常作成、既存名、不正名、ホーム作成、パスワード不一致、入力中断、非対話実行、認証拒否、作成後の失敗と復元を確認します。 |

`user::is-root`は実効利用者IDだけを判定します。`SUDO_USER`などの環境変数が設定されていても、実効利用者IDが0でなければ終了状態1を返します。利用者名を受け取る関数は、空文字、改行を含む値、ハイフンで始まる値を終了状態64として扱います。

`user::create-system-as-root`は、サービス実行とファイル所有のためのアカウントを作成します。`NAME`は、macOSの役割アカウントとLinuxのシステムアカウントで共通して使用できる`_[a-z][a-z0-9_-]*`形式に限定します。このアカウントは人のログインに使用できません。

`user::create-login-as-root`は、人がログインするための一般利用者を作成します。`NAME`は`[a-z][a-z0-9_-]*`形式、`FULL_NAME`は空でなく、改行、コロン、制御文字を含まない文字列とします。macOSではホームを`/Users/NAME`、UbuntuとFedoraでは`/home/NAME`に作成します。パスワード設定に失敗した場合は、同じ関数呼び出しで作成した利用者とホームディレクトリを削除して元の状態へ戻します。復元にも失敗した場合は終了状態74を返し、残った利用者名とホームディレクトリを標準エラー出力へ書きます。macOSのSecure TokenとFileVault解除権限は、この関数の契約に含めません。

### 管理者実行とOS別実装

| 参照元 | 本プロジェクトの関数 | 引数 | 機能 | Bash 3.2での実装規則と必須テスト |
|---|---|---|---|---|
| `assert_user_has_sudo_perms` | `command::run-as-root` | `COMMAND [ARGUMENT...]` | 実効利用者IDが0ならコマンドを直接実行し、それ以外ならsudoを介して管理者権限で実行します。標準入力、標準出力、標準エラー出力、終了状態を接続したまま保持します。 | コマンドと各引数を配列として渡し、`eval`、文字列連結、暗黙のシェル起動を使用しません。root、sudo成功、認証拒否、sudoなし、未知のコマンド、空白と記号を含む引数を確認します。 |
| `os_change_dir_owner` | `path::change-owner-recursively-as-root` | `PATH USER [GROUP]` | ディレクトリ自身と同じファイルシステム内の全内容について、所有者を管理者権限で変更します。`GROUP`を省略した場合は`USER`のプライマリーグループを使用します。 | 対象が実在する通常ディレクトリであり、シンボリックリンクでないことを確認します。再帰処理は別のマウントへ進まず、シンボリックリンク自体の所有者だけを変更します。空ディレクトリ、階層、隠しファイル、リンク、別マウント、途中失敗、認証拒否を確認します。 |

管理者権限を使用する公開関数は、名前の末尾を`-as-root`とします。`command::run-as-root`だけは動詞句自体が管理者実行を表します。これらの関数は、実効利用者IDが0でない場合にsudoを使用します。sudoが存在しない場合は終了状態69、認証または権限が拒否された場合は77を返します。

公開関数はOSに関係なく一つの名前と契約を持ちます。内部のプラットフォーム読み込み処理は`system::operating-system`とLinuxの`/etc/os-release`を確認し、macOS、Ubuntu、Fedoraの実装ファイルから一つだけを読み込みます。各実装ファイルは同じ内部プロバイダー関数を定義し、公開関数が共通の入力検査を行った後で呼び出します。未対応のOSや必要な管理コマンドがない環境では終了状態69を返します。

| 内部プロバイダー | システムアカウント作成 | ログイン用アカウント作成 | 再帰的な所有者変更 |
|---|---|---|---|
| macOS | `sysadminctl`の役割アカウントを使用し、UIDを450から499、ホームを`/var/empty`、シェルを`/usr/bin/false`の範囲で設定します。 | `sysadminctl`で一般利用者とホームを作成し、制御端末からパスワードを設定します。管理者グループとSecure Tokenは付与しません。 | BSD版の`find`と`chown -h`を使用し、別のファイルシステムとリンク先へ進みません。 |
| Ubuntu | `useradd --system --no-create-home`を使用し、ホームを`/nonexistent`、シェルを`/usr/sbin/nologin`に設定します。 | `useradd --create-home`で一般利用者を作成し、`passwd`で制御端末からパスワードを設定します。 | GNU版の`find`と`chown --no-dereference`を使用し、別のファイルシステムとリンク先へ進みません。 |
| Fedora | `useradd --system --no-create-home`を使用し、ホームを`/nonexistent`、シェルを`/usr/sbin/nologin`に設定します。 | `useradd --create-home`で一般利用者を作成し、`passwd`で制御端末からパスワードを設定します。 | GNU版の`find`と`chown --no-dereference`を使用し、別のファイルシステムとリンク先へ進みません。 |

### AWS任意モジュール

AWS関数は一般基盤の起動時に読み込みません。製品は使用する機能に対応するモジュールだけを明示的に読み込みます。AWSモジュールを読み込んだだけでは、ネットワーク通信、メタデータ取得、認証、環境変数の変更を行いません。

#### IMDS

`src/aws/imds.sh`は、EC2 Instance Metadata Service Version 2だけを使用します。IMDSv1への切り替え、バージョン選択、グローバルなトークン状態を公開APIに含めません。

| 参照元 | 本プロジェクトの関数 | 引数 | 機能 |
|---|---|---|---|
| `assert_is_ec2_instance` | `aws::is-ec2-instance` | なし | IMDSv2トークンを取得できれば終了状態0、取得できなければ1を返します。出力は行いません。 |
| `aws_get_instance_id` | `aws::instance-id` | なし | 現在のEC2インスタンスIDを出力します。 |
| `aws_get_instance_region` | `aws::instance-region` | なし | インスタンス識別文書から現在のAWSリージョンを出力します。 |
| `aws_get_ec2_instance_availability_zone` | `aws::instance-availability-zone` | なし | 現在のアベイラビリティーゾーンを出力します。 |
| `aws_get_instance_private_ip` | `aws::instance-private-ip` | なし | 現在のEC2インスタンスのプライマリー非公開IPv4アドレスを出力します。 |
| `aws_get_instance_public_ip` | `aws::instance-public-ip` | なし | 現在のEC2インスタンスの公開IPv4アドレスを出力します。割り当てがない場合は終了状態1を返します。 |
| `aws_get_instance_private_hostname` | `aws::instance-private-host-name` | なし | 現在のEC2インスタンスの非公開ホスト名を出力します。 |
| `aws_get_instance_public_hostname` | `aws::instance-public-host-name` | なし | 現在のEC2インスタンスの公開ホスト名を出力します。割り当てがない場合は終了状態1を返します。 |

内部IMDSアダプターは、`/latest/api/token`から有効期間60秒のトークンを取得し、同じ関数呼び出し内だけで使用します。HTTPプロキシを使用せず、接続と処理のタイムアウトを設定します。HTTPエラー、空の応答、不正なJSON、タイムアウトを区別し、利用できない実行環境は69、一時的な通信失敗は75を返します。

#### EC2

`src/aws/ec2.sh`はAWS CLI v2を使用します。リージョンは各関数の引数で明示し、利用者の既定リージョンを暗黙に使用しません。

| 参照元 | 本プロジェクトの関数 | 引数 | 機能 |
|---|---|---|---|
| `aws_get_instance_tags` | `aws::instance-tags` | `INSTANCE_ID REGION` | 指定EC2インスタンスの全タグをAWS CLIのJSON形式で出力します。 |
| `aws_get_instance_tag_val` | `aws::instance-tag` | `INSTANCE_ID REGION KEY` | 指定EC2インスタンスのタグ値を出力します。タグがない場合は終了状態1を返します。 |
| `aws_wrapper_wait_for_instance_tags` | `aws::wait-for-instance-tags` | `INSTANCE_ID REGION TIMEOUT_SECONDS INTERVAL_SECONDS` | 一つ以上のタグを取得できるまで待ち、全タグをJSON形式で出力します。 |
| `aws_wrapper_get_instance_tag` | `aws::wait-for-instance-tag` | `INSTANCE_ID REGION KEY TIMEOUT_SECONDS INTERVAL_SECONDS` | 指定タグを取得できるまで待ち、タグ値を出力します。 |
| `aws_get_enis_for_instance` | `aws::network-interfaces-for-instance` | `INSTANCE_ID REGION` | 指定EC2インスタンスへ接続されたElastic Network InterfaceをJSON形式で出力します。 |
| `aws_get_enis_for_tag` | `aws::network-interfaces-for-tag` | `KEY VALUE REGION` | 指定タグを持つElastic Network InterfaceをJSON形式で出力します。 |
| `aws_get_instances_with_tag` | `aws::instances-with-tag` | `KEY VALUE REGION` | 指定タグを持つ待機中または実行中のEC2インスタンスをJSON形式で出力します。 |
| `aws_wrapper_get_ips_with_tag` | `aws::instance-ips-with-tag` | `KEY VALUE REGION ADDRESS_KIND` | 指定タグを持つインスタンスのIPアドレスを一件ずつ出力します。`ADDRESS_KIND`は`private`または`public`です。 |

AWS CLIの`--query`と`--output`を使用し、利用者の値をJMESPath式またはシェルコードへ連結しません。タグ、インスタンス、ネットワークインターフェースの応答順序は公開契約に含めず、複数値を返す関数は識別子の昇順に整列して一件ずつ出力します。

#### Auto Scaling

`src/aws/auto-scaling.sh`は、EC2 Auto Scaling Groupの取得、待機、アドレス選択を提供します。

| 参照元 | 本プロジェクトの関数 | 引数 | 機能 |
|---|---|---|---|
| `aws_describe_asg` | `aws::auto-scaling-group` | `NAME REGION` | 指定Auto Scaling GroupをAWS CLIのJSON形式で出力します。存在しない場合は終了状態1を返します。 |
| `aws_describe_instances_in_asg` | `aws::instances-in-auto-scaling-group` | `NAME REGION` | 指定Auto Scaling Groupに属する待機中または実行中のEC2インスタンスをJSON形式で出力します。 |
| `aws_wrapper_get_asg_name` | `aws::current-auto-scaling-group-name` | `TIMEOUT_SECONDS INTERVAL_SECONDS` | 現在のEC2インスタンスの`aws:autoscaling:groupName`タグを取得し、Auto Scaling Group名を出力します。 |
| `aws_wrapper_get_asg_size` | `aws::auto-scaling-group-size` | `NAME REGION` | 指定Auto Scaling Groupの希望容量を0以上の整数で出力します。 |
| `aws_wrapper_wait_for_instances_in_asg` | `aws::wait-for-auto-scaling-group-instances` | `NAME REGION TIMEOUT_SECONDS INTERVAL_SECONDS` | 待機中または実行中のインスタンス数が希望容量に達するまで待ち、対象インスタンスをJSON形式で出力します。 |
| `aws_wrapper_get_ips_in_asg` | `aws::auto-scaling-group-ips` | `NAME REGION ADDRESS_KIND TIMEOUT_SECONDS INTERVAL_SECONDS` | 希望容量に達したインスタンスのIPアドレスを一件ずつ出力します。`ADDRESS_KIND`は`private`または`public`です。 |
| `aws_wrapper_get_hostnames_in_asg` | `aws::auto-scaling-group-host-names` | `NAME REGION ADDRESS_KIND TIMEOUT_SECONDS INTERVAL_SECONDS` | 希望容量に達したインスタンスのホスト名を一件ずつ出力します。`ADDRESS_KIND`は`private`または`public`です。 |
| `aws_wrapper_get_asg_rally_point` | `aws::auto-scaling-group-coordinator-host-name` | `NAME REGION ADDRESS_KIND TIMEOUT_SECONDS INTERVAL_SECONDS` | 起動日時が最も早く、同時刻ではインスタンスIDが辞書順で最初のインスタンスを調整役として選び、そのホスト名を出力します。 |

待機関数は最大試行回数ではなく、0より大きい待機上限秒と確認間隔秒を受け取ります。`time::elapsed-milliseconds`を使用し、システム日時が変化しても待機時間が逆行しないようにします。待機上限へ達した場合は終了状態75を返します。関数は`exit`を呼び出さず、認証情報、トークン、AWS CLIの応答本文をログへ書きません。

AWS関数のテストはAWS CLIとHTTP処理を固定応答のアダプターへ置き換え、実際のAWSアカウント、認証情報、IMDSへ接続しません。成功、対象なし、ページ分割、APIエラー、認証エラー、タイムアウト、空値、並び順、公開アドレスなしを確認します。

## 対応環境の検証

| 環境 | 必須条件 |
|---|---|
| macOS | Apple Silicon上の標準Bash 3.2で、一般基盤29関数とmacOS用内部プロバイダーの出力、終了状態、標準出力と標準エラー出力の分離を確認します。 |
| Ubuntu | Ubuntu 18.04以降のBashで、一般基盤29関数とUbuntu用内部プロバイダーの出力、終了状態、標準出力と標準エラー出力の分離を確認します。 |
| Fedora | FedoraのBashで、一般基盤29関数とFedora用内部プロバイダーの出力、終了状態、標準出力と標準エラー出力の分離を確認します。 |
| AWS任意モジュール | 24関数について、IMDSとAWS CLIを固定応答へ置き換え、macOS、Ubuntu、Fedoraで同じ出力、終了状態、待機規則になることを確認します。 |
| 安全性 | コマンド置換、単一引用符、二重引用符、バックスラッシュ、パターン記号、空白、改行を含む入力を実行しないことを確認します。 |
| 状態保持 | 関数の成功後と失敗後に、現在のディレクトリ、`IFS`、ロケール、シェルオプションが変わらないことを確認します。 |
