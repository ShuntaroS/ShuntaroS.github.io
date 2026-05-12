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
  File.write(File.join(INCLUDES, name), lines.join("\n") + "\n", mode: "w", encoding: "UTF-8")
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

def button(label, url, style = "outline-primary")
  return "" if blank?(url)

  "[#{label}](#{url}){.btn .btn-sm .btn-#{style} target=\"_blank\"}"
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

def hero(lang, profile, support, author_links)
  image = lang == "ja" ? "images/shuntaro-sato.jpg" : "../images/shuntaro-sato.jpg"
  contact = lang == "ja" ? "contact.qmd" : "contact.qmd"
  publications = lang == "ja" ? "publications.qmd" : "publications.qmd"
  labels = {
    "ja" => {
      kicker: "Biostatistics and Epidemiology",
      contact: "問い合わせ",
      publications: "業績を見る",
      summary: "研究支援",
      fields: "専門領域"
    },
    "en" => {
      kicker: "Biostatistics and Epidemiology",
      contact: "Contact",
      publications: "Publications",
      summary: "Research Support",
      fields: "Fields"
    }
  }[lang]

  lines = []
  lines << "::: {.profile-hero}"
  lines << "::: {.profile-photo}"
  lines << "<img src=\"#{image}\" alt=\"#{profile["name"]}\" class=\"profile-image\">"
  lines << ":::"
  lines << "::: {.profile-copy}"
  lines << "<div class=\"profile-kicker\">#{labels[:kicker]}</div>"
  lines << "<h1 class=\"profile-name\">#{profile["name"]}</h1>"
  lines << "<div class=\"profile-ruby\">#{profile["ruby"]}</div>" unless blank?(profile["ruby"])
  lines << "<div class=\"profile-lead\">#{profile["position"]} / #{profile["affiliation"]}</div>"
  lines << ""
  lines << profile["summary"]
  lines << ""
  lines << "::: {.link-row}"
  lines << "[#{labels[:contact]}](#{contact}){.btn .btn-primary}"
  lines << "[#{labels[:publications]}](#{publications}){.btn .btn-outline-primary}"
  author_links.each do |link|
    lines << button(link_label(link), link["url"], "outline-secondary")
  end
  lines << ":::"
  lines << ":::"
  lines << ":::"
  lines << ""
  lines << "::: {.summary-band}"
  lines << "## #{labels[:summary]}"
  lines << ""
  lines << "::: {.summary-grid}"
  support["summary"].each do |item|
    lines << "::: {.info-card}"
    lines << "### #{item["title"]}"
    lines << ""
    lines << item["body"]
    lines << ":::"
  end
  lines << ":::"
  lines << ":::"
  lines << ""
  lines << "## #{labels[:fields]}"
  lines << ""
  lines << "::: {.field-grid}"
  profile["fields"].each do |field|
    lines << "::: {.info-card}"
    lines << "### #{field["title"]}"
    lines << ""
    lines << field["body"]
    lines << ":::"
  end
  lines << ":::"
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
    actions << button("PubMed", url || "https://pubmed.ncbi.nlm.nih.gov/#{pmid}/")
  elsif !blank?(url)
    actions << button(lang == "ja" ? "リンク" : "Link", url)
  end
  actions << button("DOI", "https://doi.org/#{doi}") unless blank?(doi)
  actions
end

def publication_card(item, lang)
  lines = []
  lines << "::: {.pub-item}"
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
  lines << ":::"
  lines
end

def section_by_key(selected, key)
  selected.fetch("sections", []).find { |section| section["key"] == key }
end

def append_publication_section(lines, section, lang, level = 3)
  return unless section

  lines << "#{"#" * level} #{section["title"][lang]}"
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
  lines << "## #{labels[:heading]}"
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
  lines << "## #{labels[:articles]}"
  lines << ""
  append_publication_section(lines, section_by_key(selected, "first_author"), lang)
  append_publication_section(lines, section_by_key(selected, "co_first_author"), lang)
  lines << "### #{labels[:recent]}"
  lines << ""
  lines << "<div class=\"data-note\">#{labels[:note]}: #{pubmed["updated_at"]} / #{pubmed["count"]} records found</div>"
  lines << ""
  lines << "::: {.pub-list}"
  pubmed["items"].first(5).each { |item| lines.concat publication_card(item, lang) }
  lines << ":::"
  lines << ""
  lines << "::: {.link-row}"
  lines << button(labels[:pubmed], "https://pubmed.ncbi.nlm.nih.gov/?term=%22Sato%2C%20Shuntaro%22%5BFull%20Author%20Name%5D", "primary")
  lines << button(labels[:researchmap], "https://researchmap.jp/shuntarosato", "outline-secondary")
  lines << ":::"
  lines << ""
  append_publication_section(lines, section_by_key(selected, "books"), lang, 2)
  lines.concat research_projects(lang, projects)
  lines
end

profile = load_yaml(File.join(ROOT, "data", "profile.yaml"))
support = load_yaml(File.join(ROOT, "data", "support.yaml"))
selected = load_yaml(File.join(ROOT, "data", "selected_publications.yaml"))
projects = load_yaml(File.join(ROOT, "data", "research_projects.yaml"))
author = load_yaml(File.join(ROOT, "data", "authors", "me.yaml"))
pubmed = JSON.parse(File.read(File.join(ROOT, "data", "pubmed.json"), encoding: "UTF-8"))
author_links = author.fetch("links", [])

write_include("home-ja.md", hero("ja", profile["ja"], support["ja"], author_links))
write_include("home-en.md", hero("en", profile["en"], support["en"], author_links))
write_include("cv-ja.md", cv("ja", profile["ja"]))
write_include("cv-en.md", cv("en", profile["en"]))
write_include("publications-ja.md", publications("ja", selected, pubmed, projects))
write_include("publications-en.md", publications("en", selected, pubmed, projects))

puts "Rendered Quarto include files in #{INCLUDES}"
