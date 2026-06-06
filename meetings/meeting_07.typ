
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
  protocol_number: "07",
  date: "30.04.2026",
  time: "16:00",
  room: "Online",
  location: "MS Teams",
  participants: "Prof. Dr. Aljosa Smolic, Lukas Stöckli",
  absentees: "Keine",
  for-information: "-",
  subject: "7. Meeting BAA",
  agenda: (current_agenda),
)

=== 1. #current_agenda.at(0)
Abgeschlossene Arbeiten seit der Zwischenkritik:
- Neue Features ausgehend der Zwischenkritik entwickelt:
  - Materialeigenschaften der Bauelemente
  - Anzahl Elemente oberhalb und unterhalb horizontaler Elemente
- Heatmapanalyse der Features auf Labels erstellt
- PCA-Analyse der Features und Labels durchgeführt
- Split-Methode überarbeitet, um Data Leakage zu vermeiden:
  - Bisheriger Ansatz fokussierte zu stark auf gleichmässige Klassenverteilung, was dazu führte, dass Features über alle Splits hinweg identisch waren
  - Neu wird nach Projekt-ID gesplittet. D.h. Projekte kommen nur noch in einem Split vor
  - Features werden zwischen den Splits verglichen und alle Features welche im Training vorkommen, werden aus den anderen Splits entfernt um weiteren möglichen Data Leakage zu verhindern
    - Die Macro-F1-Score liegt neu bei ca. 70%, was plausibel ist
  - Verbleibendes Leakage Risiko: Wenn ein Element in zwei Projekten exakt dieselben Grössen hat, wird die Performance leicht überschätzt. Dies wird im Bericht entsprechend erläutert.
- Oversampling implementiert und mittels Schwellwertanalyse anzahl Duplikate definiert
- Performance-Analyse mit den Top-N Features durchgeführt:
  - Random Forest: 9 Features
  - XGBoost: 35 Features
- Weights & Biases für Hyperparameter-Tuning eingerichtet, Training läuft aktuell einwandfrei für ML-Modelle

=== 2. #current_agenda.at(1)
Allgemeine Fragen:
- Wie viel Projektmanagement soll in der Arbeit beschrieben werden?
  - Vorgehen bisher: klassisches Projektmanagement mit Meilensteinen und TODO-Listen, wöchentliche Reflexion
  - In Gruppen ist ausführliches Projektmanagement sinnvoll, aber für eine Einzelarbeit?
    - Nur dokumentieren, wie das Vorgehen war, prägnant halten im Kapitel Umsetzung
- Vorschlag von Adrian Willi zur Durchführung einer Umfrage zu Missklassifikationen:
  - Eine quantitative Umfrage wäre spannend, aber zeitlich nicht mehr realisierbar
  - Der Aufwand umfasst nicht nur die Umfrage selbst, sondern auch die Auswertung und die Einarbeitung in die Arbeit
  - Thema wird in den Ausblick aufgenommen und eine mögliche Umsetzung folgt wahrscheinlich nach der Abgabe
    - Im Ausblick ist der richtige Ort für die Eräwhnung und das passt so gem. Aljosa.
    - Es sollen aber Bilder der Geometrien in der Arbeit als Screenshots gezeigt werden, damit Missklassifikationen auch für Aussenstehende greifbar sind. Welche ich selbst analysiere.

Frage zu Bildunterschriften:
- In einer früheren Arbeit war das Ziel des Dozenten, sehr präzise und ausführliche Bildunterschriften zu verwenden
- Bevorzugt werden prägnante Bildunterschriften. Wie sieht das Aljosa?
  - Prägnant finde ich besser, dafür sollen Abbildungen im Fliesstext beschrieben werden.
    - Aljosa teilt diese Einschätzung: Bildunterschriften anpassen, nur bei Bedarf ausführlicher sein. Aber allgemein auch hier möglichst kurz und präzise halten.

Allgemeines Feedback von Aljosa:
- Ideen- und Konzeptabschnitte findet Aljosa auch schwierig und muss nicht enthalten werden. Es darf selbst entschieden werden, ob dieses Kapitel verwendet wird. Falls aber Themen dort vorkommen müssen es gute und starke Eigenideen sein.
  - Aljosa findet solche Abschnitte auch irreführend und widersorüchlich zu einer Forschungsarbeit
- Projektmanagement in der Umsetzung kurz erwähnen, nur das Vorgehen beschreiben, nicht wissenschaftlich ausarbeiten
- Inhalte komprimieren: Was ist für die Arbeit relevant, was nicht?
  - Nicht alle Heatmaps oder PCA-Plots zeigen. Beispielsweise eine Darstellung genügt und der Rest kann gut in den Anhang gelegt werden.
  - Aljosa wurde kurz der Arbeitsstand vom Report gezeigt
    - Er ist auch der Meinung, dass bereits zu viel vorhanden ist und Inhalte gestrichen werden sollten
    - Komprimieren ist wichtig, der aktuelle Stand sieht aber gut aus
    - Bei Bedarf können Seiten der Arbeit an Aljosa gesendet werden und er schaut sie an und gibt Rückmeldung, was auffällt und was nicht
- Bildunterschriften knackig halten, nur bei Bedarf mehr schreiben
- Der aktuelle Fortschritt ist ungewöhnlich weit für diesen Zeitpunkt, was positiv ist
  - Ansatz mit Typst findet er spannend und er wird es sich gerne anschauen

=== 3. #current_agenda.at(2)
- Kapitel Methode mit neuen Anpassungen und Ergänzungen fertigstellen
  - Korrekturvorschläge von Denise in die Arbeit einpflegen
- Kapitel Realisierung fertig schreiben, alles was bereits implementiert ist bei Umsetzung beschreiben
- Inferenzmodell entwickeln:
  - Filterung integrieren:
    - Schwellwertanalyse der Wahrscheinlichkeitsvorhersagen des Modells, damit nicht alle Elemente eine Klassifizierung erhalten. Weil beim Modell nichts mehr gesäubert wird.
    - Modell gibt Wahrscheinlichkeit aus, wie sicher es sich ist. Dieser Threshold wird zentral für die Analyse sein, damit das Modell nur die relevanten Elemente vorhersagt.
  - Falls zu wenig Elemente klassifiziert werden kann weiter nach nicht relevanten Entitäten gefiltert werden
  - Falls weiterhin zu viele Elemente klassifiziert werden kann weiter nach Ebenen wie Umgebung gefiltert werden, welche nicht relevant sind für die Kostenschätzung
- Feedbackreport mit BCF und Excel für das beste Inferenzmodell erstellen
  - Wenn möglich Solibri kompatibel
- Kapitel Ergebnisse schreiben (so visuell wie möglich):
  - Beispiel mit einem Dach für die Analyse verwenden und direkt mit ML Ergebnissen vergleichen
    - Zeigt, dass die Theorie verstanden wurde. Weniger Daten führen zu schlechterer Performance und das Modell erkennt Muster zu wenig
  - Fokus auf die Analyse der Resultate legen, da dies der Kern der Arbeit ist
  - Spannende Zusammenhänge aufzeigen, keine Vermutungen ohne Grundlage
    - Optional: Entscheidungsbäume bei einzelnen exemplarischen Beispielen anschauen
  - Fehleranalyse einzelner Beispiele durchführen, ggf. in den RF-Baum gehen um die Entscheide nachzuvollziehen und Fehler zu erkennen
- Schlussinterview vorbereiten und durchführen:
  - Erstes Interview als PDF und in Typst aufschreiben
  - Fragen für das Schlussinterview mit Patrick entwickeln
