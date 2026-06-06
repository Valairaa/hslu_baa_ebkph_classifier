
#import "/template/_meeting.typ": protocol
#import "/template/_helpers.typ": todo

// Define the meeting points
#let current_agenda = (
  "Projektübersicht und Datengrundlage",
  "Zeitraum der Arbeit",
  "Ziel der Arbeit",
  "Wünsche und Anregungen des Auftraggebers",
)

// Information for the meeting
#show: protocol.with(
  protocol_number: "01 - GKS",
  date: "03.02.2026",
  time: "11:00",
  room: "Celeste",
  location: "Luzern",
  participants: "Patrick Muff, Lukas Stöckli",
  absentees: "Keine",
  for-information: "-",
  subject: "1. Interview mit Praxispartner",
  agenda: (current_agenda),
)

=== 1. #current_agenda.at(0)
- Von GKS Architekten AG werden insgesamt 13 Projekte zur Verfügung gestellt.
  - 8 Projekte mit vollständiger Kostenermittlung durch Patrick: KEHO, LUMU, RALU, GERB, GSRH, ADEM, KEPR und ESAK
  - 5 Projekte mit kontrollierter Modellqualität ohne Kostenschätzung: ZUST, CHLI, IMBU, BRUT und ZEGA

=== 2. #current_agenda.at(1)
- Start der Bachelorarbeit: 16. Februar 2026
- Zwischenpräsentation: im April 2026
- Abgabetermin: 8. Juni 2026
- Bearbeitungsdauer: 14 Wochen
- Schlusspräsentation: Ende Juni 2026

=== 3. #current_agenda.at(2)
- Hauptziel: Klassifikation der Bauelemente ausschliesslich basierend auf der Geometrie.
  - Falls die Geometrie alleine nicht ausreicht, können automatisch verfügbare Hilfsattribute wie die "IFC Entität" oder die Materialisierung zusätzlich einbezogen werden.
- Ermittlung und Qualitätssicherung der Information der Bauteile steht im Zentrum der Arbeit, da sie als zusätzliches Intrument für eine Kontrolle der Modellqualität dienen soll.
- Erstellung einer BCF-Datei für die Anomalieprüfung, sodass die identifizierten Auffälligkeiten direkt im ArchiCAD nachvollzogen werden können.

=== 4. #current_agenda.at(3)
- Die Inferenzzeit ist sekundär: Auch bis zu drei Stunden für eine Prüfung pro Modell sind akzeptabel, sofern dadurch die Performance der Modelle steigt.
- Die Genauigkeit der Modelle soll Vorrang vor der Inferenz haben.
- Die Rückmeldung an die Modellierenden ist zentral:
  - Nicht nur den Fehler benennen, sondern auch helfen zu verstehen, worin der Fehler besteht.
  - Möglichst plausibilisierende Information zu jeder Falschklassifikation mitliefern.
- Wenn es innerhalb der Arbeit möglich ist, wäre ein System zur iterativen Modellverbesserung sinnvoll:
  - Die Fachpersonen könnten so pro Vorhersage angeben, ob diese korrekt oder falsch ist.
  - Die so gesammelten Bewertungen könnten für ein erneutes Training verwendet werden, um das Modell schrittweise zu verbessern.

