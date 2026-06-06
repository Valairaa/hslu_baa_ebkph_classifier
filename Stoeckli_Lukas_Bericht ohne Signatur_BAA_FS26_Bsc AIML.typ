#import "@preview/codly:1.1.1": *
#import "@preview/codly-languages:0.1.3": *
#import "@preview/acrostiche:0.7.0": acr

// Init codly. If live preview stops working, remove this block until the final generation of the report
#show: codly-init.with()
#codly(languages: codly-languages)

// Import the glossary
#include "_glossary.typ"

#import "/template/template.typ": template

#let report_date = datetime(year: 2026, month: 6, day: 8)
// If you want to have different dates for report, graduation and/or signature, change them here
#let signature_date = report_date
// Only the year is displayed for the graduation date
#let graduation_date = report_date

#let expression_content = [
  Mein Dank gilt in erster Linie meinem Betreuer, Prof. Dr. Aljosa Smolic, sowie meinem Experten, Adrian Willi, für die wertvolle Unterstützung und anregenden Diskussionen während der gesamten Erarbeitungszeit der vorliegenden Bachelorarbeit. Zudem möchte ich meiner Familie, meiner Freundin und meinem Auftraggeber einen besonderen Dank für ihre Unterstützung und Ermutigung während meines gesamten Studiums aussprechen. Des Weiteren danke ich #link("https://github.com/CtrlHaltDefeat")[CtrlHaltDefeat] für die Bereitstellung des #link("https://github.com/CtrlHaltDefeat/hslu_baa_typst")[Typst-Frameworks], zur Gewährleistung des Single Source of Truth Ansatzes.
]

#let abstract_content = [
  #acr("BIM") gewinnt seit Jahren an Bedeutung und wird immer häufiger bei Bauprojekten angewendet. Bei digitalen Zwillingen sind die Klassifikationen der Bauteile oft fehleranfällig und zeitaufwändig. Zudem werden die Daten heute meist manuell erfasst. Seit mehreren Jahren strebt die #link("https://www.gks.ch")[GKS Architekten AG] eine Kostenschätzung ab Modell nach eBKP-H mit der #acr("BIM")-Methode an. Beim bestehenden Anwendungsfall hat sie die gleichen Herausforderungen bezüglich der Aufbereitung, der nachträglichen Pflege und des Unterhalts der Daten festgestellt. Aufgrund dieser Ausgangslage soll im Rahmen der Bachelorarbeit ein Modell entwickelt werden, das Anomalien bei den informierten Bauelementen plausibel und gut lesbar als Bericht zurückmeldet. Nach heutigem Stand gibt es keine Literatur zu einer künstlichen Intelligenz (KI) oder einem Machine Learning (ML)-Algorithmus, die sich mit der Klassifikation von Bauelementen nach eBKP-H befasst. Diese Arbeit bildet einen Grundstein in diesem Themenbereich, indem zwei Hypothesen verfolgt werden. Die erste Hypothese prüft, ob geometrische Features ausreichen, um pro Label einen Macro-F1-Wert über 0,70 zu erreichen. Die zweite Hypothese prüft, ob Gradient-Boosting-Verfahren bei gleichbleibender Performance eine kürzere Trainingszeit als Random Forest (RF) aufweisen.

  Das strukturelle Vorgehen der Arbeit folgt dem CRISP-DM-Ansatz und das wissenschaftliche Vorgehen basiert auf einem empirisch-experimentellen Ansatz. Insgesamt wurden 13 reale Projekte als IFC- und Solibri-Dateien bereitgestellt. Als Designentscheid werden nicht die eBKP-H-Codes direkt vorhergesagt, sondern die Labels für die deterministische Zuweisung nach eBKP-H. Dabei waren vier Labels ausreichend vertreten, um ML-Modelle damit trainieren zu können. Die Bauelemente werden mit einem projektweisen Split in Training, Validierung und Test unterteilt. Dieser projektbasierte Split verhindert ein Datenleck. Als geometrische Merkmale werden pro Bauelement insgesamt 73 Features aus sechs unterschiedlichen Kategorien extrahiert. Die sechs Kategorien umfassen Merkmale zur allgemeinen Geometrie, zur achsenorientierten Bounding Box, zur ausgerichteten Bounding Box, zu den topologischen Eigenschaften, zu den Materialeigenschaften sowie zur Anzahl horizontaler Elemente unter- und oberhalb des Bauelements. Ähnliche Bauelemente, die sowohl im Trainingsdatensatz als auch im Validierungs- oder Testsplit vorkommen, werden entfernt. Pro Label wird jeweils ein ML-Modell trainiert, wobei modellspezifische Vorverarbeitungs-Pipelines angewendet werden. Auf den Trainingsdatensatz wird ein Oversampling angewendet, um untervertretene Klassen stärker zu gewichten. Für das Hyperparameter-Tuning werden die finalen Modelle RF, XGBoost und ein MLP eingesetzt. Bei RF und XGBoost werden mittels Feature-Selektion unterschiedliche Feature-Kombinationen trainiert, um zu analysieren, wie die Anzahl der Features die Performance der Modelle verändert. Als finales Modell werden die besten getunten Modelle zu einem Soft-Vote-Ensemble kombiniert. Mit einer Confidence-Filter Methode trifft das finale Modell anschliessend nur praxistaugliche Vorhersagen für die Rückmeldung an die Fachpersonen.

  In der Arbeit stellen geometrisch ähnliche Klassen eine grosse Hürde dar. Klassen wie "IfcSlab", "IfcCovering" und "IfcRoof" sind schwer zu trennen, da es sich um Decken, Dächer und deren Aufbauten handelt. Zudem sind Fenster und Türen in ihrer geometrischen Form sehr ähnlich. Die abgegebenen Daten wurden zwar von Fachpersonen auf Fehler kontrolliert, dennoch wurde im Verlauf der Arbeit festgestellt, dass die Daten diverse Fehler enthalten und die Datenqualität schlechter als erwartet ist. Des Weiteren wiesen die Daten ein Klassenungleichgewicht in den Labels auf, weshalb eine Schwellwertanalyse für untervertretene Klassen und ein Oversampling durchgeführt wurde. Um ein Datenleck zu verhindern, wurden die Daten zusätzlich zu den drei Aufteilungen projektweise getrennt und identische Featurevektoren entfernt. Eine weitere technische Hürde trat bei Apple-Silicon-Chips auf. Beim gleichzeitigen Laden der drei Bibliotheken XGBoost, scikit-learn und PyTorch kam es durch eine Kollision von libomp und OpenMP zu einem Kernel-Crash. Durch separate Subprozesse konnte dieses Problem gelöst werden. Zuletzt wurde in der Arbeit erkannt, dass das Material Glas nicht korrekt aus dem IFC-Schema extrahiert wird.

  Die Demo-Pipeline wird als Prototyp erarbeitet. Sie liest ein beliebiges IFC-Modell ein und sagt die vier trainierten Labels (IFC-Entität, Vordefinierter Typ, Lage, Tragend) voraus. Dabei erzielt das finale Soft-Vote-Ensemble auf den ungesehenen Daten im Testset einen Macro-F1-Wert von 0,7368 und eine Accuracy von 82,71 %. Beim Einsatz des ermittelten Confidence-Schwellwerts wird die Performance deutlich gesteigert. Die Accuracy der IFC-Entität steigt auf 99,26 % und jene der Lage auf 93,92 % bei einer Abdeckung von mehr als 70,0 % der Daten. Die erste Hypothese ist nur teilweise bestätigt, da der «Vordefinierte Typ» mit 0,5477 unter dem in der Hypothese geforderten Macro-F1-Wert von 0,70 liegt. Bei der zweiten Hypothese erzielte das XGBoost-Modell bessere Resultate als das RF-Modell. Überraschend war jedoch die längere Trainingszeit dieses Modells, denn XGBoost benötigte im Durchschnitt 23,04 Sekunden länger als RF. Für Fachpersonen werden Feedbackberichte in Form von Excel und Building Collaboration Format (BCF) generiert, die sich direkt in das ArchiCAD oder in die Prüfsoftware Solibri importieren lassen. Bei der Validierung der Praxistauglichkeit überzeugte der Prototyp. Im Anschluss an diese Arbeit wird er als monatlicher «PreCheck» für die interne Qualitätssicherung (QS) eingesetzt.

  Beim Projekt lag der Fokus aufgrund des vorhandenen Datensatzes auf den vier ausgewählten Labels. Bei einem grösseren Datensatz wäre das Training der restlichen neun Labels zielführend, um alle Labels für eine vollständige Zuweisung nach eBKP-H prüfen zu können. Als Feedback-Loop sollen für den «PreCheck» künftig bereits geprüfte sowie quittierte Elemente in Folgeprüfungen ignoriert werden, um die Effizienz der QS hochzuhalten. Zudem wurden bisher einfache ML- und Gradient-Boosting-Modelle trainiert. Weitere Modelle wie GNN, PointNet oder MVCNN wurden in dieser Arbeit nicht vertieft behandelt und bleiben für künftige Arbeiten spannende Forschungsgebiete. Zudem wurde die Erklärbarkeit der Modelle angeschnitten, aber nicht tiefgründig behandelt. Auch dieses Thema wäre weiter zu vertiefen. Das Demo-Modell wurde bisher dem Leiter Baumanagement der #link("https://www.gks.ch")[GKS Architekten AG] demonstriert. In diesem Zusammenhang wurde zudem eine erste Fehlanalysen durchgeführt. Eine sinnvolle Erweiterung wäre eine qualitative Studie, die untersucht, wie gut Fachpersonen und Laien die Bauelemente allein aufgrund der geometrischen Eigenschaften klassifizieren können. Zuletzt stammen die Projekte aktuell aus einem einzigen Unternehmen und wurden ausschliesslich aus der Applikation ArchiCAD exportiert. Eine Erweiterung auf unterschiedliche Modellierungsapplikationen und weitere Unternehmen bietet zusätzliches Potential für erweiterte Prüfungs- und Anwendungsbereiche.
]

#show: template.with(
  title: "KI-gestützte Bauteilklassifikation \nnach eBKP-H",
  subtitle: "Automatisierung der Qualitätssicherung bei Kostenschätzungen nach eBKP-H ab Modell mit der BIM-Methode durch den Einsatz von maschinellem Lernen oder neuronaler Netzwerke",
  // You MUST keep a trailing Scomma here, even if there is only one author
  authors: (
    (
      name: "Lukas Stöckli",
      address: "Bühl 3, 6207 Nottwil",
      email: "lukas.stoeckli@stud.hslu.ch",
    ),
  ),
  university: "Hochschule Luzern",
  division: "Informatik",
  report_date: report_date,
  advisor: "Prof. Dr. Aljosa Smolic",
  external_expert: "Adrian Willi",
  industry_partner: [GKS Architekten AG\ Patrick Muff\ Winkelriedstrasse 56\ 6003 Luzern],
  degree_program: "BSc AI & ML",
  degree_program_full: "Bachelor of Science in Artificial Intelligence & Machine Learning",
  graduation_date: graduation_date,
  confidential: false,
  signature_date: signature_date,
  signature_place: "Risch-Rotkreuz",
  expression_content: expression_content,
  abstract_content: abstract_content,
  bibliography_link: "/chapters/BAA.bib",
  appendix_index: "/chapters/7 appendix/_index.typ",
)

#include "chapters/_index.typ"
