
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
  protocol_number: "02",
  date: "05.03.2026",
  time: "16:00",
  room: "Online",
  location: "MS Teams",
  participants: "Prof. Dr. Aljosa Smolic, Lukas Stöckli",
  absentees: "Keine",
  for-information: "-",
  subject: "2. Meeting BAA",
  agenda: (current_agenda),
)

=== 1. #current_agenda.at(0)
Abgeschlossene Arbeiten:
- Projekttemplate erstellt und auf GitLab hochgeladen
- Aufgabenstellung präzisiert, mit Aljosa abgestimmt und auf Complesis geladen
- Literaturrecherche abgeschlossen (60 Literaturquellen)
- Hypothesen grob formuliert
- Terminprogramm erstellt
- Präsentation des aktuellen Stands

=== 2. #current_agenda.at(1)
- Arbeitsweise und Erwartungen von Aljosa: Passt so wie bisher.
- Arbeitsjournal: Muss formal nicht geführt werden, kann aber für eigene Zwecke genutzt werden.
- Abgrenzung in der BAA-Arbeit:
  - Abgrenzungen dürfen in allen Kapiteln erfolgen, nicht nur in einem separaten Kapitel.
  - Wichtig: Abgrenzungen begründen und schlüssig argumentieren, warum ein Thema nicht weiter verfolgt wird.
- Ungelöste Probleme gehören in den Ausblick.
- Persönliche Reflexion: Nicht notwendig, gehört nicht in eine wissenschaftliche Arbeit.
- Protokollversand nach Sitzungen: Nicht nötig, Protokoll schreiben aber nicht versenden.
- Interviews:
  - Fokus zunächst auf Patrick (Interne Expertise): Interview zur Problemdefinition (1–2 Sätze in der Arbeit), später Lösung zeigen und Rückmeldung in Ergebnisse einfliessen lassen.
  - Keine User Study erstellen, da man sich sonst angreifbar macht.
- PointNet, MVCCN, Deep Neural Networks: Zuerst auf ML-Modelle konzentrieren, weiterführende Netzwerke nur bei verbleibender Zeit, da sie bereits bereits in sich eigene komplexe Themen sind.

=== 4. #current_agenda.at(2)
- Hypothese weiter präzisieren
- Einführung der Arbeit schreiben
- State of the Art schreiben
- eBKP-H Mapping einheitlich erstellen als Excel-Mapping
  - Wo gibt es Clustergruppen welche gruppiert werden können?
- Datenset zusammenstellen
  - Datenset aus allen Modellen erstellen
  - Datenset für Labels erstellen
  - Datenset mit Labels und Featuers zusammenführen
  - Datenanalyse durchführen
  - Features aus IFC extrahieren
  - DQA durchführen

