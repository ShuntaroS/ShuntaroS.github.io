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
  doi = item["doi"]
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
  lines << "### #{item["title"]}"
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

def publications(lang, selected, pubmed)
  labels = {
    "ja" => {
      selected: "代表業績",
      recent: "PubMedから取得した最新論文",
      all: "全件一覧",
      note: "PubMedデータ更新日",
      pubmed: "PubMed検索を開く",
      researchmap: "researchmapを開く"
    },
    "en" => {
      selected: "Selected Publications",
      recent: "Recent Publications from PubMed",
      all: "Full Publication List",
      note: "PubMed data updated",
      pubmed: "Open PubMed Search",
      researchmap: "Open researchmap"
    }
  }[lang]

  lines = []
  lines << "## #{labels[:selected]}"
  lines << ""
  selected["sections"].each do |section|
    lines << "### #{section["title"][lang]}"
    lines << ""
    lines << "::: {.pub-list}"
    section["items"].each { |item| lines.concat publication_card(item, lang) }
    lines << ":::"
    lines << ""
  end

  lines << "## #{labels[:recent]}"
  lines << ""
  lines << "<div class=\"data-note\">#{labels[:note]}: #{pubmed["updated_at"]} / #{pubmed["count"]} records found</div>"
  lines << ""
  lines << "::: {.pub-list}"
  pubmed["items"].first(5).each { |item| lines.concat publication_card(item, lang) }
  lines << ":::"
  lines << ""
  lines << "## #{labels[:all]}"
  lines << ""
  lines << "::: {.link-row}"
  lines << button(labels[:pubmed], "https://pubmed.ncbi.nlm.nih.gov/?term=%22Sato%2C%20Shuntaro%22%5BFull%20Author%20Name%5D", "primary")
  lines << button(labels[:researchmap], "https://researchmap.jp/shuntarosato", "outline-secondary")
  lines << ":::"
  lines
end

profile = load_yaml(File.join(ROOT, "data", "profile.yaml"))
support = load_yaml(File.join(ROOT, "data", "support.yaml"))
selected = load_yaml(File.join(ROOT, "data", "selected_publications.yaml"))
author = load_yaml(File.join(ROOT, "data", "authors", "me.yaml"))
pubmed = JSON.parse(File.read(File.join(ROOT, "data", "pubmed.json"), encoding: "UTF-8"))
author_links = author.fetch("links", [])

write_include("home-ja.md", hero("ja", profile["ja"], support["ja"], author_links))
write_include("home-en.md", hero("en", profile["en"], support["en"], author_links))
write_include("cv-ja.md", cv("ja", profile["ja"]))
write_include("cv-en.md", cv("en", profile["en"]))
write_include("publications-ja.md", publications("ja", selected, pubmed))
write_include("publications-en.md", publications("en", selected, pubmed))

puts "Rendered Quarto include files in #{INCLUDES}"
