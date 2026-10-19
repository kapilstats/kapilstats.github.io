-- Builds the publication list on the Publications page.
-- You never need to run this file yourself.
--
-- It formats every entry of publications.bib, splits the list into
-- journal articles (under year headings), book chapters and books,
-- numbers the entries, makes "Kumar, K." bold, and shows DOIs as a
-- short "DOI" link.

-- true  = newest paper first, numbered downwards (40, 39, ..., 1)
-- false = oldest paper first, numbered upwards (1, 2, ..., 40)
local newest_first = true

local groups = {
  { title = "Journal articles", by_year = true,
    types = { ["article-journal"] = true, ["article"] = true } },
  { title = "Book chapters and conference papers", by_year = false,
    types = { ["chapter"] = true, ["paper-conference"] = true } },
  { title = "Books and edited proceedings", by_year = false,
    types = { ["book"] = true } },
}

-- "Kumar," + space + "K." becomes bold
local function bold_own_name(inlines)
  local out = pandoc.Inlines {}
  local i = 1
  while i <= #inlines do
    local a, b, c = inlines[i], inlines[i + 1], inlines[i + 2]
    if a.t == "Str" and a.text == "Kumar," and b and b.t == "Space"
        and c and c.t == "Str" and c.text:match("^K%.") then
      out:insert(pandoc.Strong { pandoc.Str("Kumar,"), pandoc.Space(), pandoc.Str("K.") })
      local rest = c.text:sub(3)
      if rest ~= "" then out:insert(pandoc.Str(rest)) end
      i = i + 3
    else
      out:insert(a)
      i = i + 1
    end
  end
  return out
end

local function tidy_entry(entry, number)
  entry = entry:walk {
    Inlines = bold_own_name,
    Link = function(link)
      if link.target:match("^https://doi%.org/") then
        link.content = { pandoc.Str("DOI") }
        return link
      end
    end,
  }
  -- put the number in front of the entry
  local first = entry.content[1]
  if first and (first.t == "Plain" or first.t == "Para") then
    first.content:insert(1, pandoc.Span({ pandoc.Str(number .. ".") }, pandoc.Attr("", { "pubnum" })))
  end
  return entry
end

local function year_of(entry)
  return pandoc.utils.stringify(entry):match("%((%d%d%d%d)%)") or "In press"
end

function Pandoc(doc)
  -- remember the type (article, chapter, book) of every entry
  local type_of = {}
  for _, ref in ipairs(pandoc.utils.references(doc)) do
    type_of[ref.id] = ref.type
  end

  doc = pandoc.utils.citeproc(doc)

  return doc:walk {
    Div = function(div)
      if div.identifier ~= "refs" then return nil end
      local entries = {}
      div:walk { Div = function(d)
        if d.classes:includes("csl-entry") then table.insert(entries, d) end
      end }

      local blocks = pandoc.Blocks {}
      for _, g in ipairs(groups) do
        local members = {}
        for _, e in ipairs(entries) do
          local key = e.identifier:gsub("^ref%-", "")
          if g.types[type_of[key]] then table.insert(members, e) end
        end
        if not newest_first then
          local reversed = {}
          for i = #members, 1, -1 do table.insert(reversed, members[i]) end
          members = reversed
        end

        if #members > 0 then
          blocks:insert(pandoc.Header(2, g.title .. " (" .. #members .. ")"))

          -- links to each year, e.g. 2026 · 2025 · ...
          if g.by_year then
            local years, seen = {}, {}
            for _, e in ipairs(members) do
              local y = year_of(e)
              if not seen[y] then seen[y] = true; table.insert(years, y) end
            end
            local bar = pandoc.Inlines {}
            for i, y in ipairs(years) do
              if i > 1 then bar:insert(pandoc.Str(" · ")) end
              bar:insert(pandoc.Link(y, "#year-" .. y))
            end
            blocks:insert(pandoc.Div({ pandoc.Para(bar) }, pandoc.Attr("", { "year-bar" })))
          end

          local current_year = nil
          local body = pandoc.Blocks {}
          for i, e in ipairs(members) do
            local number = newest_first and (#members - i + 1) or i
            if g.by_year then
              local y = year_of(e)
              if y ~= current_year then
                current_year = y
                body:insert(pandoc.Header(3, y, pandoc.Attr("year-" .. y, { "pub-year" })))
              end
            end
            body:insert(tidy_entry(e, number))
          end
          blocks:insert(pandoc.Div(body, pandoc.Attr("", { "csl-bib-body" })))
        end
      end
      return pandoc.Div(blocks, pandoc.Attr("refs"))
    end,
  }
end
