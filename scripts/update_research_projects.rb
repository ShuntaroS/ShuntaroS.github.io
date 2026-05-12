#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "net/http"
require "uri"
require "yaml"

ROOT = File.expand_path("..", __dir__)
OUTPUT = File.join(ROOT, "data", "research_projects.yaml")
SOURCE_URL = "https://grants.jst.go.jp/search/?kw=%E4%BD%90%E8%97%A4%E4%BF%8A%E5%A4%AA%E6%9C%97&rw=100"

def decode_html(text)
  text.to_s
      .gsub(/<br\s*\/?>/i, "\n")
      .gsub(/&nbsp;/, " ")
      .gsub(/&ndash;/, "-")
      .gsub(/&raquo;/, "»")
      .gsub(/&rsaquo;/, "›")
      .gsub(/&amp;/, "&")
      .gsub(/&lt;/, "<")
      .gsub(/&gt;/, ">")
      .gsub(/&quot;/, '"')
      .gsub(/&#39;/, "'")
end

def strip_tags(html)
  decode_html(html)
    .gsub(/<script.*?<\/script>/mi, "")
    .gsub(/<style.*?<\/style>/mi, "")
    .gsub(/<[^>]+>/, " ")
    .gsub(/[ \t\r\f]+/, " ")
    .gsub(/\n\s+/, "\n")
    .strip
end

def fetch(url)
  uri = URI(url)
  request = Net::HTTP::Get.new(uri)
  request["User-Agent"] = "shuntaros.github.io research project updater"

  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    response = http.request(request)
    raise "Failed to fetch #{url}: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    response.body.force_encoding("UTF-8")
  end
end

def rows_from_table(html)
  rows = {}
  html.scan(%r{<tr>\s*<th>(.*?)</th>\s*<td>(.*?)</td>\s*</tr>}mi) do |raw_key, raw_value|
    key = strip_tags(raw_key)
    value = strip_tags(raw_value)
    rows[key] = value unless key.empty? || value.empty?
  end
  rows
end

def project_items(html)
  blocks = html.split('<li class="project">').drop(1).map do |part|
    part.split('<li class="project">').first
  end

  blocks.map do |block|
    title_match = block.match(%r{<a class="link-page win_open" href="([^"]+)">(.*?)</a>}mi)
    next unless title_match

    url = title_match[1]
    title = strip_tags(title_match[2])
    rows = rows_from_table(block)
    period_status = rows["研究期間 (年度)"].to_s
    period = period_status.sub(/(交付|終了|採択|不採択)\z/, "").strip
    status = period_status[/交付|終了|採択|不採択/]
    grant_id = url[%r{KAKENHI-PROJECT-([^/]+)/}, 1]

    {
      "title" => title,
      "url" => url,
      "grant_id" => grant_id,
      "project_number" => grant_id ? "JP#{grant_id}" : nil,
      "record_set" => rows["レコードセット"],
      "funding_agency" => rows["ファンディング機関"],
      "research_category" => rows["研究種目"],
      "review_section" => rows["審査区分"] || rows["研究分野"],
      "institution" => rows["研究機関"],
      "principal_investigator" => rows["研究代表者"],
      "period" => period,
      "status" => status,
      "keywords" => rows["キーワード"]
    }.compact
  end.compact
end

def existing_manual_items
  return [] unless File.exist?(OUTPUT)

  data = YAML.load_file(OUTPUT)
  data.fetch("manual_items", [])
rescue Psych::SyntaxError
  []
end

html = fetch(SOURCE_URL)
items = project_items(html)
raise "No research project entries were parsed." if items.empty?

data = {
  "source" => {
    "name" => "GRANTS - 研究課題統合検索",
    "url" => SOURCE_URL.sub("&rw=100", ""),
    "fetched_at" => Date.today.to_s,
    "query" => "佐藤俊太朗"
  },
  "manual_items" => existing_manual_items,
  "jst_items" => items
}

File.write(OUTPUT, data.to_yaml(line_width: -1), mode: "w", encoding: "UTF-8")
puts "Wrote #{items.length} JST research project entries to #{OUTPUT}"
