
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
  protocol_number: "05",
  date: "17.04.2026",
  time: "15:00",
  room: "Online",
  location: "MS Teams",
  participants: "Prof. Dr. Aljosa Smolic, Lukas Stöckli",
  absentees: "Keine",
  for-information: "-",
  subject: "5. Meeting BAA",
  agenda: (current_agenda),
)

=== 1. #current_agenda.at(0)
Abgeschlossene Arbeiten:
- DQA und Feature Extraktion in der Arbeit niederschreiben
- Threshold-Analyse für untervertretene Klasse erstellt
- Erste Versuche mit den Baseline-Modellen machen
  - Vorerst MultiOutputClassifier trainieren, d.h. pro Feature gibt es ein ML-Modell
  - Performance analysieren zwischen Baseline-Modellen
  - Feature Importance visualisieren
  - Zwischenpräsentation vorbereiten für das nächste Meeting

=== 2. #current_agenda.at(1)
Feedback zur Arbeit und Präsentation:
- Es genügt 1 bis 2 Thesen; nur darauf konzentrieren und nicht mehr machen
  - Ansonsten gibt es zu viele Methoden und die Arbeit ist nicht fokussiert auf den Hauptteil
  - Für die Hauptthese können natürlich auch Unterthesen formuliert werden
- Auf das Wichtigste fokussieren, nicht zu viel zeigen und Themen nur ansprechen, aber nicht ausdiskutieren
  - Es gibt danach sowieso eine Diskussion, die braucht auch Themen
- Wichtig ist die Analyse: Alles, was analysiert und Rückschlüsse gezogen werden kann, soll in der Analyse miteinfliessen
  - Beispiel Roof: nur ca. 40 Elemente, davon die Hälfte falsch klassifiziert → zu wenig Daten vorhanden; das auch für andere Arbeiten so festhalten
  - Als Bestätigung zum maschinellen Lernen (Proof of Concept) wichtig, da es die Grundthemen von Machine Learning bestätigt
- DQA erwähnen und hervorheben, dass es ein Hauptpunkt war und Praxisdaten (keine theoretischen Daten) verwendet wurden
- Trick: viele Inhalte nur kurz ansprechen und weiterführende Themen in den Anhang auslagern, damit der Hauptteil fokussiert bleibt und nur Projektrelevantes erzählt wird
- Features nur schnell erklären

=== 3. #current_agenda.at(2)
- Präsentation am Schluss kurz an Aljosa senden, damit er prüfen kann, was noch gekürzt werden kann
- Nächsten Termin in der kommenden Woche vereinbaren (Aljosa ab dem 1. Mai in den Ferien)
- Aufgrund der Feature Importance Liste nur die wichtigsten 3 Features trainieren
- XBBoost fehler suchen
- Hyperparamter-Tuning mit Random Forest
- Training Random Forest Modell bei selektierten Features auf Basis der Feature Importance Matrix
- Hyperparameter-Tuning beim Random Forest Modell
- Analyse XGBoost, wieso es schlechter als RF ist und eine längere Trainingszeit hat? Erweiterung um LightGBM
- Fehleranalyse kostenrelevanter Bauteile
- Entwicklung Zuweisungsmatrix eBKP-H mit den prognostizierten Labels
- Werden Logikregeln gebraucht? Wenn ja, welche? Da nicht alle Labels nach aktuellem Datensatz sinnvoll sind.
- Entwicklung Feedbackdokumente (Excel, BCF)
- Präsentation der Ergebnisse inkl. Interview bei GKS Architekten AG


