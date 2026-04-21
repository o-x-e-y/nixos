#let template-config(
  theme-name: "Gruvbox-N",
  heading-pagebreak: true,
  doc,
) = {
  import "@preview/codly:1.3.0": *
  show: codly-init.with()

  import "@preview/codly-languages:0.1.8": *

  let codly-langs = codly-languages
    .pairs()
    .map(((lang, cfg)) => {
      cfg.name = text(fill: black, cfg.name)
      (lang, cfg)
    })
    .to-dict()

  let custom-langs = (
    casm: (
      name: text(fill: black, [CASM]),
      color: rgb("#15952f"),
      icon: codly-langs.asm.icon,
    ),
  )

  codly(
    languages: codly-langs + custom-langs,
  )

  show ref: r => (
    text(
      fill: rgb(160, 160, 255),
      underline(r),
    )
  )

  show link: l => (
    text(
      fill: red, //blue.lighten(-30%),
      underline(l),
    )
  )

  show heading.where(level: 1): h => {
    if heading-pagebreak and h.supplement != [Appendix] {
      pagebreak(
        weak: true,
      )
    }
    h
  }

  let theme-path = "./" + theme-name + ".tmTheme"
  let xml-theme = xml(theme-path)
  let theme-arr = xml-theme
    .at(0)
    .children
    .at(1)
    .children
    .at(7)
    .children
    .at(1)
    .children
    .at(3)
    .children
    .filter(v => type(v) != str)
  let foreground-pos = theme-arr.position(v => v.children == ("foreground",)) + 1
  let theme-foreground = theme-arr.at(foreground-pos).children.at(0)
  let background-pos = theme-arr.position(v => v.children == ("background",)) + 1
  let theme-background = theme-arr.at(background-pos).children.at(0)
  codly(
    zebra-fill: rgb(theme-background).lighten(2%),
    fill: rgb(theme-background),
    stroke: none,
  )
  set raw(
    theme: theme-path,
  )
  show raw.where(block: true): it => {
    let lines = it.text.split("\n")

    if lines.len() > 0 and lines.last() == "" {
      lines.pop()
    }

    let len = lines.len()
    let line-char-count = str(len).len()

    let gutter-line = place(
      dx: 1em + line-char-count * 0.6em,
      dy: -100% - 4pt,
      line(
        length: 8pt + len * 1.69em,
        angle: 90deg,
        stroke: rgb(theme-foreground).transparentize(50%) + 0.67pt,
      ),
    )

    let code = text(
      fill: rgb(theme-foreground),
      font: "JetBrainsMono NF",
      it,
    )

    block(
      fill: rgb(theme-background),
      inset: 2pt,
      radius: 7pt,
      block(
        fill: rgb(theme-background),
        inset: 4pt,
        radius: 6pt,
        stroke: 1pt + rgb(theme-foreground),
        [
          #code
          #gutter-line
        ],
      ),
    )
  }


  let theme_idle = (
    comment: rgb("#919191"),
    constant: rgb("#A535AE"),
    string: rgb("#00A33F"),
    interpolation: rgb("#990000"),
    keyword: rgb("#FF5600"),
    operator: rgb("#FF5600"),
    type: rgb("#21439C"),
    function: rgb("#21439C"),
    invalid: rgb("#990000"),
  )
  let theme = theme_idle

  let theme_lazy = (
    comment: rgb("#ACADAC"),
    constant: rgb("#3B5BB5"),
    string: rgb("#409B1C"),
    interpolation: rgb("#671EBB"),
    keyword: rgb("#FF6600"),
    // operator: rgb("#3B5BB5"),
    operator: rgb("#FF6600"),
    type: rgb("#3A4A64"),
    function: rgb("#3E4558"),
    invalid: rgb("#9D1E15"),
  )

  let casm = (
    comment: regex(";.*$"),
    register: regex("\b(R0|R1|H|L|HL|ACC|SP|BP|PC|FLAGS)\b"),
    instruction: regex(
      "\b(NOOP|HALT|EI|DI|ET|DT|RESET|LOAD|STORE|XCH|ADD|ADC|SUB|SBC|INC|DEC|NEG|NOT|AND|OR|XOR|SHL|SHR|ROL|ROR|ADDW|SUBW|MULW|DIVW|JMP|JZ|JNZ|JC|JNC|JEXT|CMP|PUSH|POP|CALL|RET|ENTER|LEAVE|MIN|MAX)\b",
    ),
    constant: regex("\b\\d+\b"),
    label: regex("(\\.[\\w\\-_]+|[\\w\\-_]+:|[\\w\\-_]+\\[)"),
    string: regex("\"[^\"]*\""),
    operator: regex("([^\\w][+-]|[+-][^\\w])"),
    addr: regex("[\\[\\](){},]"),
  )

  show raw.where(lang: "casm"): it => [
    #show casm.addr: x => text(x, fill: black)
    #show casm.instruction: x => text([*#x*], fill: theme.keyword)
    #show casm.register: x => text(x, fill: theme.constant)
    #show casm.constant: x => text(x, fill: black)
    #show casm.label: x => text(x, fill: theme.string)
    #show casm.string: x => text(x, fill: theme.string)
    #show casm.operator: x => text(x, fill: theme.operator)
    #show casm.comment: x => text(x, fill: theme.comment)
    #it
  ]

  show raw.where(block: false): data => box(
    block(
      fill: rgb("#e8e8e8"),
      stroke: 0.4pt + rgb("#acacac"),
      inset: 1.7pt,
      radius: 2pt,
      text(fill: rgb("#000000"), size: 1.125em, data),
    ),
    inset: (y: -1.7pt, x: 0pt),
  )

  doc
}

#let template(
  title: none,
  subtitle: none,
  author: [Luc Oerlemans],
  version: none,
  date: auto,
  description: none,
  cover: none,
  accent: rgb("#6c782e"), //rgb("#457b9d"),
  font: "IBM Plex Sans",
  font-size: 11pt,
  theme-name: "Gruvbox-N",
  show-title: true,
  show-table-of-contents: true,
  heading-pagebreak: true,
  doc,
) = {
  show: template-config.with(
    theme-name: theme-name,
    heading-pagebreak: heading-pagebreak,
  )

  set text(
    font: font,
    size: font-size,
  )

  set par(
    justify: true,
  )

  let author-str = if type(author) == str { author }
    else if type(author) == content { author.text }
    else { "" }

  set document(
    title: title,
    author: author-str,
  )

  set heading(
    numbering: "1.",
  )

  set page(numbering: (..nums) => {
    if nums.pos().at(0) != 1 {
      numbering("1", nums.pos().at(0))
    }
  })

  let display-date = if date == auto {
    datetime.today().display("[month repr:long] [day], [year]")
  } else if date != none {
    date
  }

  if show-title {
    // accent bar
    line(length: 100%, stroke: 3pt + accent)
    v(1fr)

    // title block
    align(center)[
      #text(font-size * 3, weight: "bold", fill: accent, title)
      #if subtitle != none {
        v(0.4em)
        text(font-size * 1.6, weight: "regular", fill: accent.lighten(20%), subtitle)
      }
      #if description != none {
        v(1.2em)
        line(length: 40%, stroke: 0.5pt + accent.lighten(40%))
        v(0.8em)
        text(font-size * 1.1, style: "italic", description)
      }
    ]

    // cover image
    if cover != none {
      v(1.5em)
      align(center, figure(
        cover,
        outlined: false,
        numbering: none,
      ))
    }

    v(1fr)

    // bottom info bar
    line(length: 100%, stroke: 0.5pt + accent.lighten(40%))
    v(0.5em)
    {
      set text(font-size * 0.95)
      let cells = ()
      if author != none { cells.push(align(left, strong(author))) }
      if version != none { cells.push(align(center, [v#version])) }
      if display-date != none {
        let date-align = if cells.len() == 0 { left } else { right }
        cells.push(align(date-align, emph(display-date)))
      }
      if cells.len() > 0 {
        grid(
          columns: (1fr,) * cells.len(),
          ..cells,
        )
      }
    }
    v(0.3em)
    line(length: 100%, stroke: 3pt + accent)
  }

  if show-table-of-contents == true {
    pagebreak(weak: true)
    outline()
    pagebreak(weak: true)
  }

  doc
}

#let snippet(
  caption: none,
  doc,
) = {
  let name = "Snippet"

  figure(
    caption: caption,
    kind: name,
    supplement: name,
    doc,
  )
}

/// altered version of https://github.com/typst/templates/blob/main/charged-ieee/lib.typ
/// DOES NOT WORK WITH DEEPER LEVELS
#let appendix(body) = {
  pagebreak(weak: true)
  set heading(numbering: "A.1", supplement: [Appendix])
  counter(heading).update(0)
  show heading: it => {
    // set text(11pt, weight: 400)
    // set align(center)
    // show: block.with(above: 15pt, below: 13.75pt, sticky: true)
    // show: smallcaps
    // let c = counter(heading).display()
    [#it.supplement #counter(heading).display(): #it.body]
  }
  body
}

#let image_right(
  path: str,
  caption: none,
  reference: none,
  doc,
) = {
  let label = if reference != none {
    label(reference)
  } else {
    none
  }

  let f = [#figure(
      image(
        path,
      ),
      caption: caption,
    ) #label]

  grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    doc, f,
  )
}

#let image_cols(
  img: image,
  caption: none,
  reference: none,
  columns: (1fr, 1fr),
  gutter: 2em,
  doc,
) = {
  let f = [#figure(
      img,
      caption: caption,
    ) #if reference != none {
      label(reference)
    }]

  grid(
    columns: columns,
    gutter: gutter,
    doc,
    f
  )
}

#let sql(txt) = {
  raw(
    lang: "sql",
    txt,
  )
}

#let easy_date(year, month, day) = {
  let d = datetime(
    year: year,
    month: month,
    day: day,
  )

  [#d.display(
    "[day] [month repr:short] [year]",
  )]
}

#let crate(name) = link("https://crates.io/crates/" + name, name)
