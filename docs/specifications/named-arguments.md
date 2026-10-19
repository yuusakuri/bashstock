# 名前付き引数とTab補完の仕様

この文書は、BashStockの公開関数が使う名前付き引数の表記と、Tab補完の契約を定義します。

## 対象

複数の設定値を受け取る公開関数を対象とする。1つか2つの必須値だけを受け取る関数は、名前付き引数にせず位置引数のままでよい。

## 表記

値を取る引数は`--name VALUE`の形式にする。真偽値を表す引数は値を取らず、指定するだけで真になる。

```bash
example::run --name sample --count 3
example::run --name sample --force
```

引数名は`--`に続く小文字のkebab-case形式（例：`--output-directory`）にする。GNUの長いoptionと同じ表記で、`--name=VALUE`の結合形と短いoptionは受け付けない。

## 関数内の解析

関数内ではBashの`while`と`case`で引数を解析する。値を取る引数では、`case`の中で`arg::require-next "$#" "$1"`を呼び出してから値をローカル変数へ代入する。すべての引数を読み終えた後、`arg::require`などで必須引数を検査する。

```bash
user::create() {
  local name=''
  local shell='/bin/bash'
  local force='false'

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --name)
        arg::require-next "$#" "$1" || return "$?"
        name=$2
        shift 2
        ;;
      --shell)
        arg::require-next "$#" "$1" || return "$?"
        shell=$2
        shift 2
        ;;
      --force)
        force='true'
        shift
        ;;
      *)
        arg::unknown "$1" || return "$?"
        ;;
    esac
  done

  arg::require --name "${name}" || return "$?"

  # 本処理
}
```

引数名からローカル変数への対応は、この`case`を読めば分かる状態を維持する。引数仕様を表現する独自DSLは使用しない。

### 検査関数

`src/arguments.sh`が提供する検査関数は次のとおり。値の存在確認、必須値の確認、型や形式の検査、不明な引数のエラー生成を共通化する。すべて失敗時に終了状態64を返し、標準エラー出力へ診断を書く。

| 関数 | 検査内容 |
|---|---|
| `arg::require-next ARGC OPTION` | `OPTION`の次に値が続くことを、残り引数数`ARGC`から検査する。 |
| `arg::require NAME VALUE` | `VALUE`が空でないことを検査する。 |
| `arg::integer NAME VALUE` | `VALUE`が10進整数であることを検査する。 |
| `arg::one-of NAME VALUE CANDIDATE...` | `VALUE`が`CANDIDATE`のいずれかと一致することを検査する。 |
| `arg::unknown OPTION` | `case`の`*)`分岐で、認識できない引数を報告する。 |

関数ローカル変数への動的代入を目的に`eval`を使う設計は採用しない。

## Tab補完

名前付き引数を公開する関数は、同じ名前空間に`::_<処理>-args`形式のTab補完用内部関数を1つ持つ。公開関数が`user::create`の場合は`user::_create-args`、`service::restart`の場合は`service::_restart-args`とする。下位名前空間を持つ関数（`git::stash::patch`など）は`git::stash::_patch-args`とする。

補完用内部関数は、引数なしで呼び出されると利用可能な引数名を1行ずつ標準出力へ書く。直前の引数名を1つ受け取って呼び出されると、その引数の値候補を1行ずつ標準出力へ書く。候補がない場合は何も書かない。

```bash
user::_create-args() {
  case "${1-}" in
    --shell)
      printf '%s\n' /bin/bash /bin/zsh
      ;;
    '')
      printf '%s\n' --name --shell --force
      ;;
  esac
}
```

`src/completion.sh`の`arg::completion::dispatch`は、補完対象の公開関数名から補完用内部関数名を自動的に導出して呼び出す。中央のdispatcherには個別関数の知識を持たせない。`arg::completion::register-all`は、呼び出された時点で定義されているすべての`::_*-args`関数を検出し、対応する公開関数へ`complete -F arg::completion::dispatch`を登録する。

対話型Bashでは、最初の読み込み時に`arg::completion::register-all`を自動で呼び出す。非対話型Bashでは自動登録しない。読み込み後に補完用の関数を定義した場合は、`arg::completion::register-all`を明示的に呼び出して登録できる。

新しい名前付き引数の公開関数を追加するときは、その関数と対応する`::_<処理>-args`を同じ機能ファイルへ追加するだけでよい。中央の補完登録一覧を手動で更新する必要はない。

補完実装はBash 3.2で利用できる機能だけを使用する。

## 検証項目

名前付き引数とTab補完を持つ公開関数を追加または変更するときは、次を確認する。

- `::_<処理>-args`が返す引数を対応する公開関数が受理すること。
- 公開すると定めた名前付き引数がすべて補完候補に含まれること。
- 値補完が対象引数の直後だけで動作すること。
- 補完定義を持つ公開関数へ`arg::completion::dispatch`が登録されること。

`scripts/lint`は`scripts/check-completion`を実行し、名前付き引数を解析する公開関数に補完用内部関数があること、補完用内部関数がその引数をすべて列挙することを検査します。
名前付き引数は、関数と、関数が`"$@"`を渡す内部の解析関数の`case`分岐と`"$1" == '--name'`の比較から読み取ります。
[test/arguments.bats](../../test/arguments.bats)は、補完用内部関数が列挙する引数を対応する公開関数が受理することと、この契約を検証する例を含みます。
