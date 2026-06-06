
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
  protocol_number: "08",
  date: "22.05.2026",
  time: "13:00",
  room: "Online",
  location: "MS Teams",
  participants: "Prof. Dr. Aljosa Smolic, Lukas Stöckli",
  absentees: "Keine",
  for-information: "-",
  subject: "8. Meeting BAA",
  agenda: (current_agenda),
)

=== 1. #current_agenda.at(0)
Abgeschlossene Arbeiten seit der letzten Besprechung:
- Kapitel "Eigene Ideen" aus der Arbeit entfernt
- Hyperparameter-Tuning abgeschlossen:
  - Plain NN mit eigener Trainingspipeline aufgesetzt
  - Zusätzlich ein NN als Vergleich zu den ML-Modellen trainiert und getuned
- Ensemble-Modell aus NN, Random Forest und XGBoost erstellt:
  - Soft-Voting mit Confidence-Score: Die Wahrscheinlichkeiten der drei Modelle werden summiert und gemittelt
  - Vorhergesagt wird jene Klasse, bei der die Modelle gemeinsam am stärksten einverstanden sind
- Testdaten auf Basis Soft-Voting und XGBoost evaluiert:
  - Soft-Voting: 74%, XGBoost: 68%, Soft-Voting generalisiert besser
- Genauere Fehleranalyse der spannendsten Missklassifikationen mittels Random Forest und XGBoost durchgeführt
- Threshold-Analyse anhand des Confidence-Scores:
  - Erst ab einer label-spezifischen Konfidenz-Schwelle wird ein Label vorhergesagt, sonst wird die Vorhersage verworfen
- Demo-Modell fertiggestellt inklusive Feedback-Berichten (Excel und BCF)

=== 2. #current_agenda.at(1)
Mail vom Departement Wirtschaft:
- Hat sich aufgelöst, da eine andere Studentin ebenfalls eine Arbeit mit dem gleichen Praxispartner im Bereich Arbeitspsychologie verfasst

Allgemeine Fragen zur Abgabe:
- Web-Abstract soll eine Woche vor Abgabe an den Betreuer gesendet werden:
  - Abgabe bis Montag, 01. Juni (am Abend) genügt
  - Besprechung Ende derselben Woche (04. oder 05. Juni)
- Soll die Arbeit für Aljosa gedruckt und gebunden werden?
  - Eine digitale Abgabe als PDF genügt
- Pitching-Video:
  - Zusammenfassung und Übersicht über die gesamte Arbeit, Länge 2 - 3 Minuten
- Bis Montag, 01. Juni können folgende Vorabzüge an Aljosa gesendet werden:
  - Report (aktueller Arbeitsstand)
  - Web-Abstract
  - Pitching-Video als Script oder bereits eine Vorversion

Feedback von Aljosa zu Analysen und Ergebnissen:
- Bei den Analysen ein bis zwei Beispiele exemplarisch ausführen:
  - Es darf erwähnt werden, dass in tieferen Details weitere Analysen möglich wären, ohne diese abschliessend zu bearbeiten
  - Die einzelnen Fälle unbedingt auch visuell zeigen, damit die Daten besser einschätzbar werden
- Bei den Ergebnissen die Essenz der Analyse klar herausarbeiten:
  - Ein bis zwei vertiefte Beispiele in den Appendix legen
  - 3D-Beispiele im Appendix sind wertvoll, da sie alles grafischer darstellen

=== 3. #current_agenda.at(2)
- Schlussinterview mit Patrick (Praxispartner) am kommenden Mittwoch durchführen (inklusive Präsentation der Demo)
- Arbeit fertig schreiben:
  - Methoden ergänzen und gegebenenfalls kürzen
  - Kapitel Implementation schreiben
  - Kapitel Ergebnisse schreiben
  - Kapitel Ausblick schreiben
  - Abstract verfassen
- Gesamte Arbeit auf 50 Seiten kürzen
- Web-Abstract schreiben
- Pitching-Video erstellen
- Dataset für Kaggle vorbereiten und hochladen
- Projekt von GitLab auf GitHub migrieren
- Bugfixes am Typst-Template vornehmen
