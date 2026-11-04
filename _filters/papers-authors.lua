-- Filter for the papers page. It runs citeproc itself, so it can act on both
-- sides of it:
--   * before: keeps a trailing "*" on a given name (equal contribution) after
--     APA abbreviates it to initials, e.g. "McCaw, Zachary*" -> "McCaw, Z.*".
--     Such authors become CSL "literal" names, so the "Family, I." format below
--     must match the citation style (APA here).
--   * before: shortens author lists longer than MAX_AUTHORS to everyone up to
--     me (and any "*" co-first authors), "…", then the last (corresponding)
--     author.
--   * after: bolds my name ("Wang, J." / "Wang, J.*") in each entry; citeproc
--     would drop any formatting put inside the name itself.

local ME_FAMILY, ME_INITIALS = "Wang,", "J%."
local ME = { family = "Wang", given = "Jeremy" }
local MAX_AUTHORS = 6

local stringify = pandoc.utils.stringify

local function initials(given)
  local out = {}
  for word in given:gmatch("[^%s]+") do
    local parts = {}
    for piece in word:gmatch("[^%-]+") do
      parts[#parts + 1] = pandoc.text.sub(piece, 1, 1) .. "."
    end
    out[#out + 1] = table.concat(parts, "-")
  end
  return table.concat(out, " ")
end

local function mark(name)
  if not name.family or not name.given then return name end
  local family, given = stringify(name.family), stringify(name.given)
  local star = given:match("%*$") and "*" or ""
  given = given:gsub("%*$", "")
  if star == "" then return name end
  return { literal = family .. ", " .. initials(given) .. star }
end

local function shorten(authors)
  if #authors <= MAX_AUTHORS then return authors end
  local keep = 1
  for i, name in ipairs(authors) do
    local family = name.family and stringify(name.family) or ""
    local given = name.given and stringify(name.given) or ""
    if given:match("%*$")
        or (family == ME.family and given:gsub("%*$", "") == ME.given) then
      keep = i
    end
  end
  if keep >= #authors - 2 then return authors end  -- nothing worth eliding

  local out = {}
  for i = 1, keep do out[i] = authors[i] end
  out[#out + 1] = { literal = "…" }
  out[#out + 1] = authors[#authors]
  return out
end

-- In-text citations print literal names in full ("Wang, J.* et al."); cut
-- them back to the family name ("Wang et al.").
local function family_only(inlines)
  local out, i = pandoc.Inlines {}, 1
  while i <= #inlines do
    local a, sp, b = inlines[i], inlines[i + 1], inlines[i + 2]
    if a.t == "Str" and a.text:match(",$") and sp and sp.t == "Space"
        and b and b.t == "Str" and b.text:match("^[%u%.%-]+%*$") then
      out:insert(pandoc.Str(a.text:sub(1, -2)))
      i = i + 3
    else
      out:insert(a)
      i = i + 1
    end
  end
  return out
end

-- APA writes a shortened list as "…, Last, A." with no "&" before the last
-- author.
local function drop_amp_after_ellipsis(inlines)
  for i = #inlines - 3, 1, -1 do
    local e, s1, amp, s2 = inlines[i], inlines[i + 1], inlines[i + 2], inlines[i + 3]
    if e.t == "Str" and e.text == "…," and s1.t == "Space"
        and amp.t == "Str" and amp.text == "&" and s2.t == "Space" then
      inlines:remove(i + 3)
      inlines:remove(i + 2)
    end
  end
  return inlines
end

local function bold_me(inlines)
  local out, i = pandoc.Inlines {}, 1
  while i <= #inlines do
    local a, sp, b = inlines[i], inlines[i + 1], inlines[i + 2]
    local name, rest
    if a.t == "Str" and a.text == ME_FAMILY and sp and sp.t == "Space"
        and b and b.t == "Str" then
      name, rest = b.text:match("^(" .. ME_INITIALS .. "%*?)(.*)$")
    end
    if name then
      out:insert(pandoc.Strong { a, sp, pandoc.Str(name) })
      if rest ~= "" then out:insert(pandoc.Str(rest)) end
      i = i + 3
    else
      out:insert(a)
      i = i + 1
    end
  end
  return out
end

function Pandoc(doc)
  local refs = pandoc.utils.references(doc)
  for _, ref in ipairs(refs) do
    if ref.author then
      ref.author = shorten(ref.author)
      for i, name in ipairs(ref.author) do ref.author[i] = mark(name) end
    end
  end
  doc.meta.references = refs
  doc.meta.bibliography = nil

  doc = pandoc.utils.citeproc(doc)
  -- Leave nothing for Quarto's own citeproc pass, which would otherwise
  -- re-resolve the (now reference-less) citations as "(key?)".
  doc.meta.references = nil

  return doc:walk {
    Cite = function(cite)
      local keys = {}
      for _, c in ipairs(cite.citations) do keys[#keys + 1] = c.id end
      return pandoc.Span(cite.content:walk { Inlines = family_only },
        { class = "citation", ["data-cites"] = table.concat(keys, " ") })
    end,
    Div = function(div)
      if div.classes:includes("csl-entry") then
        return div:walk { Inlines = drop_amp_after_ellipsis }
                  :walk { Inlines = bold_me }
      end
    end,
  }
end
