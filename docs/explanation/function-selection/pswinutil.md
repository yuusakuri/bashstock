# PSWinUtilとの導入・Android機能の比較

PSWinUtilの公開関数と、BashStockの導入、版照会、Android操作を比較します。
表の「不足する処理」は実装済みの動作を表しません。OS別の実装と実機確認はIssue #14で管理します。

## 適用する考え方

PSWinUtilからは、正確なパッケージの選択、CPUに適合する配布物の選択、導入後の実行確認、現在のシェルと起動設定への環境変数の反映を参考にします。
SDKを置き換える場合は、取得と展開を別の場所で完了させ、失敗時に既存のSDKと設定を復元します。

Windowsのwinget、レジストリ、`.exe`、`.bat`、プロセス終了コードの例外扱いは移植しません。
BashStockではOS別のパッケージ管理ツール、シェルの起動設定、引数配列、外部コマンドの終了状態を使用します。
PowerShellの確認機能を理由に、Bashの全関数へ新しい確認引数を設ける必要はありません。

PSWinUtilの一部の関数は導入済みの実行ファイルがあれば終了します。
BashStockでは、版省略時に対象OSで動作する最新安定版を選ぶ要件を優先し、存在確認だけでは更新を省略しません。
指定した版を取得できない場合も、別の版へ黙って切り替えません。

## 導入関数

PSWinUtilで直接対応する実装は、Flutter SDK、Android SDK、Git、GitHub CLI、wingetによるパッケージ導入です。
ほかのソフトウェアについては、個別の導入方法を合わせる根拠はなく、導入後の確認と失敗時の扱いを参考にします。

| BashStockの関数 | 現在の実装 | 不足する処理・適用判断 |
| --- | --- | --- |
| `deb::install-from-url` | HTTPSから取得し、CPUを検査してAPTで依存関係ごと導入します。 | パッケージ名・版と取得物を照合し、取得失敗で既存ファイルを壊さないことを確認します。署名または提供元の検証用ハッシュがある配布物では、その値も照合します。 |
| `node::install` | HomebrewまたはLinuxの配布元パッケージを導入し、Corepackとpnpmを設定します。 | Ubuntuの古いNode.js、npmの別パッケージ、Corepackの対応版を扱う必要があります。Node.jsとnpmの起動、pnpmの起動、選択した版を確認します。 |
| `docker::install` | Linuxでは公式パッケージ、サービス、グループを設定します。macOSでは実行環境を別途必要とします。 | 現在の構成を保ち、CLI・Compose・Buildx・デーモンの応答まで確認します。macOSのプロセス存在だけではデーモンの準備完了を判定できません。 |
| `colima::install` | Homebrewで導入し、停止中なら起動します。 | 指定版と導入済み版、Dockerデーモンの準備完了を確認します。 |
| `ruby::install` | rbenvとruby-buildを取得し、Rubyの導入と既定版の設定を行います。 | コンパイラーとOS別の開発ライブラリを揃え、Rubyとgemの起動を確認します。現在のシェルと再ログイン後に同じRubyを使えることを確認します。 |
| `jdk::install` | OpenJDKを導入し、既定のJava、JAVA_HOME、PATHを設定します。 | 対象OSで利用可能な版を先に確認し、javaとjavacの版、保存したJAVA_HOME、再ログイン後の選択を照合します。 |
| `pipx::install` | OSのpipxパッケージを導入し、利用者の実行ファイル用ディレクトリをPATHへ登録します。 | 古いUbuntuでのパッケージの有無とPythonの対応版を扱い、pipxによるアプリの導入と実行まで確認します。 |
| `utm::install` | DMGを取得してマウントし、既存アプリを削除してコピーします。 | PSWinUtilのFlutterと同様に、コピー成功まで既存アプリを保持します。失敗時の復元、DMGの解除、CPUとmacOSの対応版を確認します。 |
| `rancher-desktop::install` | パッケージを導入して起動し、Linuxではkvmグループを設定します。 | プロセス起動とコンテナー実行環境の準備完了を区別し、KVM、GUI、再ログイン後の権限を確認します。 |
| `pass::install` | OSのパッケージ管理ツールで導入します。 | passの起動とGPG連携を確認します。保存先や鍵を導入処理だけで置き換えません。 |
| `plantuml::install` | OSのパッケージ管理ツールで導入します。 | JavaとGraphvizの依存関係、実際の図の生成を確認します。 |
| `graphviz::install` | OSのパッケージ管理ツールで導入します。 | dotの起動と画像の生成を確認します。 |
| `flutter::dependencies::install` | Linuxのビルド依存パッケージを導入します。 | Ubuntuで固定しているlibstdc++-12-devを、各LTSで提供される開発パッケージに合わせます。SDKの対応OSと必要なコンパイラーも照合します。 |
| `flutter::install` | 安定版の一覧から版を選び、既存SDKを削除してGitで取得します。 | PSWinUtilの配布物選択、別の場所への展開、既存SDKの復元、PATH設定、FlutterとDartの起動確認を適用できます。CPU別の公式配布物を選び、利用者の作業ファイルを失わない構成が必要です。 |
| `mozc::server::install` | OSに対応するMozcサーバーのパッケージを導入します。 | パッケージの版、サーバーの起動、IBusとの互換性を確認します。WindowsのIME設定は移植しません。 |
| `mozc::ibus::install` | IBus Mozcを導入し、同じ版のサーバーがある場合は同時に導入します。 | 実際のデスクトップで日本語入力と再ログイン後の動作を確認します。 |
| `mozc::tool::install` | OSに対応するMozc設定ツールを導入します。 | GUIの起動とサーバーの版との互換性を確認します。 |
| `ssh-server::install` | OpenSSHサーバーを導入し、起動と自動起動を設定します。 | 設定の構文、サービスの応答、再起動後の接続を確認します。 |
| `vscode::install` | MicrosoftのリポジトリまたはHomebrewで導入します。 | 対象OSとCPUの配布物、codeの起動、一般ユーザーによるGUIの起動を確認します。 |
| `chrome::install` | GoogleのリポジトリまたはHomebrewで導入します。 | LinuxのCPU別配布物の有無を導入前に判定し、起動可能な版を選びます。別のブラウザーへ自動で置き換えません。 |
| `gimp::install` | GIMPを導入し、LinuxではG'MICも導入します。 | GUIの起動とプラグインの読込みを確認します。 |
| `gimp::gmic::install` | UbuntuとFedoraで異なるパッケージ名を使います。 | GIMPの版とプラグインの対応、実際のフィルター処理を確認します。 |
| `microsoft-edge::install` | Ubuntuではdeb、Fedoraではリポジトリ、macOSではHomebrewを使います。 | 対応OSとCPUを先に判定し、導入した版とGUIの起動を確認します。 |
| `xcode::command-line-tools::upgrade` | softwareupdateが提供する版を導入し、選択されたパスを確認します。 | 更新がない場合の成功扱いを保ち、clangとSDKの利用を確認します。 |
| `qmk::toolbox::install` | macOSのHomebrew caskで導入します。 | アプリの起動とUSB機器へのアクセスを確認します。OS固有のGUIアプリとして扱います。 |
| `qmk::cli::install` | 公式スクリプトを保存して実行し、qmk doctorを実行します。 | 要求した版と実際の版を照合し、Python、ツールチェーン、USB権限を各OSで確認します。 |
| `supabase::install` | HomebrewまたはCPU別のGitHubリリースパッケージを使います。 | supabaseの版と起動を確認し、Dockerを必要とする操作ではデーモンの状態も確認します。 |
| `rosetta::install` | macOSでsoftwareupdateを実行します。 | Apple Siliconを先に判定します。Intel Macで同じ導入処理を実行する根拠はありません。 |
| `git-credential-manager::install` | Homebrew caskだけを使い、指定版を反映しません。 | OS別の公式配布物、版指定、credential helperの設定と認証を扱う必要があります。 |
| `go::repository::register` | brewまたはapt-getの存在を確認します。 | 実際の登録処理はありません。OS別の取得方法と利用可能な版を定義し、Fedoraも扱う必要があります。 |
| `go::install` | HomebrewまたはUbuntuのgolangパッケージを使います。 | Fedora、OSに適合する版、PATH、goの起動と小さなプログラムの実行を扱います。 |
| `rust::install` | rustupの公式スクリプトを保存して実行します。 | cargoとrustcの版、現在のシェルと再ログイン後のPATH、指定ツールチェーンを確認します。 |
| `opencode::install` | Homebrewまたはnpmを使います。 | 公式に対応するパッケージ名と版の取得方法を確認し、実行ファイルと版を照合します。既存のnpmがあることだけでは正しい配布物を選べません。 |

## 版照会と導入後の設定

版一覧は導入済み版と取得可能な版を区別し、対象OSとCPUで導入できる安定版を数値順に返す必要があります。
PSWinUtilのFlutterとAndroidはこの区別を扱っています。BashStockでは、個別パッケージの版、言語のメジャー版、AndroidのAPI番号を混同しない設計が必要です。

| 関数 | 適用判断 |
| --- | --- |
| `apt::package::candidates`、`apt::package::latest` | APTの候補が存在する名前を選ぶ処理を保ちます。候補の取得失敗と候補なしを区別します。 |
| `node::versions` | 上流のLTSメジャー一覧と、実行中のOSで導入できる一覧を区別します。 |
| `docker::versions` | OSとCPU別の公式リポジトリを使います。返したepoch付きの値をそのまま導入できる契約を保ちます。 |
| `colima::versions` | Homebrewで取得可能な版と、導入関数が指定できる版を揃えます。 |
| `ruby::version::list`、`ruby::version::latest` | ruby-buildが列挙する安定版と、各OSの依存関係でビルドできる版を照合します。 |
| `jdk::version::list`、`jdk::version::latest` | 利用できないAPTのパッケージ名を除外し、Fedoraの版番号を省略したパッケージも確認します。 |
| `pipx::versions` | OSの提供版と、別の導入方法を必要とするOSを区別します。 |
| `utm::versions` | GitHubの安定版一覧に、対象macOSとCPUの対応確認を組み合わせます。 |
| `ubuntu::server-iso-versions`、`ubuntu::download-server-iso` | CPU別の公式ISOと検証用ハッシュを照合します。古いLTSの配布先と取得失敗時の出力ファイルも確認します。 |
| `rancher-desktop::versions` | 実行中のCPUに適合するリポジトリの取得可能な版だけを扱います。 |
| `pass::versions` | OSのパッケージ管理ツールが提供する版を使います。 |
| `plantuml::versions` | OSのパッケージ管理ツールが提供する版を使います。 |
| `graphviz::versions` | OSのパッケージ管理ツールが提供する版を使います。 |
| `flutter::versions` | stableの判定に加え、OS、CPU、配布物の存在を確認します。betaを扱う場合は利用者が明示的に選択します。 |
| `mozc::server::versions` | 実行中のOSが提供するサーバーの版を使います。 |
| `mozc::ibus::versions` | IBusとMozcサーバーを組み合わせられる版を確認します。 |
| `mozc::tool::versions` | サーバーとGUIツールの互換性を確認します。 |
| `ssh-server::versions` | OSが提供するOpenSSHサーバーの版を使います。 |
| `vscode::versions` | CPUとOSに対応する公式パッケージの版を扱います。 |
| `chrome::versions` | 配布物がないCPUを、通信失敗や空の版一覧と区別します。 |
| `gimp::versions` | OSのパッケージ版とmacOSのcask版を区別します。 |
| `gimp::gmic::versions` | 対象のGIMPへ読み込めるプラグインの版を確認します。 |
| `microsoft-edge::versions` | CPUとOSに対応する公式パッケージの版を扱います。 |
| `supabase::versions` | 上流の安定版一覧に、対象CPUのリリースファイルの存在確認を組み合わせます。 |
| `go::version::list`、`go::version::latest` | 現在は導入済みのgo versionを返します。取得可能な安定版一覧と最新値を返す設計とは一致していません。 |
| `rust::versions` | 現在は導入済みツールチェーンを返します。取得可能な安定版を示す設計とは区別が必要です。 |
| `git-credential-manager::version::list` | 現在は導入済み版を返します。版指定に使える公式配布物の一覧とは区別が必要です。 |
| `env::set-variable` | 現在のシェルと保存先の両方へ反映する考え方を適用できます。シェルの選択を先に検査し、失敗時の状態、改行、値の引用、再ログイン後の値を確認します。 |
| `env::add-path` | 重複を避ける考え方を適用できます。パス内の空白と記号、実際の改行、登録順、現在のシェルと起動設定の一致を確認します。 |
| `env::dotenv::import`、`env::dotenv::register` | 導入設定から使用する場合は、入力検査と保存した呼出しの引用を確認します。Windowsのレジストリ再読込みへは合わせません。 |
| `vscode::set-default-app` | macOSの既定アプリ設定を保ち、対象のアプリを確認してから関連付けます。 |
| `iina::set-default-app` | macOSの動画関連付けを保ち、実際のファイルを開いて確認します。 |
| `vlc::set-default-app` | LinuxのMIME設定を保ち、実際のファイルを開いて確認します。 |
| `key-binding::disable-option-t` | macOSのキー設定として扱い、Windowsのキー設定を移植しません。 |
| `flutter::use-version` | 導入先の既定値をflutter::installと揃え、タグとブランチを区別します。切替失敗前に利用者の変更を削除する処理を見直します。 |
| `flutter::run-chrome-release`、`flutter::run-linux-release` | 各実行先の依存関係と、選択したSDKの実行を確認します。 |
| `flutter::test`、`flutter::coverage` | Flutterの失敗を後続のファイル操作で成功に変えないことを確認します。 |
| `ubuntu::setup`、`ubuntu::setup-desktop`、`ubuntu::setup-desktop-22`、`mac::setup` | 個別の導入関数が保証する版と環境設定を利用します。デスクトップやOS固有の操作はPSWinUtilの一括構成へ合わせません。 |

## Android CLIとSDK

Android CLIの公式配布はLinux x86_64、macOS arm64、macOS x86_64を扱っています。
Linux arm64に同じURLを当てはめて動作するとは判断できません。
UbuntuのAPT、macOSの公式Homebrew tap、Fedoraの利用者向け公式バイナリーという取得方法を比較し、Fedora 34とUbuntuの各LTSで実行確認が必要です。

SDKの選択にはANDROID_HOMEを使い、Android CLIへ`--sdk`を渡して操作対象を固定します。
ANDROID_SDK_ROOTは既存設定との不一致を検査し、利用者の設定を無条件に削除しません。
PATHには選択したSDKのplatform-tools、emulator、Build Tools、Command-line Toolsを重複なく登録します。
PSWinUtilのbuild-tools/latestへのディレクトリ接続は、そのまま移植しません。macOSのsdkmanagerでは重複したパッケージとして警告されるため、選択した版のディレクトリを直接PATHへ登録します。

| PSWinUtilの公開関数 | BashStockの対応 | 適用判断 |
| --- | --- | --- |
| `Install-WUAndroidSdk` | 対応する導入関数はありません。 | SDK全体の導入、環境変数、版選択、構成要素の導入後の確認を分けて扱います。SDKを使う操作と、AI用の設定を登録するandroid initを混同しません。 |
| `Install-WUAndroidBuildTool` | `android::build-tools::versions`、`android::build-tools::latest-version`だけがあります。 | Build Toolsの版を検査して導入し、aapt2の起動を確認する処理が必要です。 |
| `Install-WUAndroidCommandLineTool` | 対応する導入関数はありません。 | cmdline-toolsの版を選び、sdkmanagerとavdmanagerの実行を確認します。 |
| `Install-WUAndroidPlatformTool` | 対応する導入関数はありません。 | platform-toolsの版を選び、adbとfastbootの実行を確認します。 |
| `Install-WUAndroidSdkPlatform` | 対応する導入関数はありません。 | API番号とパッケージ改訂版を分けて指定し、android.jarを確認します。 |
| `Install-WUAndroidEmulator` | 対応する導入関数はありません。 | CPUに適合するemulatorを導入し、実行と仮想化機能を確認します。 |
| `Get-WUAndroidDevice` | 対応する端末プロファイル一覧関数はありません。 | avdmanagerの端末プロファイル一覧を取得します。接続したADB端末の一覧とは別の機能です。 |
| `Get-WUAndroidSystemImage` | 対応するイメージ一覧関数はありません。 | API、tag、ABI、パッケージ改訂版で絞り込み、安定版のシステムイメージを選びます。 |
| `Get-WUAndroidEmulator` | 対応するAVD一覧関数はありません。 | emulatorのAVD一覧を取得します。ADBに接続する前のAVDも対象です。 |
| `New-WUAndroidEmulator` | 対応するAVD作成関数はありません。 | 利用できるプロファイルとイメージを検査し、同名AVDを明示指定なしで置き換えない設計を適用できます。ABIの規定値を全CPUでx86_64に固定しません。 |
| `Get-WUAndroidEmulatorPort` | 対応するポート選択関数はありません。 | コンソールの偶数ポートと隣のADBポートを一組で確保します。既存端末、IPv4、IPv6、同時起動による競合を扱います。 |
| `Test-WUAndroidEmulatorPort` | 対応するポート確認関数はありません。 | 番号の範囲と偶数を検査し、二つのポートを使える場合にだけ利用可能と判断します。 |
| `Start-WUAndroidEmulator` | 対応する起動関数はありません。 | AVDの存在、名前の重複、ポートを検査し、プロセス終了と待機時間の上限を扱います。ADB接続とAndroidの起動完了を別々に確認します。 |

Android CLIは`android sdk list --all --all-versions`で取得可能な版を確認し、`android sdk install PACKAGE@VERSION`で版を選べます。
明示した旧版には`--force`を使います。SDKのパッケージパスは`build-tools/34.0.0`のような形式を使い、avdmanagerに渡す場合は必要なセミコロン区切りへ変換します。
利用者によるライセンスの確認と、非対話実行時の扱いも明確にします。Windows固有の異常終了コードをLinuxやmacOSで成功として扱いません。

## 既存のAndroid操作

PSWinUtilの公開Android関数はSDKとAVDの管理が中心です。
BashStockのADB操作は個別の用途を保ち、機能名だけを揃えるためにAndroid CLIへ一律に置き換えません。

| 関数 | 適用判断・不足する処理 |
| --- | --- |
| `android::build-tools::versions` | Android CLIを優先し、既存環境ではsdkmanagerも使います。安定版を重複なく数値順に返し、照会の失敗を返します。 |
| `android::build-tools::latest-version` | 同じ一覧の最新値を返します。GNU固有のsort -Vへ依存せず、版なしと外部コマンドの失敗を返します。 |
| `adb::device::wait` | 接続待ちを保ち、無期限の接続待ちと起動完了待ちを区別します。 |
| `adb::device::pull` | 端末とホストのパスを引数として保持します。-Serialとデータ引数の混同を避けます。 |
| `adb::device::push` | ホストと端末のパスを引数として保持します。-Serialとデータ引数の混同を避けます。 |
| `adb::logcat::clear` | 端末指定とlogcatの終了状態を確認します。 |
| `adb::logcat::once` | 端末指定と追加フィルターの引数を保持します。 |
| `adb::logcat::continuous` | 継続表示と中断を保ち、端末指定と追加フィルターの引数を保持します。 |
| `adb::device::reboot` | 現在は再起動だけです。既存の契約にある再接続待ちを扱い、起動完了とは区別します。 |
| `adb::device::first` | 現在は端末なしでも成功します。接続済み端末がない場合は1を返し、ADB失敗を保持します。 |
| `adb::device::list` | 現在は詳細一覧を返します。既存の契約にあるdevice状態のID一覧と一致させ、offlineとunauthorizedを区別します。 |
| `adb::device::set-default` | 現在のシェルへのANDROID_SERIAL設定を保ち、各呼出しの-Serialを優先します。 |
| `adb::device::wait-for-path` | 現在は-Serialを使いません。端末指定、待機時間の検査、リモートのパスの引用、通信失敗と時間切れの区別が必要です。 |
| `adb::device::screen::capture-once` | 現在は-Serialを使いません。端末指定と保存先の契約を扱い、取得失敗で既存の画像を空にしない処理が必要です。 |
| `adb::device::screen::capture-continuous` | 端末指定、間隔と回数の検査、保存先と出力の契約を扱います。取得失敗と中断を保持します。 |
| `adb::device::select-and-pull` | 現在は通常のpullだけです。既存の契約にある端末内ファイルの選択と、選択中断を扱います。 |
| `adb::device::bootloader::enter` | ADBのreboot bootloaderを保ち、端末がfastbootへ切り替わることを確認します。 |
| `adb::device::bootloader::unlock` | 現在のadb oem unlockは、通常のADBコマンドとして扱えません。fastbootの端末指定と機種に対応した解除操作、画面確認、データ消去を伴う処理を別に扱います。 |
| `adb::device::verity::disable` | 対応する開発用端末でだけ実行できることを検査し、非対応を成功と扱いません。 |
| `adb::device::partition::remount` | rootの可否と対象ビルドの制限を確認し、再起動が必要な状態を区別します。 |
| `adb::device::partition::sha256` | 現在は-Serialとパスの検査がありません。/dev/block配下の許可したパスだけを対象とし、端末側のシェルで別のコマンドを実行させない構成が必要です。 |
| `adb::device::build::fingerprint` | 端末指定と取得失敗を保持し、文字列を返す処理を保ちます。 |
| `adb::device::build::date` | Unix秒の取得と終了状態を確認し、日時の表記を変換する場合は別の操作として扱います。 |
| `adb::device::slot::suffix` | 空の値を返す単一スロット端末と、取得失敗を区別します。 |
| `adb::device::build::kernel-version` | 端末指定と取得失敗を保持し、カーネルの版を返します。 |
| `adb::wake::lock` | 現在は充電中のスリープ抑止です。既存契約のsysfs wake lock取得とは一致しておらず、rootと対応カーネルを確認する必要があります。 |
| `adb::wake::unlock` | 現在は充電中のスリープ抑止の解除です。既存契約のsysfs wake lock解放を扱う必要があります。 |
| `adb::wake::list` | 現在はdumpsys powerを返します。既存契約のsysfs wake lock状態とは区別し、rootと対応カーネルを確認します。 |
| `adb::server::start` | ホストのADBサーバー開始を保ちます。 |
| `adb::server::stop` | ホストのADBサーバー停止を保ちます。 |
| `adb::server::restart` | 停止が成功してから開始する処理を保ちます。 |

## 導入を支える処理

`package::_install`と`package::_install-cask`は、指定した版、再実行、更新、ダウングレードの挙動を各パッケージ管理ツールで一致させる必要があります。
HomebrewのNAME@VERSIONは任意の過去版を取得する指定ではないため、取得可能なformulaとcaskの版を先に照合します。
Fedoraでは導入済み版からの更新と旧版指定を別々に確認します。

取得物のCPU、HTTPSのURL、非空のファイルを検査する現在の処理は保ちます。
取得、展開、コピーの途中で失敗した場合は、一時ファイルを片付け、既存のSDK、アプリ、設定を保持します。
環境設定の保存では、シェル内に一時配列を残さず、値とパスをシェル文字列として正しく引用します。

`Install-WUGit`と`Install-WUGitHubCli`に直接対応するBashStockの導入関数はありません。
Gitを必要とするSDK導入では、Gitの存在確認と依存パッケージの導入を扱います。
GitHub CLIを全導入関数の前提にする根拠はありません。

Chromeのプロファイル書出しとAWS VPN Clientのログ操作はsrc/install.shにありますが、ソフトウェアの導入とAndroid操作には該当しません。

## 実機確認

対象OSはFedora 34とUbuntu 18.04、20.04、22.04、24.04、26.04、および以後のLTSです。
macOS固有の関数はIntel MacとApple Siliconで確認し、提供元が配布していないOSとCPUは別の対応として記録します。
初回導入、再実行、対応する最新安定版への更新、版指定、起動、再ログイン後の設定を確認します。

SDKの置換では、取得失敗、展開失敗、起動確認失敗で元のSDKと設定を保持することを確認します。
Androidでは、実機接続、offline、unauthorized、複数端末、AVD起動、起動途中のプロセス終了、時間切れを確認します。
実行できない組合せと未実装の処理を、確認済みの対応として扱いません。
