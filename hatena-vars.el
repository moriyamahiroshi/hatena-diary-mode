(provide 'hatena-vars)

(defgroup hatena nil
  "major mode for Hatena::Diary"
  :prefix "hatena-"
  :group 'hypermedia)

(defgroup hatena-face nil
  "Hatena, Faces."
  :prefix "hatena-"
  :group 'hatena)

(defcustom hatena-usrid nil
  "hatena-diary-mode のユーザー名"
  :type 'string
  :group 'hatena)

(defcustom hatena-directory 
  (expand-file-name "~/.hatena/")
  "日記を保存するディレクトリ."
  :type 'directory
  :group 'hatena)

(defcustom hatena-init-file (concat
			     (file-name-as-directory hatena-directory)
			     "init")
  "*hatena-diary-mode の初期化ファイル。"
  :type 'file
  :group 'hatena)

(defcustom hatena-password-file 
  (expand-file-name (concat hatena-directory ".password"))
  "パスを保存するファイル"
  :type 'file
  :group 'hatena)

(defcustom hatena-entry-type 1
  "エントリのマークアップ * をどのように処理するか。
0なら * を *pn* に、1 なら * を *<time>* に置きかえて送信"
  :type 'integer
  :group 'hatena)

(defcustom hatena-change-day-offset 6
  "はてなで, 日付を変える時間 .+6 で午前 6 時に日付を変更する."
  :type 'integer
  :group 'hatena)

(defcustom hatena-trivial nil
  "ちょっとした更新をするかどうか. non-nil で\"ちょっとした更新\"になる"
  :type 'boolean
  :group 'hatena)

(defcustom hatena-use-file t
  "パスワードを(暗号化して)保存するかどうか non-nil ならパスワードを base 64 でエンコードして保存する"
  :type 'boolean
  :group 'hatena)

(defcustom hatena-cookie 
  (expand-file-name 
   (concat hatena-directory "Cookie@hatena"))
  "クッキーの名前。"
  :type 'file
  :group 'hatena)

(defcustom hatena-browser-function nil  ;; 普通は、'browse-url
  "Function to call browser.
If non-nil, `hatena-submit' calls this function.  The function
is expected to accept only one argument(URL)."
  :type 'symbol
  :group 'hatena)

(defcustom hatena-proxy ""
  "curl に必要な時、ここで設定する"
  :type 'string
  :group 'hatena)

(defcustom hatena-default-coding-system 'euc-jp
  "デフォルトのコーディングシステム"
  :type 'symbol
  :group 'hatena)


(defcustom hatena-url "http://d.hatena.ne.jp/"
  "はてなのアドレス"
  :type 'string
  :group 'hatena)

(defcustom hatena-twitter-flag nil
  "日記更新時にtwitterに通知をするかどうか. non-nil で\"twitterに通知\"になる"
  :type 'boolean
  :group 'hatena)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;日記ファイルの正規表現
(defvar hatena-fname-regexp
  "\\([0-9][0-9][0-9][0-9]\\)\\([01][0-9]\\)\\([0-3][0-9]\\)$" )
(defvar hatena-diary-mode-map nil)

;;古い仕様
(defvar hatena-header-regexp 
  (concat "\\`      Title: \\(.*\\)\n"
          "Last Update: \\(.*\\)\n"
          "____________________________________________________" ))

(defvar hatena-tmpfile 
  (expand-file-name (concat hatena-directory "hatena-temp.dat")))
(defvar hatena-tmpfile2
  (expand-file-name (concat hatena-directory "hatena-temp2.dat")))
(defvar hatena-curl-command "curl" "curl コマンド")

(defvar hatena-twitter-prefix nil "twitterに投稿する内容")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;face

(defvar hatena-font-lock-keywords nil)
(defvar hatena-html-face 'hatena-html-face)
(defvar hatena-title-face 'hatena-title-face)
(defvar hatena-header-face 'hatena-header-face)
(defvar hatena-subtitle-face 'hatena-subtitle-face)
(defvar hatena-markup-face 'hatena-markup-face)
(defvar hatena-link-face 'hatena-link-face)

(defface hatena-title-face
  '((((class color) (background light)) (:foreground "Navy" :bold t))
    (((class color) (background dark)) (:foreground "wheat" :bold t)))
  "titleの face"
  :group 'hatena-face)

(defface hatena-header-face
  '((((class color) (background light)) (:foreground "Gray70" :bold t))
    (((class color) (background dark)) (:foreground "SkyBlue4" :bold t)))
  "last updateの face"
  :group 'hatena-face)

(defface hatena-subtitle-face 
  '((((class color) (background light)) (:foreground "DarkOliveGreen"))
    (((class color) (background dark)) (:foreground "wheat")))
  "サブタイトルのface"
  :group 'hatena-face)

(defface hatena-markup-face 
  '((((class color) (background light)) (:foreground "firebrick" :bold t))
    (((class color) (background dark)) (:foreground "IndianRed3" :bold t)))
  "はてなのマークアップのface"
  :group 'hatena-face)

(defface hatena-html-face 
  '((((class color) (background light)) (:foreground "DarkSeaGreen4"))
    (((class color) (background dark)) (:foreground "Gray50")))
  "htmlのface"
  :group 'hatena-face)

(defface hatena-link-face 
  '((((class color) (background light)) (:foreground "DarkSeaGreen4"))
    (((class color) (background dark)) (:foreground "wheat")))
  "htmlタグで挟まれた部分のface"
  :group 'hatena-face)

;-----------------------------------------------------------------------------------
; はてな記法ヘルプ
;-----------------------------------------------------------------------------------
(defvar hatena-help-syntax-index
  'dummy
  "入力支援記法 `hatena-help-syntax-input'
   自動リンク `hatena-help-syntax-autolink'
   はてな内自動リンク `hatena-help-syntax-hatena-autolink'
   入力支援機能 `hatena-help-syntax-other'")

(defvar hatena-help-syntax-input
  'dummy
  "入力支援記法

|------------------------------+------------------------------+-----------------------------------------------------|
| 記法名                       | 書式                         | 機能                                                |
|------------------------------+------------------------------+-----------------------------------------------------|
| 見出し記法                   | *~~                        | 日記に見出し（h3）を付けます                        |
| 時刻付き見出し記法           | *t*~~, *t+1*~~           | 見出しに編集時刻を保存し表示します                  |
| name属性付き見出し記法       | *name*~~                   | 見出しに好きな name 属性をつけます                  |
| カテゴリー記法               | *[~~]~~                  | 日記にカテゴリーを設定します                        |
| !小見出し記法                 | **~~                       | 日記に小見出し（h4）をつけます                      |
| 小々見出し記法               | ***~~                      | 日記に小々見出し記法（h5）をつけます                |
| リスト記法                   | -~~, --~~, +~~, ++~~ | リスト（li）を簡単に記述します                      |
| 定義リスト記法               | :~~:~~                   | 定義リスト（dt）を簡単に記述します                  |
| 表組み記法                   | | ~~  | ~~  |            | 表組み（table）を簡単に記述します                   |
|                              | |*~~  | ~~  |            |                                                     |
| 引用記法                     | >> ~~ <<                   | 引用ブロック（blockquote）を簡単に記述します        |
| pre記法                      | >| ~~ |<                   | 整形したテキストをそのまま表示します（pre）         |
| スーパーpre記法              | >|| ~~ ||<                 | 整形したHTMLなどのソースをそのまま表示します（pre） |
| スーパーpre記法              | >|ファイルタイプ| ~~ ||<   | 整形したプログラムのソースコードを                  |
| （シンタックス・ハイライト） | >|??| ~~ ||<               | 色付けして表示します（pre）                         |
|                              |                              |                                                     |
| aa記法                       | >|aa| ~~ ||<               | アスキーアートを簡単にきれいに表示します            |
| 脚注記法                     | (( ~~ ))                   | 日記に脚注を設定します                              |
| 続きを読む記法               | ====                         | 次の見出しまでその後の日記を「続きを読む」にします  |
| スーパー続きを読む記法       | =====                        | 見出しも含めてその後の内容を「続きを読む」にします  |
| 改行記法                     | (連続した空白の行2つ)        | 改行（br）を挿入します                              |
| pタグ停止記法                | >< ~~ ><                   | 自動挿入される p タグを停止します                   |
| tex記法                      | [tex:~~]                   | mimeTeX を使って数式を表示します                    |
| ウクレレ記法                 | [uke:~~]                   | ウクレレのコード譜を表示します                      |
|------------------------------+------------------------------+-----------------------------------------------------|
")
	
(defvar hatena-help-syntax-autolink
  'dummy
  "自動リンク

|--------------------+---------------------------------+--------------------------------------------|
| 記法名             | 書式                            | 機能                                       |
|--------------------+---------------------------------+--------------------------------------------|
| http記法           | http://~~                     | URLへの始まるリンクを簡単に記述します      |
|                    | [http: //~~:title]            |                                            |
|                    | [http://~~:barcode]           |                                            |
|                    | [http://~~:image]             |                                            |
|                    |                                 |                                            |
| mailto記法         | mailto:~~                     | メールアドレスへのリンクを簡単に記述します |
| niconico記法       | [niconico:sm*******]            | ニコニコ動画の再生プレーヤーを表示します   |
| google記法         | [google:~~]                   | Google の検索結果にリンクします            |
|                    | [google:image:~~]             |                                            |
|                    | [google:news:~~]              |                                            |
|                    |                                 |                                            |
| map記法            | map:x~~y~~ (:map)           | Googleマップを表示し、リンクします         |
|                    | [map:~~]                      |                                            |
|                    | [map:t:~~]                    |                                            |
|                    |                                 |                                            |
| amazon記法         | [amazon:~~]                   | Amazon の検索結果にリンクします            |
| wikipedia記法      | [wikipedia:~~]                | Wikipediaの記事にリンクします              |
| twitter記法        | twitter:〜〜:title、            | Twitterのつぶやきにリンクします            |
|                    | twitter:〜〜:tweet、            |                                            |
|                    | twitter:〜〜:detail、           |                                            |
|                    | twitter:〜〜:detail:right、     |                                            |
|                    | twitter:〜〜:detail:left、      |                                            |
|                    | twitter:〜〜:tree、             |                                            |
|                    | [twitter:@hatenadiary]、        |                                            |
|                    | [http://twitter.com/hatenadiary |                                            |
|                    | /status/〜〜:twitter:title]     |                                            |
| 自動リンク停止記法 | [] はてな記法 []                | はてな記法による自動リンクを停止します     |
|--------------------+---------------------------------+--------------------------------------------|
")

(defvar hatena-help-syntax-hatena-autolink
  'dummy
  "はてな内自動リンク

|---------------+-------------------------------+-------------------------------------------------|
| 記法名        | 書式                          | 機能                                            |
|---------------+-------------------------------+-------------------------------------------------|
| id記法        | id:~~、 id:~~:archive     | はてなユーザーにリンクし、                      |
|               | id:~~:about、id:~~:image  | 自動トラックバックを送信します                  |
|               | id:~~:detail、id:〜〜+〜〜  |                                                 |
|               |                               |                                                 |
| question記法  | question:~~:title           | 人力検索はてなにリンクし、                      |
|               | question:~~:detail          | 自動トラックバックを送信します                  |
|               | question:~~:image           |                                                 |
|               |                               |                                                 |
| search記法    | [search:~~]                 | はてな検索の検索結果にリンクします              |
|               | [search:keyword:~~]         |                                                 |
|               | [search:question:~~]        |                                                 |
|               | [search:asin:~~]            |                                                 |
|               | [search:web:~~]             |                                                 |
|               |                               |                                                 |
| antenna記法   | a:id:~~                     | はてなアンテナにリンクします                    |
| bookmark記法  | b:id:~~ (:~~)             | はてなブックマークにリンクします                |
|               | [b:id:~~:t:~~]            |                                                 |
|               | [b:t:~~]                    |                                                 |
|               | [b:keyword:~~]              |                                                 |
|               |                               |                                                 |
| diary記法     | d:id:~~                     | はてなダイアリーにリンクし、                    |
|               | d:id:〜〜+〜〜                | 自動トラックバックを送信します                  |
|               | [d:keyword:~~]              |                                                 |
|               |                               |                                                 |
| fotolife記法  | f:id:~~:~~:image          | はてなフォトライフの写真を表示し、              |
|               | f:id:~~:~~:movie          | 自動トラックバックを送信します                  |
|               | f:id:~~(:favorite)          |                                                 |
|               |                               |                                                 |
| group記法     | g:~~                        | はてなグループにリンクし、                      |
|               | g:~~:id:~~                | 自動トラックバックを送信します                  |
|               | [g:~~:keyword:~~]、他     |                                                 |
|               |                               |                                                 |
| haiku記法     | [h:keyword:~~]              | はてなハイクにリンクします                      |
|               | [h:id:~~]                   |                                                 |
|               |                               |                                                 |
| idea記法      | idea:~~ (:title)            | はてなアイデアにリンクし、                      |
|               | i:id:~~                     | 自動トラックバックを送信します                  |
|               | [i:t:~~]                    |                                                 |
|               |                               |                                                 |
| rss記法       | r:id:~~                     | はてなRSSにリンクします                         |
| graph記法     | graph:id:~~                 | はてなグラフを表示し、リンクします              |
|               | [graph:id:~~:~~ (:image)] |                                                 |
|               | [graph:t:~~]                |                                                 |
|               |                               |                                                 |
| keyword記法   | [[[[~~]]]]                      | キーワードにリンクします                        |
|               | [keyword:~~]                |                                                 |
|               | [keyword:~~:graph]、他      |                                                 |
|               |                               |                                                 |
| isbn/asin記法 | isbn:~~、、 、、            | 書籍・音楽・映画などの紹介リンクを表示します    |
|               | asin:~~                     |                                                 |
|               | isbn:~~:title               |                                                 |
|               | isbn:~~:image               |                                                 |
|               | isbn:~~:detail、他          |                                                 |
|               |                               |                                                 |
| rakuten記法   | [rakuten:~~]                | 楽天市場の商品の紹介リンクを表示します          |
| jan/ean記法   | jan:~~、 ean:~~、他       | JAN/EANコードを使った商品紹介リンクを表示します |
| ugomemo記法   | ugomemo:~~                  | うごメモを貼り付けます                          |
|---------------+-------------------------------+-------------------------------------------------|
")

(defvar hatena-help-syntax-other
  'dummy
  "入力支援機能

|--------------------------------------+----------------------------------------------------------|
| ヘルプ                               | 書式                                                     |
|--------------------------------------+----------------------------------------------------------|
| 「*」や「-」をそのまま行頭に表示する | （行頭に半角の空白をつける）                             |
| 下書き記法                           | <!-- ~~ -->                                            |
| 修正時刻保存機能                     | <ins> ~~ </ins>, <del> ~~ </del>                     |
| cite、title属性                      | <blockquote cite=\"~~\" title=\"~~\"> ~~ </blockquote> |
| 自動リンクをタグ内で使う             | <a href=\"はてな記法\"> ~~ </a>                          |
|--------------------------------------+----------------------------------------------------------|
")






