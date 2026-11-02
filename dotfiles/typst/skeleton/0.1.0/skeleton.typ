#let note(body) = block(
  width: 100%,
  inset: 10pt,
  radius: 3pt,
  fill: luma(235),
  text(size: 0.9em, body),
)

#let placeholder(caption, height: 4cm) = figure(
  rect(width: 100%, height: height, stroke: (dash: "dashed", paint: luma(120)))[
    #align(center + horizon, text(fill: luma(120))[Figure placeholder])
  ],
  caption: caption,
)
