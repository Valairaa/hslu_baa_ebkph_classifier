
/*
	Custom caption function to have a caption title and body
	author: laurmaedje
	url: https://sitandr.github.io/typst-examples-book/book/snippets/chapters/outlines.html#long-and-short-captions-for-the-outline
*/
#let show-title = state("show-short-title", true)

#let title-caption(title, caption) = (
  context if show-title.get() {
    title
  } else {
    caption
  }
)

#let hint(hint_text) = text(
  fill: blue,
  size: 12pt,
  style: "italic",
  hint_text + "\n\n",
)

#let todo(todo_text) = text(
  fill: red,
  size: 12pt,
  "TODO: " + todo_text + "\n\n",
)

#let eq_legend(..entries) = [
  wobei:
  #table(
    columns: (auto, auto, 1fr),
    stroke: none,
    inset: (x: 4pt, y: 2pt),
    ..entries.pos().map(e => (e.at(0), [:], e.at(1))).flatten(),
  )
]

#let format_num(n) = {
  let s = str(int(n))
  let chars = s.clusters()
  let len = chars.len()
  let result = ""
  for (i, ch) in chars.enumerate() {
    if i > 0 and calc.rem(len - i, 3) == 0 {
      result += "'"
    }
    result += ch
  }
  result
}

#let fmt(v) = str(calc.round(v, digits: 4)).replace(".", ",")

#let delta(a, b) = {
  let d = calc.round(a - b, digits: 4)
  if d >= 0 { [+#fmt(d)] } else { [#fmt(d)] }
}

#let delta_pct(a, b) = {
  let d = calc.round((a - b) * 100, digits: 2)
  if d >= 0 { [+#fmt(d) %] } else { [#fmt(d) %] }
}

#let image_grid(images, caption, columns: 2) = figure(
  grid(
    columns: (1fr,) * columns,
    column-gutter: 1em,
    row-gutter: 1em,
    ..images,
  ),
  caption: caption,
  kind: image,
)
