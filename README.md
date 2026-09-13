# 佐藤俊太朗 研究者Webサイト

Quartoで構築し、GitHub ActionsからGitHub Pagesへ公開しています。
白い紙、明朝系の本文、740pxの読み幅、余白と細い罫線を基本にしています。
リンク文字は濃い青、装飾やホバーの下線は空色です。

## ローカル確認

QuartoとRubyが必要です。追加のRuby gemやNode.jsのインストールは不要です。

```bash
quarto preview
```

`quarto preview` / `quarto render` の開始時に、`pre-render` が
`ruby scripts/render_site_data.rb` を実行します。データから表示用Markdownと
言語別のナビゲーション情報を生成した後、QuartoがHTMLを作成します。
外部サービスへのアクセスはデータ生成に必要ありません。

データを編集した後にプレビューへ反映されない場合は、プレビューを再起動してください。
公開前にはサイト全体を生成し、内部リンクを確認します。

```bash
quarto render
python3 scripts/check_site.py
```

## 普段編集するファイル

| 内容 | 編集するファイル |
| --- | --- |
| 名前、所属、略歴、学歴・職歴・教育歴 | `data/profile.yaml` の `ja` / `en` |
| 両言語で共有するメール・フォームURL・写真 | `data/profile.yaml` の `shared` |
| Google Scholar、ORCID等のプロフィールリンク | `data/authors/me.yaml` の `links` |
| 統計相談・研究支援の説明 | `data/support.yaml` |
| 原著論文・書籍 | `data/selected_publications.yaml` |
| Researchに掲載する代表論文 | 上記の各論文に `research_selected: true` を付ける |
| PubMedから取得した論文 | `data/pubmed.json` |
| 共同研究・競争的資金等の研究課題 | `data/research_projects.yaml` の `items` |
| 日本語のResearch本文 | `research.qmd` |
| 英語のResearch本文 | `en/research.qmd` |
| 講義・研修の項目と条件 | `data/seminars.yaml` |
| Seminarsの導入文・依頼案内 | `seminars.qmd` |
| ページの見出し・導入文 | 各言語の `.qmd` |
| 色・文字・余白・画面幅・操作時の動き | `styles.scss` |

`_includes/*.md` は生成物です。直接編集せず、元のデータを更新してください。
Quartoは描画前にinclude先を検査するため、Markdown生成物は従来どおりGitで管理します。
新しいincludeを追加したときだけ、最初に `ruby scripts/render_site_data.rb` を実行してください。
`_includes/site-layouts.json` は描画中にのみ使う一時生成物で、Git管理・公開対象には含めません。

旧Hugo構成の `data/en/authors/me.yaml` と、`data/authors/me.yaml` の `links` 以外は
現行のページ生成では使用していません。プロフィールの更新先は `data/profile.yaml` です。

### Seminarsの更新手順

1. 作業ブランチで `data/seminars.yaml` を開きます。
2. `id: lectures` の `items` で講義を、`id: workshops` の `items` で演習・研修を編集します。
3. 各項目の `title`（講義名）、`description`（説明）、`audience`（対象者）、
   `level`（レベル）、`duration`（想定時間）、`outcomes`（参加者が学べること）を書き換えます。
4. 項目を増やすときは、同じ `items` 内の1項目をコピーし、同じ深さのインデントで追加します。
   下記は編集用の例です。内容が未定の欄は `null` のままで構いません。

```yaml
      - title: "講義名"
        description: "講義の説明"
        audience: null
        level: null
        duration: null
        outcomes: null
```

`null` は「ご相談ください」等の表示になります。
たとえば時間が確定したら、`duration: null` を `duration: "90分"` のように変更します。
YAMLのインデントにはタブを使わず、既存のスペース数を維持してください。

5. リポジトリのルートで `quarto preview` を実行し、Seminarsを開いて確認します。
   プレビューが起動済みなら、ターミナルで `Ctrl+C` を押して停止し、再起動するとデータの変更が確実に反映されます。
6. 公開前に `quarto render` と `python3 scripts/check_site.py` を実行します。
7. 元データと再生成された `_includes/seminars-ja.md` を作業ブランチにコミットし、
   確認後にmainへ取り込みます。GitHub Actionsが公開します。

ページ冒頭の紹介文や最後の依頼案内は `seminars.qmd` を編集します。
このファイルも変更した場合は、同じコミットに含めてください。
生成物の `_includes/seminars-ja.md` を直接編集する必要はありません。

開催案内・資料リンクは、現在 `show_sources: false` で非表示にしています。
将来表示する場合だけ、この値を `true` に変更します。
リンク先は各項目の `source.label` と `source.url` で管理します。
過去の開催時間や参加者層を、将来の標準条件として自動流用していません。
Workshopsの具体的なプログラムも未確定です。

### 言語別の構成

- 日本語：Research / Publications / Seminars / CV / Contact / English
- 英語：Research / Publications / CV / Contact / 日本語

対応するページ同士をHTMLリンクで切り替えます。Seminarsだけは英語版Researchへ移動します。
トップページのURLは日本語・英語とも従来のままです。
`en/_metadata.yml` で英語のHTML言語を指定しています。

ナビゲーションの項目は `scripts/render_site_data.rb` の `NAVIGATION` と `PAGE_LABELS` にあります。
`filters/site-layout.lua` が対応するヘッダーとフッターをHTMLに組み込みます。
`templates/title-block.html` は本文見出しを整え、トップページの氏名の二重表示を防ぎます。
`site-navigation.js` は小画面のメニュー開閉だけを担当します。
JavaScriptが無効な場合はリンク一覧をそのまま表示します。

## データの取得

PubMedを明示的に更新する場合：

```bash
python3 scripts/update_pubmed.py --retmax 12
quarto render
```

代表業績は自動更新せず、`data/selected_publications.yaml` を編集します。
書籍に書影を付ける場合は、画像を `images/books/` に保存し、その項目の `cover` に
リポジトリのルートからのパスを指定します。`cover_source` は画像の取得元の記録です。
`scripts/update_research_projects.rb` はJST GRANTSの結果を `jst_items` に保存します。
既存の `items` がある場合はその確認済み一覧を掲載します。
この2つの外部取得処理は `pre-render` に含めていません。

## GitHub Pagesへの公開

公開先は [shuntaros.github.io](https://shuntaros.github.io/) です。
`.github/workflows/publish.yml` は従来どおり、`main` へのpushまたは手動実行で動きます。
Ruby 3.3とQuartoを設定し、`quarto render`、`_site` のアップロード、Pagesへのデプロイを行います。
`.nojekyll` を配置する `scripts/post_render.sh` も維持しています。
データ生成はQuartoの描画前処理へ移したため、Actions内の重複した実行だけを取り除きました。

変更は作業ブランチで確認し、レビュー後にmainへ取り込んでください。
ブランチへのpushだけでは公開されません。GitHub側の `Settings > Pages` は
引き続き `GitHub Actions` を使用します。

## Research・Seminarsの記載根拠

既存プロフィール、業績データ、以下の公開情報の範囲で構成しています。
未発表の研究計画や新しい研究アイデアは追加していません。

- [既存の公開プロフィール](https://shuntaros.github.io/)：専門、所属、臨床研究支援、教育領域。
- [Sato et al., 2025（J-STAGE全文）](https://www.jstage.jst.go.jp/article/ace/7/2/7_25007/_html/-char/en)：まれなイベントに対する調整リスク差と統計的性能の検討。
- [Sato et al., 2024（PMC全文）](https://pmc.ncbi.nlm.nih.gov/articles/PMC10812582/)：ワクチン安全性評価におけるコホート研究・自己対照ケースシリーズと検出力。
- [本人の公開講義資料（2020年）](https://speakerdeck.com/shuntaros/observational-studies-causal-inference-what-if-chapter-3)：観察研究と因果推論。
- [臨床疫学研究推進機構の開催案内（2024年・PDF）](https://cdn.kyodonewsprwire.jp/prwfile/release/M106906/202404260076/_prw_PR1fl_cDK0Xn4i.pdf)：生存時間解析の講義内容、研究デザインに関する過去の講義。

Research本文は日英で独立して編集します。論文の書誌情報・掲載対象は共有データで管理します。
生存時間解析の説明は公開された教育活動に基づき、未確認の方法開発実績を示していません。

『疫学のデザイン入門 — 健康科学への因果的アプローチ』の書誌情報・書影は、
[学術図書出版社の商品ページ](https://www.gakujutsu.co.jp/product/978-4-7806-1477-0/)で確認しています。
