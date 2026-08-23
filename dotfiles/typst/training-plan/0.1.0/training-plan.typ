// training-plan.typ
// Components: make-zones(), workout-viewer(), week-table()

// ── Internals ─────────────────────────────────────────────────────────────────

#let _pace-to-sec(p) = {
  let parts = p.split(":")
  int(parts.at(0)) * 60 + int(parts.at(1))
}

#let _n-zones(metric) = {
  if metric == "hr"    { 5 }
  else if metric == "pace"  { 6 }
  else if metric == "power" { 7 }
  else { 5 }
}

// t=0 (easiest) → lighten 55 %;  t=1 (hardest) → darken 35 %
#let _zone-color(base, zone, n) = {
  let t = if n <= 1 { 0.0 } else { (zone - 1) / (n - 1) }
  if t <= 0.5 {
    base.lighten(int((0.5 - t) * 110) * 1%)
  } else {
    base.darken(int((t - 0.5) * 70) * 1%)
  }
}

// Z1 → 18 % of max height; max zone → 100 %
#let _zone-h-frac(zone, n) = {
  if n <= 1 { 0.6 } else { 0.18 + 0.82 * (zone - 1) / (n - 1) }
}

#let _dur-str(d) = {
  if d == calc.floor(d) { str(int(d)) } else { str(d) }
}

// 3870 → "3,870". Every fuel figure is four digits or fewer.
#let _thousands(n) = {
  let s = str(n)
  if s.len() > 3 { s.slice(0, s.len() - 3) + "," + s.slice(s.len() - 3) } else { s }
}

#let _dist-str(km) = {
  if km >= 1 {
    if km == calc.floor(km) { str(int(km)) + "km" } else { str(km) + "km" }
  } else {
    str(int(calc.round(km * 1000))) + "m"
  }
}

#let _zone-pace-sec(zone, zones) = {
  let b = zones.pace-sec
  if zone <= 1           { b.first() }
  else if zone > b.len() { b.last() }
  else                   { (b.at(zone - 2) + b.at(zone - 1)) / 2 }
}

#let _resolve-zone(step, zones, default-metric) = {
  if "zone" in step { return step.zone }
  let m = step.at("metric", default: default-metric)
  if m == "hr" and "hr" in step {
    let b = zones.hr-bounds
    for i in range(1, b.len()) {
      if step.hr < b.at(i) { return i }
    }
    return b.len() - 1
  }
  if m == "pace" and "pace" in step {
    let sec = _pace-to-sec(step.pace)
    let b = zones.pace-sec
    for i in range(b.len()) {
      if sec > b.at(i) { return i + 1 }
    }
    return b.len() + 1
  }
  if m == "power" and "power" in step {
    let b = zones.power-w
    for i in range(b.len()) {
      if step.power < b.at(i) { return i + 1 }
    }
    return b.len() + 1
  }
  1
}

#let _expand-steps(steps, zones, default-metric) = {
  let result = ()
  for step in steps {
    if "steps" in step {
      let rep  = step.at("repeat", default: 1)
      let skip = step.at("skip-last-recovery", default: true)
      let sub  = _expand-steps(step.steps, zones, default-metric)
      for i in range(rep) {
        let is-last = i == rep - 1
        if is-last and skip {
          let trimmed = sub
          while trimmed.len() > 0 {
            let z = if "zone" in trimmed.last() {
              trimmed.last().zone
            } else if zones != none {
              _resolve-zone(trimmed.last(), zones, default-metric)
            } else { 1 }
            if z <= 1 { trimmed = trimmed.slice(0, trimmed.len() - 1) }
            else { break }
          }
          result = result + trimmed
        } else if i > 0 {
          let sub-delabeled = sub.map(item => {
            // Copy the whole step, dropping only the label so it isn't
            // repeated on every rep. Whitelisting keys here previously lost
            // `power`/`hr`, collapsing auto-detected steps to Z1 on middle reps.
            let base = item
            if "label" in base { let _ = base.remove("label") }
            base
          })
          result = result + sub-delabeled
        } else {
          result = result + sub
        }
      }
    } else {
      result.push(step)
    }
  }
  result
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Build a zones configuration dictionary to pass to workout-viewer.
///
/// accent        Base colour. Easier efforts render lighter; harder render darker.
/// hr-bounds     6 HR values bounding 5 zones: (min, z1/z2, z2/z3, z3/z4, z4/z5, max)
/// pace-bounds   5 "M:SS" zone-boundary strings, slow→fast: (z1/z2 … z5/z6) → 6 zones
/// ftp           FTP in watts.
/// power-bounds  6 FTP fractions bounding 7 zones: (z1/z2, z2/z3, z3/z4, z4/z5, z5/z6, z6/z7)
///
/// Example:
///   #let my-zones = make-zones(
///     accent: rgb("#b85c38"),
///     hr-bounds: (122, 143, 154, 165, 177, 201),
///     pace-bounds: ("5:25", "4:45", "4:05", "3:35", "3:05"),
///     ftp: 260,
///     power-bounds: (0.56, 0.76, 0.91, 1.06, 1.21, 1.51),
///   )
#let make-zones(
  accent: rgb("#6c782e"),
  hr-bounds: (122, 143, 154, 165, 177, 201),
  pace-bounds: ("5:25", "4:45", "4:05", "3:35", "3:05"),
  ftp: 260,
  power-bounds: (0.56, 0.76, 0.91, 1.06, 1.21, 1.51),
) = (
  accent:    accent,
  hr-bounds: hr-bounds,
  pace-sec:  pace-bounds.map(_pace-to-sec),
  ftp:       ftp,
  power-w:   power-bounds.map(f => f * ftp),
)

/// Render a workout as a proportional coloured bar chart.
/// Bar width = duration; bar height + colour = intensity zone.
///
/// zones        Result of make-zones(), or none for greyscale.
/// metric       "hr" | "pace" | "power"
/// steps        Array of dicts:
///                duration   number (minutes) — controls bar width
///                zone       int (1-based, skips auto-detect)
///                hr / pace / power — value for auto zone detection
///                label      str — shown above bar (optional)
/// height       Height of the tallest bar (hardest zone).
/// show-labels  Show step labels above and durations below bars.
/// show-legend  Show a zone colour strip at the bottom.
///
/// Example:
///   #workout-viewer(
///     zones: my-zones, metric: "pace",
///     steps: (
///       (duration: 15, zone: 1, label: "WU"),
///       (duration: 5,  pace: "3:45", label: "1km"),
///       (duration: 2,  zone: 1, label: "rec"),
///       (duration: 5,  pace: "3:45"),
///       (duration: 2,  zone: 1),
///       (duration: 10, zone: 1, label: "CD"),
///     ),
///   )
#let workout-viewer(
  zones: none,
  metric: "hr",
  steps: (),
  height: 55pt,
  show-labels: true,
  show-legend: true,
  rest-width: 14pt,
) = {
  if steps.len() == 0 { return [] }

  let steps = _expand-steps(steps, zones, metric)
  if steps.len() == 0 { return [] }

  let steps = steps.map(s => {
    if "distance" not in s { return s }
    let pace-s = if "pace" in s {
      _pace-to-sec(s.pace)
    } else if zones != none {
      let z = if "zone" in s { s.zone }
              else { _resolve-zone(s, zones, metric) }
      _zone-pace-sec(z, zones)
    } else { none }
    if pace-s == none { return s + (duration: 1) }
    s + (duration: s.distance * pace-s / 60)
  })

  let nz   = _n-zones(metric)
  let base = if zones != none { zones.accent } else { rgb("#999999") }

  let data = steps.map(s => {
    let z = calc.clamp(
      if zones != none { _resolve-zone(s, zones, metric) }
      else             { s.at("zone", default: 1) },
      0, nz,
    )
    (
      dur:     s.duration,
      z:       z,
      h:       if z == 0 { height * 0.07 }
               else      { height * _zone-h-frac(z, nz) },
      c:       if z == 0 { rgb("#d8d8d8") }
               else      { _zone-color(base, z, nz) },
      lbl:     s.at("label", default: none),
      dur-lbl: if "distance" in s { _dist-str(s.distance) }
               else               { _dur-str(s.duration) + "′" },
    )
  })

  let cols = data.map(d => if d.z == 0 { rest-width } else { d.dur * 1fr })

  let label-row = grid(
    columns: cols, column-gutter: 1.5pt, align: bottom + center,
    ..data.map(d =>
      if d.lbl != none { text(size: 6.5pt, fill: rgb("#333"), d.lbl) } else { [] }
    ),
  )

  let bar-row = grid(
    columns: cols, rows: (height,), column-gutter: 1.5pt, align: bottom,
    ..data.map(d =>
      box(
        width: 100%, height: d.h, fill: d.c,
        radius: (top-left: 2pt, top-right: 2pt),
      )
    ),
  )

  let dur-row = grid(
    columns: cols, column-gutter: 1.5pt, align: top + center,
    ..data.map(d => text(size: 5.5pt, fill: rgb("#555"), d.dur-lbl)),
  )

  let legend = grid(
    columns: (1fr,) * nz, column-gutter: 2pt, align: center,
    ..range(1, nz + 1).map(z => stack(
      dir: ttb, spacing: 1pt,
      box(width: 100%, height: 4pt, fill: _zone-color(base, z, nz), radius: 1pt),
      text(size: 5pt, fill: rgb("#555"), "Z" + str(z)),
    )),
  )

  block(width: 100%, stack(
    dir: ttb, spacing: 2pt,
    ..if show-labels { (label-row,) } else { () },
    bar-row,
    ..if show-labels { (dur-row,) } else { () },
    ..if show-legend { (4pt, legend) } else { () },
  ))
}

/// Render a week's training schedule as a styled table.
///
/// accent   Header background colour.
/// days     Array of dicts:
///            day      str or content — label for the Day column
///            session  content — session description text
///            workout  content — optional workout-viewer output; stacked below session
///            work     str — optional work status ("free", "not rostered yet", or an
///                     "HH:MM–HH:MM" shift range); rendered as a small tinted line at the
///                     top of the row so it never narrows the workout chart
/// total    str — running total shown below the table, e.g. "~42–46 km"
/// note     content — optional extra note below the table
///
/// Example:
///   #week-table(
///     accent: rgb("#6b7c6b"),
///     days: (
///       (day: "Mon", session: [Commute cycling]),
///       (day: "Tue", session: [WU 15min → 6×1km \@3:50/km → CD 10min],
///        workout: workout-viewer(zones: my-zones, metric: "pace", steps: (...))),
///       (day: "Wed", session: [Easy 35min + Strength]),
///     ),
///     total: "~42–46 km",
///   )
// How a session landed against what was asked of it.
#let _outcome-color(o) = {
  if o == "clean" { rgb("#1f7a4d") }
  else if o == "partial" { rgb("#a8572f") }
  else if o == "failed" { rgb("#9c2b2b") }
  else { rgb("#5a5a5a") }
}

// The block's whole evidentiary base in one table. Objective columns come from
// intervals.icu via review/sessions.py; only `prescribed` and `verdict` are
// written by hand, in review/log.json. Cite a row rather than retelling it.
#let session-log(data, kind: "quality") = {
  let rows = data.sessions.filter(s => s.type == kind)
  if rows.len() == 0 { return [] }

  let hdr(body) = table.cell(
    fill: rgb("#3f4f45"),
    text(fill: white, weight: "bold", size: 8pt, body),
  )
  let cells = rows.map(s => {
    let col = _outcome-color(s.outcome)
    let cond = {
      let bits = ()
      if s.temp_work != none { bits.push[#s.temp_work °C] }
      if s.tsb != none {
        let sign = if s.tsb >= 0 { "+" } else { "" }
        bits.push[#sign#s.tsb]
      }
      if s.feel != none { bits.push[#s.feel] }
      text(size: 7.5pt)[#bits.join[ · ]]
    }
    let result = {
      let d = if s.delivered != none {
        text(size: 8pt, weight: "semibold", fill: col)[#s.delivered]
      } else {
        text(size: 8pt, fill: rgb("#9a9a9a"))[—]
      }
      stack(dir: ttb, spacing: 2pt,
        d,
        text(size: 7.5pt, fill: rgb("#4a4a4a"))[#s.verdict],
      )
    }
    (
      table.cell(text(size: 8pt)[#s.date.slice(5)]),
      table.cell(text(size: 8pt)[#s.name]),
      table.cell(text(size: 8pt, fill: rgb("#5a5a5a"))[
        #if s.prescribed != none { s.prescribed } else { "—" }
      ]),
      table.cell(cond),
      table.cell(result),
    )
  }).flatten()

  table(
    columns: (auto, auto, auto, auto, 1fr),
    stroke: none,
    fill: (_, y) => if calc.odd(y) { rgb("#f5f0eb") } else { white },
    inset: (x: 6pt, y: 5pt),
    table.header(
      hdr[Date], hdr[Session], hdr[Asked], hdr[°C · TSB · feel], hdr[Delivered],
    ),
    ..cells,
  )
}

#let week-table(
  accent: rgb("#6b7c6b"),
  days: (),
  total: none,
  note: none,
) = {
  let mk-hdr(body) = table.cell(fill: accent, text(fill: white, weight: "bold", body))

  let work-badge(w) = {
    if w == none { return none }
    let is-off = w == "free" or w == "not rostered yet"
    let col = if is-off { rgb("#9a9a9a") } else { rgb("#a8572f") }
    text(size: 7.5pt, fill: col, weight: "semibold", tracking: 0.2pt)[Work: #w]
  }

  // Daily calorie and carbohydrate target, generated by nutrition/fuel.py.
  let fuel-badge(f) = {
    if f == none { return none }
    let arrow = if f.carb_flag == "up" { [ #sym.arrow.t] }
      else if f.carb_flag == "down" { [ #sym.arrow.b] }
      else { [] }
    let split = if f.on_bike_kcal > 0 {
      [ — #_thousands(f.off_bike_kcal) off bike + #_thousands(f.on_bike_kcal) on]
    } else { [] }
    text(size: 7.5pt, fill: rgb("#2f6f8f"), weight: "semibold", tracking: 0.2pt)[
      Fuel: #_thousands(f.total_kcal) kcal#split · #f.carb_g g carb#arrow
    ]
  }

  // What the session actually returned — the objective conditions plus the
  // rider's own read of it. Generated by review/sessions.py; never hand-typed.
  let result-badge(r) = {
    if r == none { return none }
    let col = _outcome-color(r.outcome)
    let bits = ()
    if r.at("temp_work", default: none) != none {
      bits.push[#r.temp_work °C reps]
    }
    if r.at("tsb", default: none) != none {
      let s = if r.tsb >= 0 { "+" } else { "" }
      bits.push[TSB #s#r.tsb]
    }
    if r.at("feel", default: none) != none {
      bits.push[feel #r.feel (#r.feel_label)]
    }
    if r.at("rpe", default: none) != none {
      bits.push[RPE #r.rpe]
    }
    let strip = text(size: 7.5pt, fill: col, weight: "semibold", tracking: 0.2pt)[
      Ridden: #bits.join[ · ]
    ]
    if r.at("note", default: none) != none {
      stack(dir: ttb, spacing: 2pt,
        strip,
        text(size: 7.5pt, fill: rgb("#5a5a5a"), style: "italic")[#emph[“#r.note”]],
      )
    } else {
      strip
    }
  }

  let rows = days.map(d => {
    let body = if d.at("workout", default: none) != none {
      stack(dir: ttb, spacing: 6pt, d.session, d.workout)
    } else {
      d.session
    }
    let badges = (
      work-badge(d.at("work", default: none)),
      fuel-badge(d.at("fuel", default: none)),
      result-badge(d.at("result", default: none)),
    ).filter(b => b != none)
    let sess = if badges.len() > 0 {
      stack(dir: ttb, spacing: 4pt, ..badges, body)
    } else {
      body
    }
    (table.cell(strong([#d.day])), table.cell(sess))
  }).flatten()

  table(
    columns: (auto, 1fr),
    stroke: none,
    fill: (_, y) => if calc.odd(y) { rgb("#f5f0eb") } else { white },
    inset: (x: 10pt, y: 7pt),
    table.header(mk-hdr[Day], mk-hdr[Session]),
    ..rows,
  )

  if total != none {
    v(3pt)
    [*Running:* #total]
  }
  if note != none {
    parbreak()
    note
  }
}
