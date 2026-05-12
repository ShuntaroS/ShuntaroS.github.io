# 佐藤俊太朗 研究者ポートフォリオ Quarto版

Hugo Bloxで作成した素材をもとにした、Quarto website形式の研究者ホームページです。

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
