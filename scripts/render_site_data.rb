#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "yaml"

ROOT = File.expand_path("..", __dir__)
INCLUDES = File.join(ROOT, "_includes")

def load_yaml(path)
  YAML.load_file(path)
rescue Psych::DisallowedClass
  YAML.unsafe_load_file(path)
end

def write_include(name, lines)
  FileUtils.mkdir_p(INCLUDES)
  path = File.join(INCLUDES, name)
  content = lines.join("\n") + "\n"
  return if File.exist?(path) && File.read(path, encoding: "UTF-8") == content

  File.write(path, content, mode: "w", encoding: "UTF-8")
end

def blank?(value)
  value.nil? || value.to_s.strip.empty?
end

def html_escape(value)
  value.to_s
       .gsub("&", "&amp;")
       .gsub("<", "&lt;")
       .gsub(">", "&gt;")
       .gsub('"', "&quot;")
end

def localized_value(value, lang)
  return nil if blank?(value)
  return value unless value.is_a?(Hash)

  value[lang] || value["ja"] || value["en"] || value.values.find { |candidate| !blank?(candidate) }
end

def text_link(label, url)
  return "" if blank?(url)

  "[#{label}](#{url})"
end

def link_label(link)
  url = link["url"].to_s
  return link["label"] if link["label"]
  return "Google Scholar" if url.include?("scholar.google")
  return "ORCID" if url.include?("orcid.org")
  return "researchmap" if url.include?("researchmap")
  return "X" if url.include?("twitter.com") || url.include?("x.com")

  "Link"
end

def hero(lang, profile, shared, author_links)
  ja = lang == "ja"
  image = (ja ? "" : "../") + shared.fetch("photo")
  lines = [
    '::: {.profile-hero}',
    '::: {.profile-copy}',
    '<div class="eyebrow">Biostatistics &amp; Epidemiology</div>',
    "<h1 class=\"profile-name\">#{html_escape(profile["name"])}</h1>",
    "<div class=\"profile-ruby\">#{html_escape(profile["ruby"])}</div>",
    "<div class=\"profile-lead\">#{html_escape(profile["affiliation"])}<br>#{html_escape(profile["position"])}</div>",
    ':::',
    "<img src=\"#{image}\" alt=\"#{html_escape(profile["name"])}\" class=\"profile-image\" width=\"126\" height=\"126\">",
    ':::', '', '::: {.profile-summary}', profile["summary"], ':::', '',
    "[#{ja ? '研究について' : 'Explore my research'}](research.qmd){.arrow-link}", '',
    '::: {.link-row}'
  ]
  author_links.each { |link| lines << text_link(link_label(link), link["url"]) }
  lines.concat [':::', '', '::: {.home-index}']
  entries = if ja
    [
      ["Publications", "publications.qmd", "原著論文、書籍、共同研究・競争的資金等の研究課題。"],
      ["Seminars", "seminars.qmd", "医学統計学や臨床研究の講義・研修について。"],
      ["CV", "cv.qmd", "学歴、職歴、大学での教育活動。"]
    ]
  else
    [
      ["Research", "research.qmd", "Causal inference, time-to-event outcomes, and methods for clinical research."],
      ["Publications", "publications.qmd", "Selected articles, books, and research grants."],
      ["CV", "cv.qmd", "Academic training, appointments, and teaching."]
    ]
  end
  entries.each_with_index do |(title, href, description), i|
    lines.concat ['::: {.index-entry}', "<div class=\"index-number\" aria-hidden=\"true\">0#{i + 1}</div>", '', '::: {.index-copy}', '',
                  "## [#{title}](#{href}){.arrow-link}", '', description, '', ':::', ':::', '']
  end
  lines.concat [':::', '', '::: {.contact-note}',
                ja ? '共同研究・統計相談・セミナーのご相談をお受けしています。' : 'For research collaboration and statistical consultation, please get in touch.', '',
                "[#{ja ? 'お問い合わせ' : 'Get in touch'}](contact.qmd){.arrow-link}", ':::']
  lines
end

def timeline(title, items)
  lines = ["## #{title}", "", "::: {.timeline}"]
  items.each do |item|
    period = item["period"] || item["year"]
    text = item["title"] || [item["degree"], item["institution"]].compact.join(", ")
    lines << "::: {.timeline-item}"
    lines << "<div class=\"timeline-period\">#{period}</div>"
    lines << ""
    lines << "**#{text}**"
    lines << ":::"
  end
  lines << ":::"
  lines
end

def cv(lang, profile)
  labels = {
    "ja" => {
      education: "学歴",
      career: "職歴",
      teaching: "教育",
      degrees: "学位",
      memberships: "所属学会"
    },
    "en" => {
      education: "Education",
      career: "Professional Experience",
      teaching: "Teaching",
      degrees: "Degrees",
      memberships: "Memberships"
    }
  }[lang]

  lines = []
  lines.concat timeline(labels[:education], profile["education"])
  lines << ""
  lines.concat timeline(labels[:career], profile["career"])
  lines << ""
  lines.concat timeline(labels[:teaching], profile["teaching"])
  lines << ""
  lines << "## #{labels[:degrees]}"
  lines << ""
  lines << "::: {.tag-list}"
  profile["degrees"].each { |degree| lines << "- #{degree}" }
  lines << ":::"
  lines << ""
  lines << "## #{labels[:memberships]}"
  lines << ""
  lines << "::: {.tag-list}"
  profile["memberships"].each { |membership| lines << "- #{membership}" }
  lines << ":::"
  lines
end

def publication_actions(item, lang)
  actions = []
  url = item["url"]
  pmid = item["pmid"]
  doi = item["doi"].to_s.sub(/\.+\z/, "")
  if !blank?(pmid)
    actions << text_link("PubMed", url || "https://pubmed.ncbi.nlm.nih.gov/#{pmid}/")
  elsif !blank?(url)
    label = localized_value(item["url_label"], lang) || (lang == "ja" ? "リンク" : "Link")
    actions << text_link(label, url)
  end
  actions << text_link("DOI", "https://doi.org/#{doi}") unless blank?(doi)
  actions
end

def publication_card(item, lang, prefix = "pub")
  lines = []
  anchor = blank?(item["pmid"]) ? "" : "##{prefix}-#{item["pmid"]} "
  cover = item["cover"]
  lines << "::: {#{anchor}.pub-item#{blank?(cover) ? '' : ' .book-item'}}"
  unless blank?(cover)
    cover_path = (lang == "ja" ? "" : "../") + cover
    alt = lang == "ja" ? "『#{item['title']}』の書影" : "Cover: #{item['title']}"
    lines << "<img src=\"#{html_escape(cover_path)}\" alt=\"#{html_escape(alt)}\" class=\"book-cover\" loading=\"lazy\">"
    lines.concat ["", "::: {.book-copy}", ""]
  end
  lines << "<div class=\"item-title\">#{html_escape(item["title"])}</div>"
  lines << ""
  lines << item["authors"].to_s
  lines << ""
  lines << "<div class=\"pub-meta\">#{item["citation"]}</div>" unless blank?(item["citation"])
  actions = publication_actions(item, lang)
  unless actions.empty?
    lines << ""
    lines << "::: {.pub-actions}"
    actions.each { |action| lines << action }
    lines << ":::"
  end
  lines << ":::" unless blank?(cover)
  lines << ":::"
  lines
end

def section_by_key(selected, key)
  selected.fetch("sections", []).find { |section| section["key"] == key }
end

def append_publication_section(lines, section, lang, level = 3)
  return unless section

  lines << "#{"#" * level} #{section["title"][lang]} {##{section["key"].tr("_", "-")}}"
  lines << ""
  lines << "::: {.pub-list}"
  section["items"].each { |item| lines.concat publication_card(item, lang) }
  lines << ":::"
  lines << ""
end

def project_card(item, lang)
  lines = []
  title = localized_value(item["title"], lang)
  labels = {
    "ja" => {
      funding_agency: "配分機関",
      period: "研究期間",
      role: "役割"
    },
    "en" => {
      funding_agency: "Funding agency",
      period: "Period",
      role: "Role"
    }
  }[lang]

  facts = [
    [labels[:funding_agency], localized_value(item["funding_agency"], lang)],
    [labels[:period], item["period"]],
    [labels[:role], localized_value(item["role"], lang)]
  ].reject { |_label, value| blank?(value) }

  lines << "::: {.project-item}"
  lines << "<div class=\"item-title\">#{html_escape(title)}</div>"
  if facts.any?
    lines << ""
    lines << "::: {.project-facts}"
    facts.each do |label, value|
      lines << "<div class=\"project-fact\"><span>#{html_escape(label)}</span><strong>#{html_escape(value)}</strong></div>"
    end
    lines << ":::"
  end
  lines << ":::"
  lines
end

def research_projects(lang, projects)
  labels = {
    "ja" => {
      heading: "共同研究・競争的資金等の研究課題",
      source: "出典",
      source_label: "GRANTS 研究課題統合検索"
    },
    "en" => {
      heading: "Research Projects and Grants",
      source: "Source",
      source_label: "GRANTS"
    }
  }[lang]

  curated_items = projects.fetch("items", [])
  items = curated_items.empty? ? projects.fetch("manual_items", []) + projects.fetch("jst_items", []) : curated_items
  lines = []
  lines << "## #{labels[:heading]} {#research-grants}"
  lines << ""
  if projects["source"]
    source = projects["source"]
    updated_at = source["updated_at"]
    if blank?(source["url"]) && !blank?(updated_at)
      source_html = html_escape(lang == "ja" ? "#{updated_at}に更新" : "Updated #{updated_at}")
    else
      source_name = localized_value(source["name"], lang) || labels[:source_label]
      source_html = "#{labels[:source]}: "
      source_html += if source["url"]
                       "<a href=\"#{source["url"]}\" target=\"_blank\" rel=\"noopener\">#{html_escape(source_name)}</a>"
                     else
                       html_escape(source_name)
                     end
      source_date = source["fetched_at"] || source["captured_at"] || updated_at
      source_html += " / #{html_escape(source_date)}" unless blank?(source_date)
    end
    lines << "<div class=\"data-note\">#{source_html}</div>"
    lines << ""
  end
  lines << "::: {.project-list}"
  items.each { |item| lines.concat project_card(item, lang) }
  lines << ":::"
  lines
end

def publications(lang, selected, pubmed, projects)
  labels = {
    "ja" => {
      articles: "論文",
      recent: "PubMedから取得した最新論文",
      note: "PubMedデータ更新日",
      pubmed: "PubMed検索を開く",
      researchmap: "researchmapを開く"
    },
    "en" => {
      articles: "Articles",
      recent: "Recent Publications from PubMed",
      note: "PubMed data updated",
      pubmed: "Open PubMed Search",
      researchmap: "Open researchmap"
    }
  }[lang]

  lines = []
  lines << "## #{labels[:articles]} {#selected-publications}"
  lines << ""
  append_publication_section(lines, section_by_key(selected, "first_author"), lang)
  append_publication_section(lines, section_by_key(selected, "co_first_author"), lang)
  lines << "### #{labels[:recent]} {#recent-publications}"
  lines << ""
  lines << "<div class=\"data-note\">#{labels[:note]}: #{pubmed["updated_at"]} / #{pubmed["count"]} records found</div>"
  lines << ""
  lines << "::: {.pub-list}"
  pubmed["items"].first(5).each { |item| lines.concat publication_card(item, lang, "recent-pub") }
  lines << ":::"
  lines << ""
  lines << "::: {.link-row}"
  lines << text_link(labels[:pubmed], "https://pubmed.ncbi.nlm.nih.gov/?term=%22Sato%2C%20Shuntaro%22%5BFull%20Author%20Name%5D")
  lines << text_link(labels[:researchmap], "https://researchmap.jp/shuntarosato")
  lines << ":::"
  lines << ""
  append_publication_section(lines, section_by_key(selected, "books"), lang, 2)
  lines.concat research_projects(lang, projects)
  lines
end

# Navigation is declared once; language counterparts are resolved at build time.
NAVIGATION = {
  "ja" => %w[research publications seminars cv contact],
  "en" => %w[research publications cv contact]
}.freeze
PAGE_LABELS = {"research" => "Research", "publications" => "Publications", "seminars" => "Seminars", "cv" => "CV", "contact" => "Contact"}.freeze

def site_layout(lang, page, profile, author_links)
  ja = lang == "ja"
  other = ja ? "en" : "ja"
  counterpart = (NAVIGATION[other] + ["index"]).include?(page) ? page : "research"
  language_href = (ja ? "en/" : "../") + "#{counterpart}.html"
  nav = NAVIGATION[lang].map do |key|
    current = key == page ? ' aria-current="page"' : ''
    "<li><a href=\"#{key}.html\"#{current}>#{PAGE_LABELS.fetch(key)}</a></li>"
  end.join("\n")
  nav += "<li><a class=\"language-link\" href=\"#{language_href}\" lang=\"#{other}\" hreflang=\"#{other}\">#{ja ? 'English' : '日本語'}</a></li>"
  footer_links = author_links.reject { |link| %w[X note].include?(link_label(link)) }.map do |link|
    "<a href=\"#{html_escape(link["url"])}\">#{html_escape(link_label(link))}</a>"
  end.join("\n")
  {
    "header" => <<~HTML,
      <a class="skip-link" href="#page-start">#{ja ? '本文へ移動' : 'Skip to content'}</a>
      <header class="site-header">
        <nav class="site-nav" aria-label="#{ja ? 'メインナビゲーション' : 'Main navigation'}">
          <a class="site-brand" href="index.html"><span class="brand-name">#{html_escape(profile["name"])}</span><span class="brand-note">#{ja ? 'Shuntaro Sato' : 'Biostatistics &amp; Epidemiology'}</span></a>
          <button class="nav-toggle" type="button" aria-expanded="false" aria-controls="site-navigation">#{ja ? 'メニュー' : 'Menu'}</button>
          <ul id="site-navigation" class="nav-links">#{nav}</ul>
        </nav>
      </header>
      <div id="page-start" tabindex="-1"></div>
    HTML
    "footer" => <<~HTML
      <footer class="site-footer"><div class="footer-inner">
        <span>© 2026 #{html_escape(profile["name"])}</span>
        <nav class="footer-links" aria-label="#{ja ? '研究者プロフィール' : 'Research profiles'}">#{footer_links}</nav>
      </div></footer>
    HTML
  }
end

def research_profile(profile)
  ['::: {.research-identity}',
   "**#{profile["name"]}**<br>#{profile["position"]} · #{profile["affiliation"]}", ':::']
end

def research_selected(lang, selected)
  lines = ['::: {.pub-list}']
  selected.fetch("sections").each do |section|
    section.fetch("items").select { |item| item["research_selected"] }.each do |item|
      lines.concat publication_card(item, lang)
    end
  end
  lines << ':::'
  lines
end

def seminars(data)
  lines = []
  data.fetch("sections").each do |section|
    lines.concat ["## #{section.fetch('title')} {##{section.fetch('id')}}", '', section.fetch("description"), '']
    section.fetch("items").each do |item|
      lines.concat ['::: {.seminar-entry}', "### #{item.fetch('title')}", '', item.fetch("description"), '', '<dl class="seminar-facts">']
      {"audience" => "対象者", "level" => "レベル", "duration" => "想定時間", "outcomes" => "参加者が学べること"}.each do |key, label|
        value = item[key]
        value = key == "outcomes" ? "内容はご相談のうえ決定します。" : "ご相談ください" if blank?(value)
        lines << "<div><dt>#{label}</dt><dd>#{html_escape(value)}</dd></div>"
      end
      lines << '</dl>'
      if data["show_sources"] && item["source"]
        lines.concat ['', "<p class=\"seminar-source\"><a href=\"#{html_escape(item['source']['url'])}\">#{html_escape(item['source']['label'])}</a></p>"]
      end
      lines.concat [':::', '']
    end
  end
  lines
end

def contact(lang, shared, support)
  ja = lang == "ja"
  lines = ["## #{ja ? 'メール' : 'Email'}", '',
           "[#{shared.fetch('email')}](mailto:#{shared.fetch('email')})", '',
           "## #{ja ? 'お問い合わせフォーム' : 'Contact form'}", '',
           ja ? 'フォームからもご連絡いただけます。' : 'You can also reach me through the contact form.', '',
           "[#{ja ? 'フォームを開く' : 'Open contact form'}](#{shared.fetch('contact_form')}){.action-link}", '',
           "## #{ja ? '研究支援・教育' : 'Research support and teaching'}", '']
  support.fetch("summary").each do |item|
    lines.concat ["### #{item.fetch('title')}", '', item.fetch("body"), '']
  end
  lines
end

profile = load_yaml(File.join(ROOT, "data", "profile.yaml"))
support = load_yaml(File.join(ROOT, "data", "support.yaml"))
selected = load_yaml(File.join(ROOT, "data", "selected_publications.yaml"))
projects = load_yaml(File.join(ROOT, "data", "research_projects.yaml"))
author = load_yaml(File.join(ROOT, "data", "authors", "me.yaml"))
seminar_data = load_yaml(File.join(ROOT, "data", "seminars.yaml"))
pubmed = JSON.parse(File.read(File.join(ROOT, "data", "pubmed.json"), encoding: "UTF-8"))
author_links = author.fetch("links", [])
layouts = {}
%w[ja en].each do |lang|
  write_include("home-#{lang}.md", hero(lang, profile[lang], profile.fetch("shared"), author_links))
  write_include("cv-#{lang}.md", cv(lang, profile[lang]))
  write_include("publications-#{lang}.md", publications(lang, selected, pubmed, projects))
  write_include("research-profile-#{lang}.md", research_profile(profile[lang])) if lang == "en"
  write_include("research-selected-#{lang}.md", research_selected(lang, selected))
  write_include("contact-#{lang}.md", contact(lang, profile.fetch("shared"), support[lang]))
  (NAVIGATION[lang] + ["index"]).each do |page|
    input = (lang == "ja" ? "" : "en/") + "#{page}.qmd"
    layouts[input] = site_layout(lang, page, profile[lang], author_links)
  end
end
write_include("seminars-ja.md", seminars(seminar_data))
write_include("site-layouts.json", [JSON.pretty_generate(layouts)])
puts "Rendered Quarto include files in #{INCLUDES}"
