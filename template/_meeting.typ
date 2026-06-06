#let protocol(
  protocol_number: "Protokollnummer",
  date: "Sitzungsdatum",
  time: "Zeit",
  room: "Raum",
  location: "Ort",
  participants: "Teilnehmer",
  absentees: "Abwesende",
  for-information: "Empfänger",
  subject: "Betreff",
  agenda: (),
  body,
) = {
  // document settings
  set document(title: "Protokoll")
  set page(
    paper: "a4",
    margin: (top: 3cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
    header: align(left, text(weight: "bold", size: 20pt, "Protokoll - Nr. " + protocol_number)),
    footer: text(size: 8pt)[
      #subject \ #location, #date \
      Seite #context counter(page).display("1/1", both: true)
    ],
  )
  set text(
    font: "Times New Roman",
    size: 12pt,
    lang: "de",
    region: "CH",
  )

  v(3cm)

  // set date and time
  grid(
    columns: (1fr, 1fr, 2fr),
    [
      #text("Sitzungsdatum:") \
      *#date*
    ],
    [
      #text("Zeit:") \
      *#time*
    ],
    [
      #text("Sitzungszimmer:") \
      *#room*
    ],
  )

  v(0.5em)

  // Participants
  text("Teilnehmende:")
  linebreak()
  strong(participants)

  v(0.5em)

  // Absentees
  text("Abwesende:")
  linebreak()
  strong(absentees)

  v(0.5em)

  // For Information
  text("Zur Kenntnisnahme:")
  linebreak()
  strong(for-information)

  v(1em)

  // Subject
  text(weight: "bold", subject, size: 15pt)

  v(1em)

  // Agenda
  text("Traktanden:")
  if agenda.len() > 0 {
    enum(..agenda.map(t => [#t]))
  }

  pagebreak()

  // Additional Content
  table(
    columns: (3fr, 1fr),
    stroke: none,
    [*Thema*], [* *],
    // Placeholder for tasks
  )

  body

  v(3em)

  text("Freundliche Grüsse \nLukas Stöckli")
}

// If tasks are needed on the right side of the protocol
#let topic(topic, taks) = {
  table(
    columns: (3fr, 1fr),
    stroke: none,
    topic, tasks,
  )
}

