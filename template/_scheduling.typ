// colors
#let col-header-bg = rgb("#2c3e50")
#let col-row-odd = rgb("#f7f9fc")
#let col-row-even = rgb("#eaf0fb")
#let col-bar = rgb("#2980b9")
#let col-bar-done = rgb("#27ae60")
#let col-border = rgb("#b0bec5")
#let col-week-odd = rgb("#34495e")
#let col-week-even = rgb("#16a085")   // Teal für gerade Wochen
#let col-week-text = white
#let col-meta-bg = rgb("#ecf0f1")
#let col-we-odd = rgb("#d5e8f7")   // Wochenende ungerade SW
#let col-we-even = rgb("#d5f0e8")   // Wochenende gerade SW
#let col-stripe = rgb("#eef6f0")   // Wochenstreifen gerade SW

// date helper
#let _dim(m, y) = {
  if m == 2 {
    if calc.rem(y, 400) == 0 { 29 } else if calc.rem(y, 100) == 0 { 28 } else if calc.rem(y, 4) == 0 { 29 } else { 28 }
  } else if m in (4, 6, 9, 11) { 30 } else { 31 }
}

#let _date-from-offset(offset, sd, sm, sy) = {
  let d = sd + offset
  let m = sm
  let y = sy
  while d > _dim(m, y) {
    d -= _dim(m, y)
    m += 1
    if m > 12 {
      m = 1
      y += 1
    }
  }
  (d: d, m: m, y: y)
}

#let _fmt(offset, sd, sm, sy) = {
  let dt = _date-from-offset(offset, sd, sm, sy)
  let dd = if dt.d < 10 { "0" + str(dt.d) } else { str(dt.d) }
  let mm = if dt.m < 10 { "0" + str(dt.m) } else { str(dt.m) }
  dd + "." + mm + "." + str(dt.y).slice(2)
}

// main function
#let planning-gantt(
  tasks: (),
  title: "Terminprogramm",
  start-day: 16,
  start-month: 2,
  start-year: 2026,
  n-weeks: 16,
  day-w: 1.6mm,
  row-h: 5.0mm,
  meta-cols: (4mm, 60mm, 8mm, 8mm, 8mm, 10mm),
) = {
  set page(paper: "a4", flipped: false, margin: (top: 10mm, bottom: 10mm, left: 10mm, right: 10mm))
  set text(font: "Times New Roman", size: 6pt)

  let n-days = n-weeks * 7
  let total-meta-w = meta-cols.fold(0mm, (a, b) => a + b)
  let total-gantt-w = n-days * day-w
  let sw-day(sw) = (sw - 1) * 7

  rotate(-90deg, reflow: true, {
    // title and info
    align(center)[
      #text(size: 11pt, weight: "bold")[#title]
      #h(4mm)
      #text(size: 7pt, fill: rgb("#555"))[
        SW 1–#n-weeks · Lukas Stöckli · Stand: #datetime.today().display("[day].[month].[year]")
      ]
    ]
    v(2mm)

    block(width: 100%, clip: false, {
      // header row 1: column titles + week headers
      let hdrs = ("ID", "Arbeitspaket / Meilenstein", "Start", "Ende", "Tage", "Stand")
      grid(
        columns: meta-cols + (total-gantt-w,),
        rows: (row-h,),
        ..range(meta-cols.len()).map(ci => box(
          width: meta-cols.at(ci),
          height: row-h,
          fill: col-header-bg,
          stroke: col-border + 0.4pt,
          inset: 2pt,
          align(center + horizon, text(fill: white, weight: "bold", size: 5.5pt, hdrs.at(ci))),
        )),
        // weekly header with alternating background for weeks and weekends
        box(width: total-gantt-w, height: row-h, fill: col-week-odd, stroke: col-border + 0.4pt, {
          for w in range(1, n-weeks + 1) {
            box(
              width: 7 * day-w,
              height: row-h,
              fill: if calc.rem(w, 2) == 1 { col-week-odd } else { col-week-even },
              stroke: col-border + 0.4pt,
              inset: 0.5pt,
              align(center + horizon, text(fill: col-week-text, weight: "bold", size: 5pt, "SW" + str(w))),
            )
          }
        }),
      )

      // header row 2: day numbers and weekend shading
      grid(
        columns: meta-cols + (total-gantt-w,),
        rows: (4mm,),
        box(width: meta-cols.at(0), height: 4mm, fill: col-meta-bg, stroke: col-border + 0.4pt, []),
        box(width: meta-cols.at(1), height: 4mm, fill: col-meta-bg, stroke: col-border + 0.4pt, inset: 1pt, align(
          left + horizon,
          text(size: 4.5pt, fill: rgb("#666"), "Start: " + _fmt(0, start-day, start-month, start-year)),
        )),
        ..range(2, meta-cols.len()).map(ci => box(
          width: meta-cols.at(ci),
          height: 4mm,
          fill: col-meta-bg,
          stroke: col-border + 0.4pt,
          [],
        )),
        box(width: total-gantt-w, height: 4mm, fill: white, stroke: col-border + 0.4pt, {
          let dns = ("M", "D", "M", "D", "F", "S", "S")
          for d in range(n-days) {
            let is-we = calc.rem(d, 7) >= 5
            let even-week = calc.rem(calc.quo(d, 7) + 1, 2) == 0
            box(
              width: day-w,
              height: 4mm,
              fill: if is-we { if even-week { col-we-even } else { col-we-odd } } else { white },
              stroke: col-border + 0.25pt,
              align(center + horizon, text(
                size: 3.2pt,
                fill: if is-we { rgb("#888") } else { rgb("#333") },
                dns.at(calc.rem(d, 7)),
              )),
            )
          }
        }),
      )

      // task rows
      for (i, task) in tasks.enumerate() {
        let (id, name, sw-s, sw-e, pct) = task
        let row-bg = if calc.rem(i, 2) == 0 { col-row-odd } else { col-row-even }
        let d-start = sw-day(sw-s)
        let d-end = sw-day(sw-e) + 6
        let n-td = d-end - d-start + 1
        let bar-total = n-td * day-w
        let bar-done = bar-total * pct / 100

        grid(
          columns: meta-cols + (total-gantt-w,),
          rows: (row-h,),
          box(width: meta-cols.at(0), height: row-h, fill: row-bg, stroke: col-border + 0.4pt, inset: 1pt, align(
            center + horizon,
            text(weight: "bold", size: 6pt, str(id)),
          )),
          box(
            width: meta-cols.at(1),
            height: row-h,
            fill: row-bg,
            stroke: col-border + 0.4pt,
            inset: (x: 2pt, y: 1pt),
            align(left + horizon, text(size: 5.5pt, name)),
          ),
          box(width: meta-cols.at(2), height: row-h, fill: row-bg, stroke: col-border + 0.4pt, inset: 1pt, align(
            center + horizon,
            text(size: 4.8pt, _fmt(d-start, start-day, start-month, start-year)),
          )),
          box(width: meta-cols.at(3), height: row-h, fill: row-bg, stroke: col-border + 0.4pt, inset: 1pt, align(
            center + horizon,
            text(size: 4.8pt, _fmt(d-end, start-day, start-month, start-year)),
          )),
          box(width: meta-cols.at(4), height: row-h, fill: row-bg, stroke: col-border + 0.4pt, inset: 1pt, align(
            center + horizon,
            text(size: 5pt, str(n-td) + "d"),
          )),
          box(width: meta-cols.at(5), height: row-h, fill: row-bg, stroke: col-border + 0.4pt, inset: 1pt, align(
            center + horizon,
            stack(dir: ttb, text(size: 5pt, weight: "bold", str(pct) + "%"), v(0.5pt), box(
              width: 7mm,
              height: 2pt,
              fill: rgb("#ddd"),
              stroke: col-border + 0.3pt,
              place(box(width: 7mm * pct / 100, height: 2pt, fill: if pct == 100 { col-bar-done } else { col-bar })),
            )),
          )),
          // gantt bar with background, progress and label
          box(width: total-gantt-w, height: row-h, fill: row-bg, stroke: col-border + 0.4pt, clip: true, {
            // Wochenstreifen + Wochenenden
            for d in range(n-days) {
              let is-we = calc.rem(d, 7) >= 5
              let w = calc.quo(d, 7) + 1
              let even-week = calc.rem(w, 2) == 0
              let bg = if is-we {
                if even-week { col-we-even } else { col-we-odd }
              } else if even-week { col-stripe } else { none }
              if bg != none {
                place(dx: d * day-w, dy: 0pt, box(width: day-w, height: row-h, fill: bg))
              }
            }
            // weekly grid lines
            for w in range(1, n-weeks) {
              place(dx: w * 7 * day-w - 0.25pt, dy: 0pt, line(
                start: (0pt, 0pt),
                end: (0pt, row-h),
                stroke: col-border + 0.6pt,
              ))
            }
            // bar background
            place(dx: d-start * day-w + 0.5pt, dy: row-h / 2 - 3pt, box(
              width: bar-total - 1pt,
              height: 6pt,
              fill: col-bar.lighten(50%),
              stroke: col-bar + 0.5pt,
              radius: 1.5pt,
            ))
            // progress bar
            if pct > 0 {
              place(dx: d-start * day-w + 0.5pt, dy: row-h / 2 - 3pt, box(
                width: calc.max(bar-done - 1pt, 0pt),
                height: 6pt,
                fill: if pct == 100 { col-bar-done } else { col-bar },
                radius: 1.5pt,
              ))
            }
          }),
        )
      }

      // legend
      v(3mm)
      grid(
        columns: (auto, 4mm, auto, 5mm, 4mm, auto, 5mm, 4mm, auto, 5mm, 4mm, auto),
        gutter: 2mm,
        align(horizon, text(size: 5.5pt, weight: "bold", "Legende:")),
        box(width: 4mm, height: 3mm, fill: col-bar, radius: 1pt),
        text(size: 5.5pt, "In Bearbeitung"),
        [],
        box(width: 4mm, height: 3mm, fill: col-bar-done, radius: 1pt),
        text(size: 5.5pt, "Abgeschlossen"),
        [],
        box(width: 4mm, height: 3mm, fill: col-we-odd, stroke: col-border + 0.3pt),
        text(size: 5.5pt, "Ungerade Semesterwochen"),
        [],
        box(width: 4mm, height: 3mm, fill: col-we-even, stroke: col-border + 0.3pt),
        text(size: 5.5pt, "Gerade Semesterwochen"),
      )
    })
  })
}
