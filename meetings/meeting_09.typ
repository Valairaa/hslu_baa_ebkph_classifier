
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
  protocol_number: "09",
  date: "05.06.2026",
  time: "14:00",
  room: "Online",
  location: "MS Teams",
  participants: "Prof. Dr. Aljosa Smolic, Lukas Stöckli",
  absentees: "Keine",
  for-information: "-",
  subject: "9. Meeting BAA",
  agenda: (current_agenda),
)

=== 1. #current_agenda.at(0)
Abgeschlossene Arbeiten seit der letzten Besprechung:
- Bericht und Web-Abstract fertig gestellt
- Schlussinterview mit dem Praxispartner (Patrick Muff) geführt und im Bericht integriert
- Arbeit fertig geschrieben
- Dataset auf Kaggle veröffentlicht
- Bugfixes am Typst-Template gelöst
- Bericht auf 50 Seiten gekürzt

=== 2. #current_agenda.at(1)
Feedback zum Pitching-Video:
- Das Pitching-Video sollte gemäss Reglement ca. 90 Sekunden dauern:
  - Es ist kein Abschlussbericht, sondern nur ein Teaser
- Die Ziele der Arbeit auf High-Level erklären:
  - Nicht die exakten Hypothesen vorlesen
  - Umgangssprachlich formulieren
- Bestätigung der Thesen am Schluss, ebenfalls umgangssprachlich, aber kurz halten
- Die Videos sind sehr ansprechend und sollten möglichst so belassen, allenfalls etwas gekürzt werden
- Am Montag vor der Schlusspräsentation (25. Juni 2026) findet ein Meeting mit Aljosa zur Vorbesprechung statt:
  - Aljosa meldet sich diesbezüglich noch

Anmerkungen zum Report:
- Keine, sieht gut aus

Anmerkungen zum Web-Abstract:
- Keine, sieht gut aus

=== 3. #current_agenda.at(2)
- Upload der Arbeit, des Web-Abstracts und des Pitching-Videos bis am 08. Juni 2026 (12:00 Uhr)
