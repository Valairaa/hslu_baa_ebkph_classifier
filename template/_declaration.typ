
#let declaration(
  title: none,
  authors: (),
  advisor: none,
  external_expert: none,
  industry_partner: none,
  degree_program: none,
  graduation_date: none,
  confidential: none,
  signature_date: none,
  signature_place: none,
  university: none,
  division: none,
) = {
  let german_months = (
    "Januar",
    "Februar",
    "März",
    "April",
    "Mai",
    "Juni",
    "Juli",
    "August",
    "September",
    "Oktober",
    "November",
    "Dezember",
  )
  let format_date_de = date => {
    [#date.display("[day]"). #german_months.at(date.month() - 1) #date.display("[year]")]
  }

  [== Bachelorarbeit an der #university -  #division]

  let name_of_student = "Name of Student"
  if (authors.len() > 0) {
    name_of_student = name_of_student + "s"
  }

  table(
    columns: 2,
    stroke: none,
    row-gutter: 1.0em,
    column-gutter: 3em,
    [#v(2.5em)*Titel:*], [#v(2.5em)#title],
    [*Student:*], [#authors.map(a => a.name).join(" \ ")],
    [*Studiengang:*], [#degree_program],
    [*Jahr:*], [#graduation_date.display("[year]")],
    [*Betreuungsperson:*], [#advisor],
    [*Expertenperson:*], [#external_expert],
    [*Auftraggeber:*], [#industry_partner],
  )

  [
    #v(5em)*Codierung / Klassifizierung der Arbeit:*\
    #if (confidential) {
      [
        ⬜ Öffentlich (Normalfall)\
        ☑ Vertraulich
      ]
    } else {
      [
        ☑ Öffentlich (Normalfall)\
        ⬜ Vertraulich
      ]
    }



    #v(5em)*Eidesstattliche Erklärung*\
    Ich erkläre hiermit, dass ich die vorliegende Arbeit selbständig und ohne unerlaubte fremde Hilfe angefertigt habe. Alle verwendeten Quellen, Literatur und Hilfsmittel (insbesondere künstliche Intelligenz oder sonstige verwendete Instrumente) wurden urheberrechts- und datenschutzkonform verwendet und wörtlich oder inhaltlich entnommene Stellen als solche kenntlich gemacht. Das Vertraulichkeitsinteresse des Auftraggebers wurde gewahrt und die Urheberrechtsbestimmungen der Hochschule Luzern respektiert.


    #stack(
      grid(align: bottom + center, columns: (2fr, 4.7fr))[
        #signature_place, #if (signature_date != none) { format_date_de(signature_date) }
      ][
        #v(6em)
      ],
      spacing: .5em,
      line(length: 100%, stroke: (thickness: .5pt)),
      "Ort / Datum, Unterschrift",
    )
  ]
}
