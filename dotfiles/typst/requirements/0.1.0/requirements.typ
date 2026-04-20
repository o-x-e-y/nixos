#let get-req-color(priority) = {
  if lower(priority) == "must" {
    rgb("#e6cff2")
  } else if lower(priority) == "high" {
    rgb("#d4edbc")
  } else if lower(priority) == "med" {
    rgb("#ffe5a0")
  } else if lower(priority) == "low" {
    rgb("#ffcfc9")
  } else {
    white
  }
}

#let prio(priority) = {
  let c = get-req-color(priority)
  let color = if c != none {
    c.saturate(100%).darken(40%)
  } else {
    black
  }

  box(
    block(
      fill: c,
      stroke: 0.4pt + rgb("#acacac"),
      inset: 1.7pt,
      radius: 2pt,
      text(fill: color)[#upper(priority)],
    ),
    inset: (y: -2pt, x: 0.3pt),
  )
}

#let must = prio("must")
#let high = prio("high")
#let med = prio("med")
#let low = prio("low")

#let user-requirements(
  caption: none,
  key: "US",
  start-at: 1,
  zebra-fill: rgb("#efefef"),
  ..children,
) = {
  let req(
    description,
    priority,
    index,
  ) = {
    let c = get-req-color(priority)
    let color = if c != none {
      c.saturate(100%).darken(40%)
    } else {
      black
    }

    let reference = lower(key) + str(index)
    let supplement = key + "-" + str(index)

    (
      [#figure(kind: key, supplement: key, supplement) #label(reference)],
      [#align(left)[#description]],
      text(fill: color)[#upper(priority)],
    )
  }

  let requirements = children
    .pos()
    .enumerate()
    .map(
      ((row, (desc, prio))) => req(desc, prio, row + start-at),
    )

  let table = table(
    columns: (5em, 1fr, 5em),
    stroke: 1pt,
    align: center + horizon,
    inset: (3 / 5) * 1em,
    fill: (col, row) => {
      let priority = children.at(row).at(1)
      if col == 2 { get-req-color(priority) } else if calc.odd(row) { zebra-fill } else { none }
    },
    ..requirements.flatten()
  )

  figure(
    kind: key,
    supplement: key + " Table",
    caption: caption,
    table,
  )
}
