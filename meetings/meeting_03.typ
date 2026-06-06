
#import "/template/_meeting.typ": protocol
#import "/template/_helpers.typ": todo

// Define the meeting points
#let current_agenda = (
  "Aktueller Arbeitsstand",
  "Offene Fragen / Projektdetails",
  "Nächste Arbeiten / Pendenzen",
)

// Information for the meeting
#show: protocol.with(
  protocol_number: "03",
  date: "20.03.2026",
  time: "13:00",
  room: "Online",
  location: "MS Teams",
  participants: "Prof. Dr. Aljosa Smolic, Lukas Stöckli",
  absentees: "Keine",
  for-information: "-",
  subject: "3. Meeting BAA",
  agenda: (current_agenda),
)

=== 1. #current_agenda.at(0)
Abgeschlossene Arbeiten:
- State of the Art geschrieben
- Daten gesammelt und als Datenset erstellt
- Labels als Datenset erstellt
- Labels und Daten gemerged basierend auf GUID, Modellname
- Erste Datenvisualisierung der Daten erstellt

=== 2. #current_agenda.at(1)
- Das Datum der Zwischenpräsentation ist am Nachmittag, 23. April 2026
- Das Ziel und die Klassifikationsstrategie muss klar definiert sein
  - Vergleich: eBKP-H direkt predicten vs. zuerst Labels predicten?
    - Vor- und Nachteile beider Ansätze evaluieren
- Die Herzarbeit liegt in der Data Curation / Feature Extraction
  - Vergleichen was funktioniert, was nicht und was in den Daten fehlt damit es funktionieren kann
  - Allgemeine Frage: Wie müssen die Daten bereitgestellt werden, um einen ML-Workflow zu garantieren?
  - Vorgehen in der Arbeit schlüssig zeigen und dokumentieren
- Der Vergleich der Modellperformance ist wichtig
  - Modelle mit allen Daten trainieren und zusätzlich mit gefilterten, normalisierten Daten
  - Damit wird ersichtlich, wieso die Datenkuration die Performance verbessert

=== 3. #current_agenda.at(2)
- eBKP-H Mapping einheitlich erstellen als Excel-Mapping für eine bessere Übersicht
  - Damit kann später eine Klassifikation rückgeschlossen oder gemacht werden
- DQA / Anreicherung des Datensets
  - Pro eBKP-H Code eine Spalte machen und den Elementen zuweisen
  - eBKP-H Code in Hierarchien aufsplitten (Level 1, Level 2, ausgeschriebenen Namen)
  - Clustergruppen danach identifizieren
  - Label-Features aus IFC extrahieren, welche für Klassifikation benötigt werden
  - Geometrische Features dem Datenset dazufügen
  - Features für das Training extrahieren (Dataloader entwickeln)
  - DQA durchführen
- Zeitplan
  - Bis Ende Ostern: Daten bearbeitet und kuriert
  - Ab Ostern bis Midterm: Erste Tests und KI-Modelle trainiert haben
    - Damit Vergleiche zwischen den Modellen möglich sind

