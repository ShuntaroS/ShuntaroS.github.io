-- Build language-specific navigation into HTML, including when JavaScript is off.
-- Ruby prepares the shared layout data before Quarto reads the pages.
function Meta(meta)
  if not quarto.doc.is_format("html") then return meta end
  local root = quarto.project.directory
  local file = assert(io.open(root .. "/_includes/site-layouts.json", "r"))
  local layouts = quarto.json.decode(file:read("*a"))
  file:close()
  local relative = quarto.doc.input_file:sub(#root + 2)
  local layout = assert(layouts[relative], "Missing site layout for " .. relative)
  quarto.doc.include_text("before-body", layout.header)
  quarto.doc.include_text("after-body", layout.footer)
  quarto.doc.add_html_dependency({
    name = "site-navigation",
    version = "1.0.0",
    scripts = {"../scripts/site-navigation.js"}
  })
  return meta
end
