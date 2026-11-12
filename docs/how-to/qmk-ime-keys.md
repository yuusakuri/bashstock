# HHKB の Alt 単押しで IME を切り替える

対象は、[yuusakuri/qmk_firmware](https://github.com/yuusakuri/qmk_firmware) のファームウェアを使う HHKB です。キーボードは US ANSI 配列で、交換用コントローラーの HHKB Alternate Controller を搭載した構成です。QMK でのキーボード識別子は `hhkb/ansi` です。

[コミット ac4adf8f909489276dba98251b7280f026448161](https://github.com/yuusakuri/qmk_firmware/commit/ac4adf8f909489276dba98251b7280f026448161) にある次のキーマップに対応します。

| キーマップ | 左 Alt の単押し | 右 Alt の単押し |
| --- | --- | --- |
| [`alt_convert_non_convert`](https://github.com/yuusakuri/qmk_firmware/tree/ac4adf8f909489276dba98251b7280f026448161/keyboards/hhkb/ansi/keymaps/alt_convert_non_convert) | 無変換（`KC_INT5`）で英数入力 | 変換（`KC_INT4`）で日本語入力 |
| [`alt_lang`](https://github.com/yuusakuri/qmk_firmware/tree/ac4adf8f909489276dba98251b7280f026448161/keyboards/hhkb/ansi/keymaps/alt_lang) | LANG2（`KC_LNG2`）で英数入力 | LANG1（`KC_LNG1`）で日本語入力 |

Ubuntu／Fedora の GNOME と IBus Mozc では、どちらのキーマップも左 Alt の単押しを英数入力、右 Alt の単押しを日本語入力に設定できます。単押しと長押しの判定はキーボードが行い、長押しでは通常の Alt キーとしてショートカットを使えます。

IBus Mozc を導入済みの GNOME セッションで BashStock を読み込み、次の順番で実行してください。

```bash
gnome::keyboard-layout::set-us
mozc::ibus::set-hiragana-as-default
keyboard::setup-ime-keys
gnome::input-source::setup-ime-keys
```

キーの対応付けには管理者権限を使います。GNOME と Mozc の設定は、普段デスクトップを使用する利用者の権限で実行してください。設定後は USB キーボードを接続し直してください。

`keyboard::setup-ime-keys` はすべての USB キーボードを対象にします。特定のキーボードだけを対象にする場合は、ベンダー ID と製品 ID をそれぞれ 4 桁の 16 進数で指定します。

```bash
keyboard::setup-ime-keys 4653 0001
```

Ubuntu では、`ubuntu::setup-desktop` でも一連の設定を行えます。
