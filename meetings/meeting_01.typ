
#import "/template/_meeting.typ": protocol
#import "/template/_helpers.typ": todo

// Define the meeting points
#let current_agenda = (
  "Pitch-Präsentation",
  "Aufgabenstellung",
  "Offene Fragen / Projektdetails",
  "Organisatorisches",
  "Nächste Arbeiten / Pendenzen",
)

// Information for the meeting
#show: protocol.with(
  protocol_number: "01",
  date: "20.02.2026",
  time: "14:00",
  room: "Suurstoffi 12, 12.017 - 10",
  location: "Rotkreuz",
  participants: "Prof. Dr. Aljosa Smolic, Lukas Stöckli",
  absentees: "Keine",
  for-information: "-",
  subject: "Kick-off Meeting BAA",
  agenda: (current_agenda),
)

=== 1. #current_agenda.at(0)
Pitch wird durch Lukas präsentiert.

=== 2. #current_agenda.at(1)
- Die Bewertung der Bachelorarbeit erfolgt anhand der Aufgabenstellung
- Aufgabenstellung wird genauer präzisiert und anschliessend mit Aljosa abgestimmt
  - Quantifizierbare Ziele bei der Zielformulierung integrieren
  - Hypothese bei der Zielformulierung integrieren
  - Gewünschte Methoden und Vorgehen sind weiter zu präzisieren

=== 3. #current_agenda.at(2)
- Beim Projektmanagement ist das Vorgehen frei wählbar
- Quellen müssen nach APA7 formatiert und angegeben werden
  - Die Seitenanzahlen der referenzierten Abschnitte müssen im Text nicht angegeben werden
- Vorhandenes Experteninterview bereits in der Arbeit deklarieren und die Thesis damit untermauern
- Literaturrecherche soll einen breiten Überblick über die aktuelle Forschungslage geben
  - Anschliessend ist zu definieren, wieso welcher Ansatz gewählt wurde und wieso andere Ansätze nicht gewählt wurden
- Einfachere Modelle sind ausreichend für die Bachelorarbeit
  - Fortgeschrittene Modelle wie GNN, PointNet oder Dynamic Graph CNN können im Ausblick erwähnt werden, würden aber den Rahmen der Bachelorarbeit sprengen
- Als Geometrie-Anreicherung Bounding Boxes verwenden
  - Transformationen zu Mesh- oder Voxelgeometrien sowie Punktwolken würden den Rahmen der Bachelorarbeit sprengen, können aber im Ausblick erwähnt oder bei vorhandener Zeit angegangen werden
- Experteninterviews sind wertvoll für die Bachelorarbeit
  - Zusätzlich zu den numerischen Ergebnissen können Experteninterviews die Arbeit untermauern und ihr mehr Gewicht verleihen
  - Wenn möglich, mit 3–4 Personen Experteninterviews führen, um die Ergebnisse und die Bedürfnisse zu validieren

=== 4. #current_agenda.at(3)
- Lukas wird voraussichtlich am 1. Mai das zweite Mal Vater
  - Wenn möglich, ist der Termin der Zwischenpräsentation in der Woche 8 oder 9 anzusetzen. Damit das Risiko minimiert wird, dass die Zwischenpräsentation verschoben werden muss.

=== 5. #current_agenda.at(4)
- Hypothese und Forschungsfrage weiter präzisieren
- Aufgabenstellung präzisieren und anschliessend an Aljosa zur Kontrolle per Mail senden
- Wochenplan und Aufgabenpakete definieren
- Literaturrecherche weiterführen
- Einführung der Arbeit schreiben
- Daten zusammenstellen und bereits Mapping für korrekte Labels erzeugen
- Rohling von State of the Art erstellen

