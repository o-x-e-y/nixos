#import "@preview/oxifmt:0.2.1": strfmt

#let get_complevel_color(value) = {
  if value == 0.5 { rgb("#94f6ff80") }
  else if value == 1 { rgb("#94f6ff") }
  else if value == 2 { rgb("#b2ffa3") }
  else if value == 3 { rgb("#fdffb6") }
  else { white }
}

#let competence_profile(
  main_competence_numbers: (()),
  personal_numbers: (),
  caption: none,
  show_legend: false
) = {
  let scale_factor = 70%;

  // cell background color

  // convert values to display format
  let format_cell(value) = {
    if value == none or value == 0 { [] }
    else { [#value] }
  }

  // format labels for black background
  let format_label(label) = {
    text(white)[#label]
  }

  let main_headings = (
    [],
    [Managing],
    [Analysing],
    [Advising],
    [Designing],
    [Realising],
  )

  let row_names = (
    [User Interaction],
    [Business Processes],
    [Software],
    [Hardware],
    [Infrastructure],
  )

  let legend = scale(
    scale_factor,
    origin: top + left,
    reflow: true,
    table(
      rows: 1,
      columns: 3,
      stroke: 1pt * 150% * scale_factor,
      fill: (col, row) => {
        if col == 0 { get_complevel_color(1) }
        else if col == 1 { get_complevel_color(2) }
        else if col == 2 { get_complevel_color(3) }
        else { white }
      },
      [Level 1], [Level 2], [Level 3],
    ),
  )

  let main_competence_row(idx) = (
    format_label(row_names.at(idx)),
    ..main_competence_numbers.at(idx).map(format_cell),
  )

  let table1 = scale(
    scale_factor,
    origin: top + left,
    reflow: true,
    table(
      columns: 6,
      rows: 6,
      fill: (col, row) => {
        if col == 0 and row == 0 { white }
        else if col == 0 or row == 0 { black }
        else { get_complevel_color(main_competence_numbers.at(row - 1).at(col - 1)) }
      },
      stroke: (col, row) => {
        if col == 0 and row == 0 { none }
        else { 1pt * 150% * scale_factor }
      },
      align: center + horizon,
      inset: 10pt * scale_factor,
      ..main_headings.map(format_label),
      ..range(0, 5).map(main_competence_row).flatten(),
    ),
  )

  let personal_headings = (
    [Professional Standard],
    [Personal Leadership],
  )

  let format_personal_data(num) = {
    box(height: 32pt * scale_factor, [#num])
  }

  let table2 = scale(
    scale_factor,
    origin: top + left,
    reflow: true,
    [
      #table(
        columns: 2,
        rows: 2,
        fill: (col, row) => {
          if row == 0 { black }
          else { get_complevel_color(personal_numbers.at(col)) }
        },
        stroke: 1pt * 150% * scale_factor,
        ..personal_headings.map(format_label),
        ..personal_numbers.map(format_personal_data),
        align: center + horizon,
        inset: 10pt * scale_factor,
      )
      #scale(128% * scale_factor, [Legend:]),
      #v(-17pt)
      #scale(
        256% * scale_factor,
        [#legend],
        reflow: true,
      )
    ],
  )

  figure(
    caption: caption,
    [
      #grid(
        columns: (2.7fr, 1fr),
        table1, table2,
      )
    ],
  )
}

#let kpi_table(rows: ()) = {
  let headers = (
    [KPI],
    [Proof],
    [Rating],
  )

  let format_header(header) = {
    text(white)[*#header*]
  }

  let kpi-rating-color(v) = {
    if v == "U" {
      rgb("#ffb3b3")
    } else if ("S", "G", "O").contains(v) {
      rgb("#b2ffa3")
    } else {
      rgb("#c6b7ff")
    }
  }

  let table = table(
    columns: (auto, 1.5fr, auto),
    fill: (col, row) => {
      if row == 0 { black }
      else if col == 2 {
        let v = rows.at(row - 1).at(2)
        kpi-rating-color(v)
      }
    },
    stroke: 1pt,
    align: center + horizon,
    inset: 8pt,
    ..headers.map(format_header),
    ..range(0, rows.len())
      .map(i => {
        rows.at(i).slice(0, 3).map(v => [#v])
      })
      .flatten()
  )

  let ratings = (none, "U", "S", "G", "O")

  let legend = grid(
    columns: 5,
    stroke: 1pt,
    align: center + horizon,
    inset: 8pt,
    fill: (col, row) => {
      let v = ratings.at(col)
      kpi-rating-color(v)
    },
    ..ratings.map(v => {
      if v == none {
        [Ungraded]
      } else {
        v
      }
    })
  )

  [
    #table
    #box([Legend: #legend])
  ]
}

#let kpi(dest, body) = {
  show link: l => text(fill: blue.lighten(-30%), l.body)
  [#link(dest)[#body] #linebreak()]
}

#let complevel(num) = {
  let color = get_complevel_color(num)

  let cl = box(
    block(
      fill: color,
      stroke: 0.4pt + color.darken(30%),
      inset: 2pt,
      radius: 2pt,
      text(fill: rgb("#000000"), [#num]),
    ),
    baseline: 2pt,
  )

  cl
}

#let feedpulse(
  teacher: none,
  grade: none,
  date: none,
  doc,
) = {
  let grade_info = if (upper(grade) == "U") {
    text(rgb(192, 0, 0), "Unsatisfactory")
  } else if (upper(grade) == "S") {
    text(rgb(47, 116, 181), "Satisfactory")
  } else if (upper(grade) == "O") {
    text(rgb(0, 176, 80), "Outstanding")
  } else {
    text(rgb(192, 0, 0), "Invalid grade")
  }
  let grade = if (grade != none) {
    [Grade: *#grade_info* #linebreak()]
  }
  [
    #heading(level: 2, numbering: none)[#date]
    #grade
    #doc
  ]
};

#kpi_table(rows: (
  (1, 2, 3),
  (5, 6, 7),
));

// Example usage:
#let main_competence_numbers = (
  (1, 2, none, 3, 1),
  (none, 2, 3, 1, none),
  (2, none, 1, 3, 2),
  (1, 3, 2, none, 1),
  (none, 1, 3, 2, none),
)

#let personal_numbers = (1, none, 2, 3);

#competence_profile(
  main_competence_numbers: main_competence_numbers,
  personal_numbers: personal_numbers,
  caption: "Current profile",
)
