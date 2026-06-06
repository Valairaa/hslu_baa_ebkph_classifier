#let cover(
  title: none,
  subtitle: none,
  authors: (),
  university: none,
  degree_program_full: none,
  report_date: none,
) = {
  v(-2.5em)
  move(dx: 0em)[
    #grid(
      columns: (2fr, 2fr),
      column-gutter: 50pt,
      align(left)[
        #image("/template/images/HSLU_2022_logo.png", width: 80%)
      ],
      align(right)[
        #move(dy: -3.0em, dx: 6em)[#image("/template/images/Informatik_2026_logo.png", width: 130%)]
      ],
    )
  ]

  align(horizon + center)[

    #text(size: 24pt, [#title])\

    #v(1em)

    #subtitle

    #v(2em)

    #let count = authors.len()
    #let ncols = calc.min(count, 3)

    #let author_title = "Autor"
    #if (count > 1) {
      author_title = author_title + "s"
    }

    *#author_title*
    #grid(
      columns: (1fr,) * ncols,
      row-gutter: 24pt,
      ..authors.map(author => [
        #author.name \
        #author.address \
        #link("mailto:" + author.email)
      ]),
    )

    #v(3em)

    #university\
    #degree_program_full

    #v(3em)

    //#report_date.display("[month repr:long] [day], [year repr:full]")
    #report_date.display("08. Juni 2026")
  ]
}
