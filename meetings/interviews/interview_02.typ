
#import "/template/_meeting.typ": protocol
#import "/template/_helpers.typ": todo

// Define the meeting points
#let current_agenda = (
  "Vorstellung des aktuellen Arbeitsstands",
  "Live-Demonstration auf dem Projekt LUMU",
  "Fragen zu den Feedback-Berichten",
  "Fragen zur Praxistauglichkeit und Erweiterungswünsche",
)

// Information for the meeting
#show: protocol.with(
  protocol_number: "02 - GKS",
  date: "27.05.2026",
  time: "13:30",
  room: "Online",
  location: "MS Teams",
  participants: "Patrick Muff, Lukas Stöckli",
  absentees: "Keine",
  for-information: "-",
  subject: "2. Interview mit Praxispartner",
  agenda: (current_agenda),
)

=== 1. #current_agenda.at(0)
- Es werden die gewählten Methoden und Arbeitsschritte der Arbeit durch Lukas präsentiert:
  - Daten werden neu pro Projekt sauber getrennt, damit sich Trainings-, Validierungs- und Testset nicht mehr überschneiden.
  - Hyperparameter-Tuning der drei Basismodelle Random Forest, XGBoost und MLP.
  - Soft-Voting-Ensemble über die getunten Basismodelle als finales Vorhersagemodell.
  - Confidence-Analyse zur Herleitung label-spezifischer Konfidenz-Schwellwerte.
  - Resultate des finalen Modells auf den Testdaten als Grundlage für die Demo-Validierung.
- Für die Abgabe der Arbeit genügt dem Auftraggeber ein digitaler Print (PDF).

=== 2. #current_agenda.at(1)
- Die Demo-Pipeline ("run_demo.py") wird am Testprojekt "LUMU" vorgeführt. Das Projekt war während des gesamten Trainings unsichtbar und dient als realistische Praxisprüfung.
- Gemeinsame Inspektion der Fehlklassifikationen im Solibri, um die Auffindbarkeit der betroffenen Bauelemente und die Aussagekraft der BCF-Topics in der gewohnten Prüfumgebung zu beurteilen.
  - Die Strukturierung und Darstellung der BCF-Issues überzeugten.
  - Gemeinsam wurde erkannt, dass das Demo-Modell Decken, heruntergehängte Decken und Dächer nicht gut voneinander unterscheiden kann. Auch bei den modellierenden Personen liegt bei diesen Elementen eine grosse Fehlerquelle. Bei den ersten Modellen im Projekt, welche durch Patrick kontrolliert werden, sind diese Elemente oft durch die modellierenden Personen falsch informiert.
  - Die Missklassifikationen der Waschbecken und anderer sanitärer Objekte sind gemäss Patrick kein Problem, da sie für Kostenschätzungen nicht über klassifizierte Objekte ausgewertet werden und in den meisten Projektphasen ohnehin nicht modelliert werden.
  - Diverse Elemente, welche das nicht benötigen, wurden durch das Modell als "vordefinierter Typ" vorhergesagt. Dies stellt aber kein Problem dar, da nicht benötigte Informationen die Klassifikation der Bauelemente nicht beeinträchtigen oder verändern.
  - Diverse Elemente sind bei den abgegebenen Daten inkorrekt. Das Modell konnte diverse Elemente identifizieren, welche bei den Daten falsch waren. Bei den Kostenschätzungen wurden diese Elemente nicht eingerechnet, jedoch wurden diese Fehler nicht den modellierenden Personen rückgemeldet. Insgesamt waren Fensterbänke oder Wände fälschlicherweise als Fenster klassifiziert worden. Decken bei Balkonen wurden als Bodenplatten deklariert oder Leichtbauwände wurden in den Daten als massive Wände deklariert. Diese Fehler konnte das Demo-Modell beim Projekt "LUMU" bereits korrekt identifizieren.

#pagebreak()

=== 3. #current_agenda.at(2)
3.1. Ist die Gruppierung der Fehlklassifikationen in BCF-Topics nach (Label, true_class, predicted_class) für die Modellierenden nachvollziehbar oder zu grobgranular?

#emph["Die aktuelle Gruppierung ist bereits gut nachvollziehbar, daher braucht es keine zusätzliche Aufschlüsselung. Anfänglich bestand die Angst, dass die Modellannahmen für den Modellierenden intransparent bleiben. In der präsentierten Form lässt sich aber gut nachvollziehen, was das Modell vorschlägt. Besonders die Gruppierung der Missklassifikationen erleichtert die darauffolgende Analyse ungemein."]

3.2. Reichen die im Excel-Bericht angebotenen Arbeitsblätter (overview, misclassified, correct, unchecked), um die Korrekturen sinnvoll zu priorisieren?

#emph["Im täglichen Handling ist der BCF-Report klar wichtiger. Das Excel ist insbesondere für die nicht geprüften Elemente wertvoll, da man so erkennt, wo das Modell bewusst nicht hingeschaut hat. Das hilft besonders bei der Analyse und Erkennung von Fehlern und Anomalien. Als weitere Verbesserung wäre es ideal, wenn zusätzlich zum Excel-Bericht alle ungeprüften Elemente als zusätzliche Folie am Ende des BCF aufgenommen würden. Das Excel dient dann nur noch als ergänzender Beschrieb und Übersicht und alles Wichtige für die Prüfung wird im BCF-Bericht erfasst."]

3.3. Genügt die Information "currently / should be" pro Topic, oder werden zusätzliche Hinweise zur möglichen Fehleranalyse erwartet?

#emph["Diese Informationen genügen. Weiterführende Hinweise würden eher Verwirrung stiften."]

=== 4. #current_agenda.at(3)
4.1 Sind die Vorhersagen bereits genügend präzise, um die Anforderungen für einen Einsatz als ergänzende Qualitätsprüfung zu erfüllen?

#emph[
  "Ja. Als alleinige Qualitätsprüfung reicht es nicht aus, in Kombination mit einer Fachperson ergibt sich aber ein ideales Werkzeug. Die Performance des Modells ist für eine rein modellgestützte Prüfung noch zu wenig exakt. Besonders der Fokus des Modells auf die einzelnen Elemente ist zum Teil schwierig nachzuvollziehen, wobei der Mensch hier aktuell seine Stärken hat. Deshalb ist ein Zusammenspiel beider Akteure in diesem Fall ideal. Besonders für kleine Details ist das Demomodell sehr gut brauchbar, da diese in der Praxis oft übersehen werden oder Fehler nicht zurückgemeldet werden."
]

4.2 Wie gross darf der Zeitaufwand in der Praxis sein, um die Missklassifikationen vom Demomodell im Nachgang einzuschätzen?

#emph[
  "Das lässt sich nicht pauschal beantworten. Der Aufwand hängt stark von der Projektgrösse und der Projektphase ab, da eine projektspezifische Beurteilung immer notwendig ist. Es gibt immer eine individuelle Schwelle, ab der der Aufwand für ein Projekt nicht mehr tragbar wäre. Diese Schwelle ist jedoch immer individuell zu entscheiden."
]
#pagebreak()

4.3 In welchem Schritt des bestehenden Workflows (Modellierung, Qualitätsprüfung, Kostenschätzung) würde die Pipeline am meisten Nutzen stiften?

#emph[
  "Sie wäre ideal als Ergänzung zum bisherigen Pre-Check, welcher bereits monatlich die ausgewählten Projekte auf deren Modellqualität prüft. Idealerweise werden nur neu hinzugekommene oder geänderte Elemente erneut vorhergesagt, damit bereits bestätigte Elemente nicht wieder vorgeschlagen werden. Das ergäbe einen grossen Effizienzgewinn für alle Beteiligten, ansonsten gäbe es bei gleichen, sich monatlich wiederholenden Missklassifikationen einen Verlust der Motivation bei den Mitarbeitenden."
]

#pagebreak()

4.4 Welche Erweiterungen wären für einen produktiven Einsatz erforderlich oder wünschenswert?

#emph[
  "Eine Feedbackschlaufe für falsch erkannte Bauelemente, damit das Modell aus der Praxis lernt. Bereits abgearbeitete Vorschläge sollen nicht mehr erscheinen, offene und nicht bearbeitete Vorschläge sollen jedoch so lange wiederkehren, bis sie behandelt worden sind."
]

4.5 Würde Patrick das Demomodell im aktuellen Stand bereits seinem Team zur Verfügung stellen? Oder unter welchen Bedingungen wäre es praxisorientiert?

#emph["Ja, im aktuellen Stand wäre es bereits eine sehr grosse Hilfe. Einzige Bedingung wäre, dass eine Feedbackschlaufe integriert wird, damit wiederkehrende Falschprognosen nicht erneut erfasst werden."]

4.6 Wo sieht Patrick aktuell die grösste Schwäche am Modell?

#emph[
  "Am Modell selbst sehe ich kein wesentliches Risiko und keine Schwäche, wenn es richtig genutzt und eine Feedbackschlaufe eingeführt wird. Die Schwäche liegt aktuell bei den Trainingsdaten, diese sollten umfangreicher und diverser sein, um die Performance des Schlussmodells weiter erhöhen zu können. Dort wird es auch spannend sein, wie viel sich das Modell bei umfangreicheren Daten verbessert."
]
