# 佐藤俊太朗 研究者ポートフォリオ Quarto版

Quarto website形式の研究者ホームページです。

## ローカル確認

```bash
quarto render
quarto preview
```

## 主な編集ファイル

- `data/profile.yaml`: 氏名、所属、自己紹介、専門、学歴、職歴、教育歴
- `data/support.yaml`: 研究支援の説明
- `data/selected_publications.yaml`: 手動で選ぶ代表業績
- `data/pubmed.json`: PubMedから取得した最新論文
- `data/research_projects.yaml`: 共同研究・競争的資金等の研究課題
- `contact.qmd`, `en/contact.qmd`: 問い合わせページ
- `styles.scss`: Zephyrテーマに重ねる軽いデザイン調整

データを編集したら、表示用Markdownを再生成します。

```bash
ruby scripts/render_site_data.rb
quarto render
```

## PubMed更新

```bash
scripts/update_pubmed.py --retmax 12
quarto render
```

PubMed更新にはインターネット接続が必要です。代表業績は自動更新せず、`data/selected_publications.yaml` を手で編集します。

## GitHub Pages

`main` ブランチへpushすると、`.github/workflows/publish.yml` がQuartoサイトをrenderし、GitHub Pagesへ公開します。

GitHub側では、リポジトリの `Settings > Pages` で Source を `GitHub Actions` にしてください。

公開先:

```text
https://shuntaros.github.io/
```

## 通常の更新・公開手順

ページを編集したら、ローカルで確認してからcommit/pushします。

```bash
quarto render
git status
git add .
git commit -m "Update website"
git push
```

`git push` 後、GitHub Actionsが自動でQuartoサイトをrenderし、GitHub Pagesへ公開します。通常は1-2分ほどで反映されます。

## データファイルを編集した場合

以下のデータファイルを編集した場合は、`quarto render` の前に表示用Markdownを再生成します。

- `data/profile.yaml`
- `data/support.yaml`
- `data/selected_publications.yaml`
- `data/pubmed.json`
- `data/research_projects.yaml`

```bash
ruby scripts/render_site_data.rb
quarto render
git status
git add .
git commit -m "Update website data"
git push
```

## PubMedを更新して公開する場合

PubMedから最新論文を取得して公開する場合は、次の流れです。

```bash
scripts/update_pubmed.py --retmax 12
quarto render
git status
git add .
git commit -m "Update PubMed publications"
git push
```

PubMed更新にはインターネット接続が必要です。代表業績は自動更新されないため、必要に応じて `data/selected_publications.yaml` を手で編集してください。

## 研究課題を更新・追記する場合

JST GRANTSから「佐藤俊太朗」の検索結果を再取得する場合は、次を実行します。

```bash
scripts/update_research_projects.rb
ruby scripts/render_site_data.rb
quarto render
git status
git add .
git commit -m "Update research projects"
git push
```

自分で研究課題を追記する場合は、`data/research_projects.yaml` の `manual_items` に追加します。

```yaml
manual_items:
  - title: "研究課題名"
    url: "https://example.com/"
    project_number: "課題番号"
    funding_agency: "資金配分機関"
    research_category: "研究種目"
    review_section: "審査区分・研究分野"
    institution: "研究機関"
    principal_investigator: "研究代表者"
    period: "2026-04-01 - 2029-03-31"
    status: "交付"
    keywords: "キーワード1 / キーワード2"
```

`scripts/update_research_projects.rb` は `jst_items` を更新しますが、`manual_items` は残すようにしています。

## 反映確認

GitHub Actionsの結果はGitHubの `Actions` タブで確認できます。

公開直後に古い表示が残る場合は、数分待ってから再読み込みしてください。
