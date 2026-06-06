
#import "/template/_meeting.typ": protocol
#import "/template/_helpers.typ": todo

// Define the meeting points
#let current_agenda = (
  "Notizen",
  "Feedback",
  "Aktuelle Fragen Dozenten",
  "Nächste Arbeiten / Pendenzen",
)

// Information for the meeting
#show: protocol.with(
  protocol_number: "06",
  date: "23.04.2026",
  time: "16:00",
  room: "Suurstoffi 12, 12.017 - 10",
  location: "Rotkreuz",
  participants: "Prof. Dr. Aljosa Smolic, Adrian, Willi, Lukas Stöckli",
  absentees: "Keine",
  for-information: "-",
  subject: "Zwischenkritik BAA",
  agenda: (current_agenda),
)

=== 1. #current_agenda.at(0)

- Der aktuelle Arbeitsstand ist gut, es gibt aber noch diverse Unklarheiten im Projekt. Besonders ist der Fokus auf Eigenleistungen zu legen.
- Abgrenzung gut und soll in der Arbeit vermerkt werden: Wieso ML-Modelle und wieso keine Transformer-Netzwerke gewählt wurden?
- Eigenleistungen zeigen ist wichtig, der Fokus sollte mehr auf Eigenleistungen sein. Bis jetzt zu wenig vorhanden.
- Adrian Willi findet es gut, dass als Kernthema ML gewählt wurde und nicht ein CNN- oder Transformerarchitektur.
- Der Code wird auch abgegeben und bewertet.
  - Adrian Willi bevorzugt Code mit möglichst keinen Notebooks. Ist aber mir überlassen wie ich es in meiner Arbeit will.
- Wenn keine Modelle oder Daten abgegeben werden, dann müssen mindestens Samples abgeben werden. Damit man ein Gespür für die Daten bekommt. -> (anonymisiertes Sample, damit man die Daten spürt)
- Generalisierung der Daten wichtig, die Performance der Modelle ist gem. Adrian Willi overfittet
  - Analyse als Experte oder als Laye als spannender Punkt für Missklassifikationen mit 3D-Bild der Elemente aus dem Solibri: Analysieren warum unterscheiden sich die Elemente. Können Laien oder Experten anhand des Bildes auch die Differenzierung machen. Wenn nein, wieso soll es das das ML-Modell unterscheiden können?
  - Modelle genügen in der Anzahl. Es gibt wichtigere Themen, welche zuerst angegangen werden sollen.
- Manuelle Analysen der Elemente zeigen, wie sich diese verhalten (im Anhang Beispiele als Bilder beilegen, wie beispielsweise ist es eine Decke oder eine Tür?)
- Mathew-Korrelation anschauen, wird von Adrian Willi empfohlen und ist sehr sensitiv als Metric, was beim Projekt hilft.
- Korrelation der Features machen, sie sollten zum Teil stark korrelieren. Da die Performance der Modelle sehr gut sind.
- Subsample der IFC-Modelle nehmen und schauen, wie gut es performt (auch ohne Cleaning, welche unknown sind oder nicht wichtig?)
  - Ein Projekt nehmen, welches eher exotischer ist und nicht viel vorkommt in den Daten um die Generalisierung des Modells zu prüfen

=== 2. #current_agenda.at(1)

- Die Arbeit kompakt schreiben, sehr viel Informationen auf kurze Sätze vereinen.
  - 50 Seiten mit Bildern sind sehr viel, maximal bei dieser Begrenzung bleiben. Die Kunst ist es, viel Informationen komprimiert zu schreiben.
- Unterschiede in den Daten zeigen, wo gibt es Missklassifikationen und wieso? Diverse Analysen sind sehr wichtig für die Arbeit, auch bildlich darstellen.
- Fokus auf eigene kreative Umsetzungen: Unterschiede mathematisch oder visuell zeigen.
  - Alles in den Anhang was möglich ist um die Daten zu zeigen wie auch einen Ausschnitt. Das ist für das Gefühl der Daten wichtig und nicht für die Bewertung der Arbeit
- Spannend wäre eine kurze Analyse. Können die Missklassifikationen der 3D Objekte auch Laien oder Experten visuell zuordnen?
- Plain NN mal machen zum Trainieren, um zu sehen wie gut es ist (optional, falls Zeit bleibt)
- Hyperparameter-Tuning mit Weights and Biases machen. Adrian Willi empfiehlt es mit Sweeps. Das Tracking der Trainingszeit und der Trainingsmetrics nicht vergessen.
- Pro Label eine PCA-Analyse durchführen mit den Features um zu sehen, welche Features miteinander korrelieren und irrelevant sind
- Subsampling / Anonymisierung der Daten als Vorschlag
  — damit man die Daten sieht aber nicht das gesamte Wissen der Firma preisgibt
- Unbedingt ein Expertengespräch, durchführen damit man sieht, wie brauchbar das Modell in der Praxis ist
- Eigene Metriken (ausmassbasiert) sind begrüssenswert, da grösseres Ausmass auch eine grössere Kostenrelevanz bedeutet. Jedoch einfach halten und nicht zu viel Zeit investieren.
- Weitere Features wie die Neigung der Elemente oder Materialisierung der Elemente sind zu begrüssen bis zur Abgabe der Arbeit als Eigenleistung
- Bis zu zwei Seiten dürfen an Adrian Willi vorab gesendet werden, damit es einen Eindruck vom Schreibstil hat und Feedback diesbezüglich geben kann. Sollte maximal zwei Wochen vor der Abgabe passiert sein.
- Alle Themen, welche in der Arbeit nicht gelöst werden konnten in den Ausblick nehmen und dort erwähnen.

=== 3. #current_agenda.at(2)

- Warum unterscheiden sich die Bauelemente. Was macht das ML-Modell anders als ein Mensch? Wie kann man das zeigen?
- Verhalten bei ungesehenen Daten / Praxistauglichkeit: Wie wird das Modell vorhersagen, wenn kein DQA durchegeführt wurde? Wie kann das Problem behoben werden?
- Overfitting allgemein als Thema anschauen und sorgfältig analysieren
  - Clipping ist einfach, aber auch bei wenigen Daten nicht sinnvoll
  - Oversampling oder synthetische Daten für das Training wären spannend. Trotzdem abwägen wie sinnvoll es ist, nicht damit synthetische Muster gelernt werden.
- Die Modelle kommen in der Finanzbranche meistens maximal auf 60% mit dem Noise und der Skewness der Daten. Deshalb gut überprüfen, ob ein Data Leak oder Bug im Code vorhanden ist.
  - Features PCA-Cluster anschauen, ob sie trennbar sind oder dort bereits ein Leakage erkannt wird und durch die Korrelation der Features die Validierungsdaten zu ähnlich sind? D.h. nicht so gut generalisieren.
- Im Experteninterview fragen, welchen Einfluss hätte Fehler es auf die Kosten? Oder wie kostspielig waren die Fehler basierend auf der Kostenschätzung?

=== 4. #current_agenda.at(3)

- Mathew-Korrelation als Metric einbauen
- Weitere Features als Eigenleistung entwickeln
- Korrelation der Features untersuchen
- PCA pro Label durchführen und Features-PCA-Cluster anschauen
- Mehr Daten synthetisch herstellen oder Oversampling in Betracht ziehen, wenn möglich
- Kernthema für die folgenden 6 Wochen: Aussagekräftige Analysen machen und aufzeigen, wie gut das Modell performt mit weniger Features
  - Missklassifikationen im Random Forest Baum analysieren
    - Welche Elemente sind falsch? Wieso? Welche Schwellwerte führen dazu?
  - Manuelle Analysen der Elemente machen und im Anhang zeigen
    - Am besten mit Laien und Experten
  - Subsample der IFC-Modelle nehmen und ohne Cleaning predicten. Wie verhält sich das Modell?
- Anonymisiertes Sample aus Code abgeben
- Bei Willi nachfragen, wie er die Qualität der Arbeit findet und was verbessert werden kann (Sample mit zwei Seiten, zwei Wochen vor der Abgabe.)

