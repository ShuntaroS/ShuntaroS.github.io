# リデザインの変更・検証記録

作業ブランチは `codex/paper-research-redesign` です。この記録はローカル実装・検証完了時点のものです。
以下の検証結果には、その後のPR作成・マージ・GitHub Pagesへの公開結果は含めていません。

コンセプトは「紙のように読む。Webのように触れる。」です。
白地、明朝系の本文、740pxの読み幅、細い罫線、空色の装飾と濃い青のリンクで構成しました。
Researchは日英別の本文で管理し、未発表の研究計画や新しい研究アイデアは追加していません。
Seminarsの未確定項目は `data/seminars.yaml` のnull値として残し、画面には相談案内を表示します。

## 検証結果

| 確認項目 | 結果 |
| --- | --- |
| Quartoによる全ページ生成 | Quarto 1.8.27で11ページを生成。警告・エラーなし。 |
| 普段のローカル確認 | quarto previewでRubyのデータ生成が実行され、プレビューが起動。 |
| 日本語・英語ナビゲーション | 全11ページの項目順、現在地、対応ページへの言語切替を検査。Seminarsの切替先は英語Research。 |
| モバイル表示 | Chromeで320・390・768・860・1024・1440pxの6幅、計66通りを確認。横はみ出しなし。代表ページの画面も目視確認。 |
| 操作 | 下線の伸長、矢印の4px移動、リンクの2px浮上・1px押下、キーボードフォーカス、本文スキップ、メニューの開閉・Escapeを確認。 |
| 動きを減らす設定 | prefers-reduced-motionでtransitionと変位を無効化することを確認。 |
| JavaScriptなし | 320px幅でもナビゲーションを表示し、言語切替が可能。 |
| WCAGの自動検査 | axe-core 4.10.3で11ページ×2幅の22回を検査。WCAG 2 A/AA、2.1 A/AAおよびbest-practiceの違反検出なし。 |
| 文字のコントラスト | 白背景に対し本文14.84:1、リンク7.25:1、補助文字5.58:1。下線のグラデーションで自動判定が保留になった箇所は色値を別途確認。 |
| 内部リンク・生成物 | 全ページの内部リンク、参照ファイル、ページ内ID、h1、main、言語を検査。未解決のMarkdown記法なし。 |
| GitHub Pages構成 | 既存の公開トリガー、権限、同時実行設定、デプロイ処理と照合。一致を確認。_siteと.nojekyllを維持。 |
| 実際のデプロイ | 未実行。GitHub側での公開成功までは検証対象に含めていません。 |

表示・操作の確認にはmacOSのChromeを使用しました。フォントは利用環境の明朝系・セリフ系フォントにフォールバックします。

## 変更したファイル

以下の40ファイルを変更・追加しました。`_includes/*.md` は元データからの生成物です。

| ファイル | 変更内容 |
| --- | --- |
| [.github/workflows/publish.yml](.github/workflows/publish.yml) | Quartoの描画前処理へ移したデータ生成ステップの重複を解消。公開条件・権限・デプロイ処理は維持。 |
| [.gitignore](.gitignore) | 一時生成するナビゲーションJSONをGit管理から除外。 |
| [README.md](README.md) | quarto previewによる確認、編集箇所、公開手順、文章の公開情報による根拠を整理。 |
| [REDESIGN.md](REDESIGN.md) | 今回の変更一覧と検証結果を記録。 |
| [_quarto.yml](_quarto.yml) | Rubyのpre-render、740pxの本文幅、共通テーマ、レイアウト処理を設定。 |
| [styles.scss](styles.scss) | 白地・明朝系・余白・罫線のデザインに変更。空色の装飾、濃青のリンク、操作・フォーカス・動作軽減設定を実装。 |
| [index.qmd](index.qmd) | 日本語トップページの見出し・メタデータを整理。 |
| [en/index.qmd](en/index.qmd) | 英語トップページを研究紹介への入口として整理。 |
| [research.qmd](research.qmd) | 公開情報に基づく日本語のResearchを新設。 |
| [en/research.qmd](en/research.qmd) | 所属・専門・方法への関心が分かる英語のResearchを新設。 |
| [seminars.qmd](seminars.qmd) | 講義と演習・研修、ご依頼案内からなるSeminarsを新設。 |
| [publications.qmd](publications.qmd) | 日本語の業績ページを共通デザインに統一し、ページ内リンクを追加。 |
| [en/publications.qmd](en/publications.qmd) | 英語の業績ページを共通デザインに統一し、ページ内リンクを追加。 |
| [cv.qmd](cv.qmd) | 日本語CVの見出しを統一し、広いページ幅の個別指定を解除。 |
| [en/cv.qmd](en/cv.qmd) | 英語CVの見出しを統一し、広いページ幅の個別指定を解除。 |
| [contact.qmd](contact.qmd) | 日本語の問い合わせ案内を整理。フォームの常設埋め込みをリンクへ変更。 |
| [en/contact.qmd](en/contact.qmd) | 英語の問い合わせ案内を整理。未掲載のGmailへの案内を除去。 |
| [en/_metadata.yml](en/_metadata.yml) | 英語ページのHTML言語をenに指定。 |
| [data/profile.yaml](data/profile.yaml) | メール・フォームURL・写真を共通情報に集約し、英語の自己紹介を簡潔に修正。 |
| [data/selected_publications.yaml](data/selected_publications.yaml) | Researchの代表論文2件を選択。『疫学のデザイン入門』と、書籍2冊の書影・取得元を追加。 |
| [data/seminars.yaml](data/seminars.yaml) | 講義テーマと、対象者・レベル・時間・学べることの編集用データを新設。未確定値はnullで管理。 |
| [scripts/render_site_data.rb](scripts/render_site_data.rb) | 共有データからプロフィール・業績・問い合わせ・セミナー・言語別ナビゲーションを生成。論文の重複IDも防止。 |
| [scripts/site-navigation.js](scripts/site-navigation.js) | 小画面でのメニュー開閉とEscapeによる閉鎖・フォーカス復帰を実装。 |
| [scripts/check_site.py](scripts/check_site.py) | 生成ページの言語・ナビゲーション・内部リンク・参照先・見出し・ID・.nojekyllを確認する検査を追加。 |
| [filters/site-layout.lua](filters/site-layout.lua) | Quartoの描画時に言語・ページに対応したヘッダーとフッターを組み込み。 |
| [templates/title-block.html](templates/title-block.html) | 通常ページのタイトルを統一。トップページの氏名の重複と重複IDを防止。 |
| [_includes/home-ja.md](_includes/home-ja.md) | 共有プロフィールから日本語トップページを再生成。 |
| [_includes/home-en.md](_includes/home-en.md) | 共有プロフィールから英語トップページを再生成。 |
| [_includes/publications-ja.md](_includes/publications-ja.md) | 日本語業績の表示を罫線中心に変更し、安定したページ内IDとテキストリンクを生成。 |
| [_includes/publications-en.md](_includes/publications-en.md) | 英語業績の表示を罫線中心に変更し、安定したページ内IDとテキストリンクを生成。 |
| [_includes/contact-ja.md](_includes/contact-ja.md) | 共有の連絡先・支援内容から日本語の問い合わせ内容を生成。 |
| [_includes/contact-en.md](_includes/contact-en.md) | 共有の連絡先・支援内容から英語の問い合わせ内容を生成。 |
| [_includes/research-profile-en.md](_includes/research-profile-en.md) | 既存プロフィールから英語Researchの氏名・役職・所属を生成。 |
| [_includes/research-selected-ja.md](_includes/research-selected-ja.md) | 共有業績データから日本語Researchの代表論文を生成。 |
| [_includes/research-selected-en.md](_includes/research-selected-en.md) | 共有業績データから英語Researchの代表論文を生成。 |
| [_includes/seminars-ja.md](_includes/seminars-ja.md) | 講義・研修データから日本語Seminarsの項目を生成。 |
| [data/authors/me.yaml](data/authors/me.yaml) | Xと同じリンク欄にnoteを追加。 |
| [data/pubmed.json](data/pubmed.json) | PubMedの書誌情報を再取得。検索結果178件、最新12件のデータを保存し、ページの最新5件を更新。 |
| [images/books/epidemiology-by-design-ja.jpg](images/books/epidemiology-by-design-ja.jpg) | 『疫学のデザイン入門』の出版社提供の書影を追加。 |
| [images/books/modern-epidemiology-ja.jpg](images/books/modern-epidemiology-ja.jpg) | 『現代疫学 原著第4版』の出版社提供の書影を追加。 |

## 追加調整

- Seminarsの開催案内・資料リンクを非表示にしました。`data/seminars.yaml` の `show_sources` で切り替えられます。
- 『疫学のデザイン入門』を書影とともに日英の書籍欄に追加しました。書誌情報と画像の取得元は `data/selected_publications.yaml` に記録しています。
- 『現代疫学 原著第4版』にも日英の書籍欄で書影を表示します。
- プロフィール写真はCSSで円形に表示します。元の写真ファイルは変更していません。
- 日英のトップページでXの隣にnoteを追加しました。
- READMEにSeminarsの編集・確認・公開の手順を追記しました。

追加調整後も全11ページのrenderと内部リンク検査を実行しました。
変更した5ページについて320・390・1440pxの計15通りを確認し、390・1440pxで計10回のaxe検査を実施しました。
検査対象はGitHub Pagesに公開するHTMLです。Quartoのプレビュー専用UIは含めていません。
