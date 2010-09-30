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
  "hatena-diary-mode �Υ桼����̾"
  :type 'string
  :group 'hatena)

(defcustom hatena-directory 
  (expand-file-name "~/.hatena/")
  "��������¸����ǥ��쥯�ȥ�."
  :type 'directory
  :group 'hatena)

(defcustom hatena-init-file (concat
			     (file-name-as-directory hatena-directory)
			     "init")
  "*hatena-diary-mode �ν�����ե����롣"
  :type 'file
  :group 'hatena)

(defcustom hatena-password-file 
  (expand-file-name (concat hatena-directory ".password"))
  "�ѥ�����¸����ե�����"
  :type 'file
  :group 'hatena)

(defcustom hatena-entry-type 1
  "����ȥ�Υޡ������å� * ��ɤΤ褦�˽������뤫��
0�ʤ� * �� *pn* �ˡ�1 �ʤ� * �� *<time>* ���֤�����������"
  :type 'integer
  :group 'hatena)

(defcustom hatena-change-day-offset 6
  "�ϤƤʤ�, ���դ��Ѥ������ .+6 �Ǹ��� 6 �������դ��ѹ�����."
  :type 'integer
  :group 'hatena)

(defcustom hatena-trivial nil
  "����äȤ��������򤹤뤫�ɤ���. non-nil ��\"����äȤ�������\"�ˤʤ�"
  :type 'boolean
  :group 'hatena)

(defcustom hatena-use-file t
  "�ѥ���ɤ�(�Ź沽����)��¸���뤫�ɤ��� non-nil �ʤ�ѥ���ɤ� base 64 �ǥ��󥳡��ɤ�����¸����"
  :type 'boolean
  :group 'hatena)

(defcustom hatena-cookie 
  (expand-file-name 
   (concat hatena-directory "Cookie@hatena"))
  "���å�����̾����"
  :type 'file
  :group 'hatena)

(defcustom hatena-browser-function nil  ;; ���̤ϡ�'browse-url
  "Function to call browser.
If non-nil, `hatena-submit' calls this function.  The function
is expected to accept only one argument(URL)."
  :type 'symbol
  :group 'hatena)

(defcustom hatena-proxy ""
  "curl ��ɬ�פʻ������������ꤹ��"
  :type 'string
  :group 'hatena)

(defcustom hatena-default-coding-system 'euc-jp
  "�ǥե���ȤΥ����ǥ��󥰥����ƥ�"
  :type 'symbol
  :group 'hatena)


(defcustom hatena-url "http://d.hatena.ne.jp/"
  "�ϤƤʤΥ��ɥ쥹"
  :type 'string
  :group 'hatena)

(defcustom hatena-twitter-flag nil
  "������������twitter�����Τ򤹤뤫�ɤ���. non-nil ��\"twitter������\"�ˤʤ�"
  :type 'boolean
  :group 'hatena)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;�����ե����������ɽ��
(defvar hatena-fname-regexp
  "\\([0-9][0-9][0-9][0-9]\\)\\([01][0-9]\\)\\([0-3][0-9]\\)$" )
(defvar hatena-diary-mode-map nil)

;;�Ť�����
(defvar hatena-header-regexp 
  (concat "\\`      Title: \\(.*\\)\n"
          "Last Update: \\(.*\\)\n"
          "____________________________________________________" ))

(defvar hatena-tmpfile 
  (expand-file-name (concat hatena-directory "hatena-temp.dat")))
(defvar hatena-tmpfile2
  (expand-file-name (concat hatena-directory "hatena-temp2.dat")))
(defvar hatena-curl-command "curl" "curl ���ޥ��")

(defvar hatena-twitter-prefix nil "twitter����Ƥ�������")
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
  "title�� face"
  :group 'hatena-face)

(defface hatena-header-face
  '((((class color) (background light)) (:foreground "Gray70" :bold t))
    (((class color) (background dark)) (:foreground "SkyBlue4" :bold t)))
  "last update�� face"
  :group 'hatena-face)

(defface hatena-subtitle-face 
  '((((class color) (background light)) (:foreground "DarkOliveGreen"))
    (((class color) (background dark)) (:foreground "wheat")))
  "���֥����ȥ��face"
  :group 'hatena-face)

(defface hatena-markup-face 
  '((((class color) (background light)) (:foreground "firebrick" :bold t))
    (((class color) (background dark)) (:foreground "IndianRed3" :bold t)))
  "�ϤƤʤΥޡ������åפ�face"
  :group 'hatena-face)

(defface hatena-html-face 
  '((((class color) (background light)) (:foreground "DarkSeaGreen4"))
    (((class color) (background dark)) (:foreground "Gray50")))
  "html��face"
  :group 'hatena-face)

(defface hatena-link-face 
  '((((class color) (background light)) (:foreground "DarkSeaGreen4"))
    (((class color) (background dark)) (:foreground "wheat")))
  "html�����Ƕ��ޤ줿��ʬ��face"
  :group 'hatena-face)

;-----------------------------------------------------------------------------------
; �ϤƤʵ�ˡ�إ��
;-----------------------------------------------------------------------------------
(defvar hatena-help-syntax-index
  'dummy
  "���ϻٱ絭ˡ `hatena-help-syntax-input'
   ��ư��� `hatena-help-syntax-autolink'
   �ϤƤ��⼫ư��� `hatena-help-syntax-hatena-autolink'
   ���ϻٱ絡ǽ `hatena-help-syntax-other'")

(defvar hatena-help-syntax-input
  'dummy
  "���ϻٱ絭ˡ

|------------------------------+------------------------------+-----------------------------------------------------|
| ��ˡ̾                       | ��                         | ��ǽ                                                |
|------------------------------+------------------------------+-----------------------------------------------------|
| ���Ф���ˡ                   | *������                        | �����˸��Ф���h3�ˤ��դ��ޤ�                        |
| �����դ����Ф���ˡ           | *t*������, *t+1*������           | ���Ф����Խ��������¸��ɽ�����ޤ�                  |
| name°���դ����Ф���ˡ       | *name*������                   | ���Ф��˹����� name °����Ĥ��ޤ�                  |
| ���ƥ��꡼��ˡ               | *[������]������                  | �����˥��ƥ��꡼�����ꤷ�ޤ�                        |
| !�����Ф���ˡ                 | **������                       | �����˾����Ф���h4�ˤ�Ĥ��ޤ�                      |
| �������Ф���ˡ               | ***������                      | �����˾������Ф���ˡ��h5�ˤ�Ĥ��ޤ�                |
| �ꥹ�ȵ�ˡ                   | -������, --������, +������, ++������ | �ꥹ�ȡ�li�ˤ��ñ�˵��Ҥ��ޤ�                      |
| ����ꥹ�ȵ�ˡ               | :������:������                   | ����ꥹ�ȡ�dt�ˤ��ñ�˵��Ҥ��ޤ�                  |
| ɽ�Ȥߵ�ˡ                   | | ������  | ������  |            | ɽ�Ȥߡ�table�ˤ��ñ�˵��Ҥ��ޤ�                   |
|                              | |*������  | ������  |            |                                                     |
| ���ѵ�ˡ                     | >> ������ <<                   | ���ѥ֥�å���blockquote�ˤ��ñ�˵��Ҥ��ޤ�        |
| pre��ˡ                      | >| ������ |<                   | ���������ƥ����Ȥ򤽤Τޤ�ɽ�����ޤ���pre��         |
| �����ѡ�pre��ˡ              | >|| ������ ||<                 | ��������HTML�ʤɤΥ������򤽤Τޤ�ɽ�����ޤ���pre�� |
| �����ѡ�pre��ˡ              | >|�ե����륿����| ������ ||<   | ���������ץ����Υ����������ɤ�                  |
| �ʥ��󥿥å������ϥ��饤�ȡ� | >|??| ������ ||<               | ���դ�����ɽ�����ޤ���pre��                         |
|                              |                              |                                                     |
| aa��ˡ                       | >|aa| ������ ||<               | �������������Ȥ��ñ�ˤ��줤��ɽ�����ޤ�            |
| ����ˡ                     | (( ������ ))                   | �����˵�������ꤷ�ޤ�                              |
| ³�����ɤ൭ˡ               | ====                         | ���θ��Ф��ޤǤ��θ���������³�����ɤ�פˤ��ޤ�  |
| �����ѡ�³�����ɤ൭ˡ       | =====                        | ���Ф���ޤ�Ƥ��θ�����Ƥ��³�����ɤ�פˤ��ޤ�  |
| ���Ե�ˡ                     | (Ϣ³��������ι�2��)        | ���ԡ�br�ˤ��������ޤ�                              |
| p������ߵ�ˡ                | >< ������ ><                   | ��ư��������� p ��������ߤ��ޤ�                   |
| tex��ˡ                      | [tex:������]                   | mimeTeX ��Ȥäƿ�����ɽ�����ޤ�                    |
| ������쵭ˡ                 | [uke:������]                   | �������Υ��������ɽ�����ޤ�                      |
|------------------------------+------------------------------+-----------------------------------------------------|
")
	
(defvar hatena-help-syntax-autolink
  'dummy
  "��ư���

|--------------------+---------------------------------+--------------------------------------------|
| ��ˡ̾             | ��                            | ��ǽ                                       |
|--------------------+---------------------------------+--------------------------------------------|
| http��ˡ           | http://������                     | URL�ؤλϤޤ��󥯤��ñ�˵��Ҥ��ޤ�      |
|                    | [http: //������:title]            |                                            |
|                    | [http://������:barcode]           |                                            |
|                    | [http://������:image]             |                                            |
|                    |                                 |                                            |
| mailto��ˡ         | mailto:������                     | �᡼�륢�ɥ쥹�ؤΥ�󥯤��ñ�˵��Ҥ��ޤ� |
| niconico��ˡ       | [niconico:sm*******]            | �˥��˥�ư��κ����ץ졼�䡼��ɽ�����ޤ�   |
| google��ˡ         | [google:������]                   | Google �θ�����̤˥�󥯤��ޤ�            |
|                    | [google:image:������]             |                                            |
|                    | [google:news:������]              |                                            |
|                    |                                 |                                            |
| map��ˡ            | map:x������y������ (:map)           | Google�ޥåפ�ɽ��������󥯤��ޤ�         |
|                    | [map:������]                      |                                            |
|                    | [map:t:������]                    |                                            |
|                    |                                 |                                            |
| amazon��ˡ         | [amazon:������]                   | Amazon �θ�����̤˥�󥯤��ޤ�            |
| wikipedia��ˡ      | [wikipedia:������]                | Wikipedia�ε����˥�󥯤��ޤ�              |
| twitter��ˡ        | twitter:����:title��            | Twitter�ΤĤ֤䤭�˥�󥯤��ޤ�            |
|                    | twitter:����:tweet��            |                                            |
|                    | twitter:����:detail��           |                                            |
|                    | twitter:����:detail:right��     |                                            |
|                    | twitter:����:detail:left��      |                                            |
|                    | twitter:����:tree��             |                                            |
|                    | [twitter:@hatenadiary]��        |                                            |
|                    | [http://twitter.com/hatenadiary |                                            |
|                    | /status/����:twitter:title]     |                                            |
| ��ư�����ߵ�ˡ | [] �ϤƤʵ�ˡ []                | �ϤƤʵ�ˡ�ˤ�뼫ư��󥯤���ߤ��ޤ�     |
|--------------------+---------------------------------+--------------------------------------------|
")

(defvar hatena-help-syntax-hatena-autolink
  'dummy
  "�ϤƤ��⼫ư���

|---------------+-------------------------------+-------------------------------------------------|
| ��ˡ̾        | ��                          | ��ǽ                                            |
|---------------+-------------------------------+-------------------------------------------------|
| id��ˡ        | id:�������� id:������:archive     | �ϤƤʥ桼�����˥�󥯤���                      |
|               | id:������:about��id:������:image  | ��ư�ȥ�å��Хå����������ޤ�                  |
|               | id:������:detail��id:����+����  |                                                 |
|               |                               |                                                 |
| question��ˡ  | question:������:title           | ���ϸ����ϤƤʤ˥�󥯤���                      |
|               | question:������:detail          | ��ư�ȥ�å��Хå����������ޤ�                  |
|               | question:������:image           |                                                 |
|               |                               |                                                 |
| search��ˡ    | [search:������]                 | �ϤƤʸ����θ�����̤˥�󥯤��ޤ�              |
|               | [search:keyword:������]         |                                                 |
|               | [search:question:������]        |                                                 |
|               | [search:asin:������]            |                                                 |
|               | [search:web:������]             |                                                 |
|               |                               |                                                 |
| antenna��ˡ   | a:id:������                     | �ϤƤʥ���ƥʤ˥�󥯤��ޤ�                    |
| bookmark��ˡ  | b:id:������ (:������)             | �ϤƤʥ֥å��ޡ����˥�󥯤��ޤ�                |
|               | [b:id:������:t:������]            |                                                 |
|               | [b:t:������]                    |                                                 |
|               | [b:keyword:������]              |                                                 |
|               |                               |                                                 |
| diary��ˡ     | d:id:������                     | �ϤƤʥ������꡼�˥�󥯤���                    |
|               | d:id:����+����                | ��ư�ȥ�å��Хå����������ޤ�                  |
|               | [d:keyword:������]              |                                                 |
|               |                               |                                                 |
| fotolife��ˡ  | f:id:������:������:image          | �ϤƤʥե��ȥ饤�դμ̿���ɽ������              |
|               | f:id:������:������:movie          | ��ư�ȥ�å��Хå����������ޤ�                  |
|               | f:id:������(:favorite)          |                                                 |
|               |                               |                                                 |
| group��ˡ     | g:������                        | �ϤƤʥ��롼�פ˥�󥯤���                      |
|               | g:������:id:������                | ��ư�ȥ�å��Хå����������ޤ�                  |
|               | [g:������:keyword:������]��¾     |                                                 |
|               |                               |                                                 |
| haiku��ˡ     | [h:keyword:������]              | �ϤƤʥϥ����˥�󥯤��ޤ�                      |
|               | [h:id:������]                   |                                                 |
|               |                               |                                                 |
| idea��ˡ      | idea:������ (:title)            | �ϤƤʥ����ǥ��˥�󥯤���                      |
|               | i:id:������                     | ��ư�ȥ�å��Хå����������ޤ�                  |
|               | [i:t:������]                    |                                                 |
|               |                               |                                                 |
| rss��ˡ       | r:id:������                     | �ϤƤ�RSS�˥�󥯤��ޤ�                         |
| graph��ˡ     | graph:id:������                 | �ϤƤʥ���դ�ɽ��������󥯤��ޤ�              |
|               | [graph:id:������:������ (:image)] |                                                 |
|               | [graph:t:������]                |                                                 |
|               |                               |                                                 |
| keyword��ˡ   | [[[[������]]]]                      | ������ɤ˥�󥯤��ޤ�                        |
|               | [keyword:������]                |                                                 |
|               | [keyword:������:graph]��¾      |                                                 |
|               |                               |                                                 |
| isbn/asin��ˡ | isbn:���������� ����            | ���ҡ����ڡ��ǲ�ʤɤξҲ��󥯤�ɽ�����ޤ�    |
|               | asin:������                     |                                                 |
|               | isbn:������:title               |                                                 |
|               | isbn:������:image               |                                                 |
|               | isbn:������:detail��¾          |                                                 |
|               |                               |                                                 |
| rakuten��ˡ   | [rakuten:������]                | ��ŷ�Ծ�ξ��ʤξҲ��󥯤�ɽ�����ޤ�          |
| jan/ean��ˡ   | jan:�������� ean:��������¾       | JAN/EAN�����ɤ�Ȥä����ʾҲ��󥯤�ɽ�����ޤ� |
| ugomemo��ˡ   | ugomemo:������                  | ��������Ž���դ��ޤ�                          |
|---------------+-------------------------------+-------------------------------------------------|
")

(defvar hatena-help-syntax-other
  'dummy
  "���ϻٱ絡ǽ

|--------------------------------------+----------------------------------------------------------|
| �إ��                               | ��                                                     |
|--------------------------------------+----------------------------------------------------------|
| ��*�פ��-�פ򤽤Τޤ޹�Ƭ��ɽ������ | �ʹ�Ƭ��Ⱦ�Ѥζ����Ĥ����                             |
| ���񤭵�ˡ                           | <!-- ������ -->                                            |
| ����������¸��ǽ                     | <ins> ������ </ins>, <del> ������ </del>                     |
| cite��title°��                      | <blockquote cite=\"������\" title=\"������\"> ������ </blockquote> |
| ��ư��󥯤򥿥���ǻȤ�             | <a href=\"�ϤƤʵ�ˡ\"> ������ </a>                          |
|--------------------------------------+----------------------------------------------------------|
")






