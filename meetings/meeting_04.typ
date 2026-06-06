
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
  protocol_number: "04",
  date: "02.04.2026",
  time: "14:00",
  room: "Online",
  location: "MS Teams",
  participants: "Prof. Dr. Aljosa Smolic, Lukas Stöckli",
  absentees: "Keine",
  for-information: "-",
  subject: "4. Meeting BAA",
  agenda: (current_agenda),
)

=== 1. #current_agenda.at(0)
Abgeschlossene Arbeiten:
- Zuweisungsmatrix fertig erstellt aus den diversen Excel Dateien
- Labels extrahiert und analysiert
- ArchiCAD Features extrahiert und analysiert
  - Sind zu wenige vorhanden und werden als Input ausgeschlossen
- Geometrische Features extrahiert und analysiert
  - Allgemeine Features
  - AABB Features
  - TFBB Features
  - Topologische Features
- Duplikate wurden auf Basis der geometrischen Features entfernt
- Daten wurden an Normalverteilung angeglichen (wichtig für KNN, SVM)
- Datenset für Training, Validierung und Tests erstellt

=== 2. #current_agenda.at(1)
- Wie viel Zeit habe ich als Präsentation für die Zwischenpräsentation? 20 Minuten?
  - Die Präsentation sollte zwischen 15-20 Minuten sein
  - Sie soll gesamtheitlich aber kompakt sein

=== 3. #current_agenda.at(2)
- DQA und Feature Extraktion in der Arbeit niederschreiben
- Erste Versuche mit den Baseline-Modellen machen
  - Vorerst MultiOutputClassifier trainieren, d.h. pro Feature gibt es ein ML-Modell
  - Performance analysieren zwischen Baseline-Modellen
  - Feature Importance visualisieren
  - Aufgrund der Feature Importance Liste nur die wichtigsten 3 Features trainieren
- Zwischenpräsentation vorbereiten für das nächste Meeting
- XBBoost weiter trainieren
- Hyperparamter-Tuning mit Tracking der Performance (Wandb)
- Simultane ML-Modelle versuchen (multilabel classifiers), welche simultan über mehrere Klassen die Labels vorhersagen

