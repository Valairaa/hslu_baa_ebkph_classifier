#import "/template/_helpers.typ": title-caption, todo
#import "@preview/acrostiche:0.7.0": acr

== Beispiele

Das ist eine Zitierung / Referenzierung @pishdad_analysis_2024. #cite(<pishdad_analysis_2024>, form: "prose") oder einfach eine Inline-Zitierung oder wenn man mehrere Quellen zitieren möchte #cite(<pishdad_analysis_2024>, <another_source_2023>).

Sie können auch auf Überschriften verweisen auf Tabellen @T:table und so weiter.

#todo("TEST")

Fussnoten sind auch ziemlich einfach#footnote[https://www.grammarly.com/].

Sie können Akronyme wie #acr("CSV") für den vollständigen Namen verwenden. Dies erscheint dann in der Abkürzungsliste. Oder einfach aber nur #acr("BIM")

== Ein Untertitel

#lorem(20)

=== Ein Unteruntertitel

#lorem(20)

==== Ein Unterunteruntertitel

Ich würde nicht empfehlen, tiefer zu gehen als dies.

#figure(
  table(
    columns: 2,
    table.header([Kopfzeile 1], [Kopfzeile 2]),

    [Zeile 1, Spalte 1], [Zeile 1, Spalte 2],
  ),
  caption: title-caption(
    [Dies ist ein Tabellenunterschrift-Titel],
    [Dies ist ein wirklich laaaaaaaaaaaaaaaaaaaaaanger Tabellenunterschrift-Text. Dieser wird nicht im Tabellenverzeichnis angezeigt.],
  ),
)<T:table>

#figure(
  kind: math.equation,
  $ R^2 = 1 - frac("SS"_(R E S), "SS"_(T O T)) = 1 - frac(sum_i (y-hat(y)_i)^2, sum_i (y-macron(y)_i)^2) $,
  caption: "Dies ist ein Gleichungstitel",
)


Wie man sehen kann, werden Abbildungsnummern automatisch entsprechend dem Kapitel generiert, in dem sie sich befinden:
#figure(
  table(
    columns: 2,
    table.header([Überschrift 1], [Überschrift 2]),
    [Zeile 1, Spalte 1], [Zeile 1, Spalte 2],
  ),
  caption: title-caption(
    [Dies ist ein Tabellenbeschriftungstitel],
    [Dies ist ein wirklich laaaaaaaaaaaaaaaaaaaaaanger Tabellenbeschriftungstext. Dieser wird nicht in der Abbildungsliste angezeigt.],
  ),
)<T:table2>
