#import "@preview/acrostiche:0.7.0": acr
#import "/template/_helpers.typ": hint, title-caption, todo

= Stand der Forschung <research>

== BIM und maschinelles Lernen

=== Building Information Modeling
Das #acr("IFC")-Schema ist ein offener Standard für semantische Informationen von Gebäudeobjekten mit der Dateiendung ".ifc" @buildingsmart_ifc_2026. Es umfasst Geometrien, Features und Beziehungen, um einen Datenaustausch über #acr("IFC") kompatible Anwendungen hinweg zu erleichtern und die Wiederverwendung von Daten für Analysen und nachgelagerte Aufgaben zu ermöglichen @buildingsmart_ifc_2026. Das aktuelle #acr("IFC")-Schema 4 beinhaltet 768 Entitäten und 410 Psets @zhang_automated_2020.

#figure(
  image("./img/ifc_tree_structure_Building information_modeling_borrmann.png", width: 100%),
  caption: [Ausschnitt aus dem #acr("IFC") Datenmodell mit den wichtigsten Entitäten der obersten Ebenen der Vererbungshierarchie @borrmann_building_2021],
)<chapter_2_ifc_structure>

Zudem nutzt es eine baumartige Struktur, wie in der @chapter_2_ifc_structure zu sehen ist. Die oberste Wurzel ist grundlegendste Klasse für alle Entitätsdefinitionen (IfcRoot), gefolgt von Grundstücken (IfcSite), Gebäuden (IfcBuilding), Stockwerken (IfcBuildingStorey) und Räumen (IfcSpace) als Container. Innerhalb der Container werden die Bauelemente (IfcProduct) gespeichert @zhu_integration_2019. Diese hierarchische Struktur ermöglicht ein effizientes Management der Daten sowie der komplexen Relationen zwischen Bauelementen und deren Informationen @du_bim_2024.

Die Daten innerhalb des #acr("IFC") Formats umfassen Gebäudegeometrie, Materialattribute, strukturelle Komponenten, räumliche Beziehungen und Kostenschätzungen @du_bim_2024. Die Geometrie eines Bauelements wird über "IfcLocalPlacement" (Lage im Raum) und "IfcProductDefinitionShape" (Form) beschrieben @zhu_integration_2019 und kann als #acr("BRep"), #acr("CSG") oder Sweep vorliegen @donkers_automatic_2015.

#figure(
  image("./img/lod_levels_bauen_digital_schweiz.png", width: 100%),
  caption: [Übersicht der unterschiedichen LoD Detaillierungsgrade am Beispiel einer Innenwand #footnote[#link("https://bauen-digital.ch/aktuell/out-now-level-of-information-need-grundlagen-und-anwendungen/")]],
)<chapter_2_lod>

Für die Extraktion von Informationen aus #acr("IFC") Dateien wird die Bibliothek IfcOpenShell @ifcopenshell_2026 eingesetzt. Jedes Bauelement verfügt über eine #acr("GUID"), die den gezielten Zugriff auf einzelne Objekte in der #acr("IFC")-Hierarchie ermöglicht @slusarczyk_machine_2024. Die Bauelemente werden im internationalen Kontext in fünf verschiedene #acr("LoD") Stufen modelliert, wie auf der @chapter_2_lod zu sehen ist.

=== Maschinelles Lernen im BIM-Kontext
Die Elemente in #acr("IFC")-Modellen sind in einer objektorientierten Struktur repräsentiert, welche sich ideal für analytische Aufgaben und den Einsatz von #acr("ML") Techniken eignet @nunez-calzado_machine_2018. Dabei werden wichtige Zusammenhänge innerhalb der Bauteile, Räume und Features abgebildet @slusarczyk_machine_2024. Neben den klassischen #acr("ML") Methoden werden für die Klassifikation von #acr("IFC")-Modellen auch #acr("DL") Ansätze und graphenbasierte Methoden wie #acr("GNN") eingesetzt, welche die graphähnliche Struktur vom #acr("IFC")-Schema nutzen, um relationale Zusammenhänge zwischen den Bauelementen abzubilden @du_bim_2024.

=== Semantische Anreicherung
Unzureichende Semantik kann den Datenaustausch erheblich beeinflussen und Analysen oder Simulationen bei Applikationen für die Gebäudeperformance beeinträchtigen oder behindern @belsky_semantic_2016 @bloch_connecting_2022. #acr("SA") zielt darauf ab, implizite Semantik der Gebäude zu interpretieren und zurück in die Modelle zu speichern, sodass die #acr("SA") für mehrere Zwecke mit minimalem Nachbearbeitungsaufwand verwendet werden kann @belsky_semantic_2016 @bloch_connecting_2022. #acr("SA") Techniken lösen das Problem der Interoperabilität, indem sie vorhandene numerische, geometrische oder relationale Informationen im Modell nutzen, um neue semantische Informationen abzuleiten und die Nutzung in Applikationen oder anderen Verfahren zu erleichtern @belsky_semantic_2016 @slusarczyk_machine_2024.

Die Literatur zu #acr("SA") ist begrenzt und es ist ein relativ neues Forschungsfeld @bloch_comparing_2018. Frühere Studien setzten hauptsächlich regelbasierte Methoden ein, um die Semantik von Bauelementen zu interpretieren @belsky_semantic_2016, wobei deren Komplexität bei heterogenen Strukturen zu Fehlern führen kann @ma_3d_2018. #cite(<bloch_comparing_2018>, form: "prose") untersuchten die Leistung regelbasierter Methoden mit #acr("ML")-Methoden und stellten fest, dass #acr("ML")-Methoden regelbasierte Ansätze in der Klassifikation von Raumtypen in Wohngebäuden in der Accuracy übertreffen. Viele Studien adressieren den Bedarf einer semantischen Integrität in #acr("BIM")-Modellen, um den Austausch dieser Modelle zwischen den Projektteams zu ermöglichen, fachspezifische Analysen durchzuführen und die geforderten Leistungen von Auftraggebenden zu erfüllen @slusarczyk_machine_2024.

== Bauteilklassifikation bei IFC-Dateien
=== Vorhandene Datensätze
Für die Klassifikation von Bauteilen in #acr("IFC") Dateien ist die Verfügbarkeit hochwertiger Datensätze von entscheidender Bedeutung. Neben den öffentlich zugänglichen Datensätzen existieren auch nicht öffentliche oder nur auf Anfrage verfügbare Datensätze. ArchShapesNet ist ein Benchmark-Datensatz für die Klassifikation von #acr("BIM") Elementen, welcher nur auf Anfrage verfügbar ist. Er beinhaltet 4'000 synthetische Instanzen pro Kategorie über 11 bis 13 Klassen, mit 12 gerenderten 2D-Bildern pro Element für Multi-View-CNN-Modelle @yu_archshapesnet_2022. #cite(<austern_incorporating_2024>, form: "prose") verwendeten einen Datensatz von 42'000 einzelnen Elementen aus elf verschiedenen BIM-Dateien, welcher nicht öffentlich zugänglich ist. Bei den öffentlich verfügbaren Datensätzen gibt es eine grosse Vielfalt in Bezug auf die enthaltenen Objekte, welche für die Forschung und Entwicklung von Klassifikationsmodellen genutzt werden können, wie in der @chapter_2_bim_datasets aufgeführt ist.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    align: (left, right, center, center, left, center),
    stroke: (x: none, y: none),

    table.hline(),
    table.header(
      [*Datensatz*],
      [*Objekte*],
      [*Entitäten*],
      [*MV*#footnote[MV (Multi-View): Der Datensatz enthält zusätzlich gerenderte 2D-Bilder aus mehreren Perspektiven für Multi-View-CNN-Modelle]],
      [*Autorenschaft*],

      [*Download-Links*],
    ),
    table.hline(),

    [BIMCompNet], [1'304'206], [87], [Ja], [@yang_bimcompnet_2025],
    [#link("https://bimcompnet-606lab.xaut.edu.cn")[Download]],
    [884k IFC Objects], [884'008], [84], [-], [@teclaw_neural_2024],
    [#link("https://zenodo.org/records/10730758")[Download]],
    [IFCNet], [19'613], [65], [Ja], [@emunds_ifcnet_2021], [#link("https://ifcnet.e3d.rwth-aachen.de")[Download]],
    [BIMGEOM], [10'146], [13], [-], [@collins_bimgeom_2021], [#link("https://doi.org/10.7910/DVN/YK86XK")[Download]],
    [IFCNetCore], [7'930], [20], [Ja], [@emunds_ifcnet_2021], [#link("https://ifcnet.e3d.rwth-aachen.de")[Download]],
    [Wu & Zhang], [389], [5], [-], [@zhang_building_2019],
    [#link("https://purr.purdue.edu/publications/3259/1")[Download]],
    table.hline(),
  ),
  caption: [
    #text[Öffentlich verfügbare Datensätze für #acr("BIM") Klassifikationsaufgaben.]
  ],
)<chapter_2_bim_datasets>

Obwohl bereits diverse Datensätze für die Klassifikation von Bauteilen bei #acr("IFC")-Dateien existieren, gibt es aktuell keinen Datensatz, der für die Klassifikation von Bauelementen nach dem Schweizer Standard #acr("eBKP-H") erstellt worden ist.

=== Feature Engineering / Extraktion
Objekte in #acr("IFC")-Modellen können entweder anhand ihrer eigenen Merkmale wie Form oder Material oder durch ihre räumlichen und topologischen Beziehungen zu anderen Objekten beschrieben werden. Dabei lassen sie sich durch grundlegende Geometrien wie Kanten, Flächen oder Linien darstellen, was die Klassifizierung erleichtert @bloch_comparing_2018. In der Studie von @ma_3d_2018 wird gezeigt, dass Merkmale wie Umfang, Orientierung, Volumen und Schwerpunkt wichtige Kriterien für die Klassifizierung von Bauelementen sind.

Umfang und Orientierung eines Objekts werden häufig durch seine Begrenzungsbox angenähert. In der Studie von #cite(<belsky_semantic_2016>, form: "prose") wurden #acr("AABB") verwendet, die jedoch bei rotierten Objekten die Geometrie grösser schätzen als sie effektiv ist. Im Gegensatz dazu wurden in der Arbeit von #cite(<jylanki_exact_2015>, form: "prose") #acr("TFBB") eingesetzt, bei denen die längste Achse als Extrusionsrichtung des Objekts dient. #cite(<ma_3d_2018>, form: "prose") identifizierten den Schwerpunkt der Bauelemente als wichtiges Klassifikationsmerkmal. Die Studie zeigte zudem, dass #acr("TFBB") gegenüber #acr("AABB") bessere Ergebnisse erzielt. Ergänzend wurden Formverhältnisse sowie das Verhältnis von Fläche zu Volumen als zusätzliche Features eingesetzt @koo_using_2019.

Neuere Studien wie #cite(<utkucu_classification_2024>, form: "prose") trainierten #acr("RF")-Modelle mit 25 unterschiedlichen Merkmalen in drei unterschiedlichen Kategorien:
- Dimensionen (Fläche, Volumen, Bounding Box Masse und Seitenverhältnisse)
- Lage (Minimum und Maximum pro Achse)
- Topologie (Anzahl Flächen, Kanten, Vertices, Euler-Charakteristik und Genus)

In der Studie von #cite(<thomsen_assessing_2015>, form: "prose") wird zudem gezeigt, dass geometrische Merkmale normalisiert und skaliert werden sollten, damit sie vergleichbar sind und ihre Medianwerte nahe null liegen.

=== Klassische ML-Ansätze
Klassische #acr("ML")-Methoden bilden die Grundlage für automatisierte Klassifikationen von Bauelementen in #acr("IFC")-Dateien. Sie werden als Basismodelle sowie als leistungsfähige Klassifikatoren eingesetzt. Die Performance und der Einsatz der Modelle werden in den folgenden Unterkapitel gewürdigt.

==== Klassische Basismodelle
Klassische #acr("ML")-Algorithmen werden in der Literatur regelmässig als Baselinemodelle eingesetzt. Die @tab_baseline_models zeigt alle in der Literatur berichteten Accuracies auf.
Ergänzend zu der Liste stellten #cite(<koo_automatic_2021>, form: "prose") fest, dass #acr("SVM") bei der Klassifikation von Tür- und Wand-Subtypen deutlich schlechter abschnitt als die getesteten Deep-Learning-Modelle.

#figure(
  table(
    columns: (0.7fr, 0.4fr, 1fr),
    align: (left + top, left + top, left + top),
    stroke: (x: none, y: none),

    table.hline(),
    table.header([*Modell*], [*Accuracies*], [*Literaturen*]),
    table.hline(),

    [Naive Bayes], [66,2 - 79,1 %], [@koo_using_2019],
    [Logistische Regression], [80,6 - 89,3 %], [@koo_using_2019 @austern_incorporating_2024],
    [#acr("KNN")], [48,7 - 89,5 %], [@austern_incorporating_2024 @utkucu_classification_2024 @xu_automatic_2022],
    [#acr("SVM")],
    [83,5 - 99,0 %],
    [@koo_using_2019 @austern_incorporating_2024 @xu_automatic_2022 @tang_automatic_2025],
    [#acr("DT")], [66,2 - 100 %], [@utkucu_classification_2024 @wang_framework_2024 @tang_automatic_2025],
    table.hline(),
  ),
  caption: [Übersicht der klassischen Basismodelle mit den erzielten Accuracies in den Literaturen],
)<tab_baseline_models>

==== Random Forest
Random Forest #acr("RF") ist ein effizientes Modell im #acr("ML"). Es ist eine effektive Kombination aus einem Ensemblealgorithmus für Klassifikationen und Decision Trees. Im Vergleich zu anderen Klassifikationsalgorithmen integriert #acr("RF") einzelne Klassifikatoren. Dadurch steigt die Accuracy der Klassifikationen und die Fehlerquote wird deutlich reduziert. Dies führt dazu, dass #acr("RF") häufig bei Klassifikationsaufgaben eingesetzt wird @xu_automatic_2022. In den Studien erzielte #acr("RF") sehr gute Ergebnisse, welche, je nach Datensatz und Anzahl der verwendeten Klassen, eine Accuracy zwischen 75,9 % und 100 % erzielte @austern_incorporating_2024 @utkucu_classification_2024 @xu_automatic_2022 @tang_automatic_2025. Gegenüber #acr("SVM") und #acr("KNN") zeigt #acr("RF") oft eine höhere Robustheit bei grösseren und heterogeneren Datensätzen.

#pagebreak()
==== Ensemble Learning
#acr("EL") verbessert die Accuracy und die Robustheit beim Training von verschiedenen Modellen wie #acr("DL"), #acr("NN"), lineare Regression und integriert diese in den Prognosen @sagi_ensemble_2018. Besonders Verfahren wie Gradient-Boosting, #acr("XGBoost"), #acr("GBDT") aber auch baumbasierte Ensembles wie #acr("ExtraTree") haben sich bei strukturierten Datensätzen bewährt. In der Studie von #cite(<li_ensemble-learning-based_2022>, form: "prose") wurden sechs #acr("EL")-Modelle (#acr("RF"), #acr("ExtraTree"), #acr("AdaBoost"), #acr("GBDT"), #acr("XGBoost") und #acr("LightGBM")) verglichen, wobei #acr("XGBoost") mit 95,0 % Accuracy und einem F1 Score von 97,0 % am besten abgeschnitten hatte. #cite(<abualdenien_ensemble_learning_2022>, form: "prose") setzten Random Forest und #acr("XGBoost") mit 16 Geometriefeatures für die automatische Klassifikation von Bauelementen ein und erzielten Accuracies zwischen 83,0 % und 85,0 %. #cite(<petrochenko_machine_2024>, form: "prose") erreichten mit CatBoost eine Accuracy von 99,56 % und einen F1 Score von 97,49 % bei der automatisierten Klassifikation von #acr("IFC")-Elementen.

=== Deep-Learning-Ansätze
Deep-Learning-Ansätze bilden seit den letzten Jahren eine wichtige Basis im Bereich der Geometrieerkennung von #acr("IFC")-Modellen. Federführend dabei ist der Bedarf, dass aus aufgenommenen Punktwolken von bestehenden Gebäuden die Punkte als Bauelemente erkannt werden und dabei die Punktwolken später in #acr("IFC")-Modelle überführt werden können. Zur Vollständigkeit und Übersicht sind deshalb in dieser Arbeit auch Literaturrecherchen in diesem Bereich erstellt worden. Die Ermittlung wie Punktwolken oder Geometrien mit Deep Learning klassifiziert oder semantisch angereichert werden können standen dabei im Fokus zur Einordnung der bestehenden #acr("ML")-Ansätzen.

==== Graphenbasierte Netzwerke
#acr("IFC")-Dateien besitzen eine graphenähnliche Struktur, die sich für graphenbasierte Methoden anbietet. Die Bauelemente dienen als Knoten und ihre geometrischen Merkmale als Attribute. Die Kanten werden durch die Beziehung zwischen den Elementen gebildet @asier_mediavilla_graph-based_2023 @austern_incorporating_2024. Die gebräuchlichsten #acr("GNN")-Architekturen sind #acr("GCN"), #acr("GAT") und GraphSAGE. Ein direkter Vergleich von #cite(<nabrotzky_graph_2025>, form: "prose") zeigte grosse Leistungsunterschiede zwischen den Methoden. #acr("GCN") erzielte eine Accuracy von 16,8 % während #acr("GAT") und GraphSAGE 90,0 % erreichten. Für Klassifikationsaufgaben im Bereich #acr("BIM") wurden allgemein Accuracies zwischen 85,0 % und 97,0 % erreicht @nabrotzky_graph_2025 @collins_assessing_2021.

Ein wesentlicher Vorteil von #acr("GNN") ist, dass relevante geometrische Merkmale automatisch abgeleitet werden und kein manuelles Feature Engineering benötigt wird @collins_assessing_2021. Zudem generalisieren #acr("GNN") besser auf unbekannte #acr("IFC")-Dateien und benötigen kleinere Trainingsdatensätze @austern_incorporating_2024. Die Stärke zeigt sich besonders bei geometrisch ähnlichen Klassen. Beispielsweise grenzen Fenster typischerweise nur an Wände, Türen aber auch an Böden. #acr("GNN") konnte bei diesen Fällen die Klassen zuverlässig unterscheiden @austern_incorporating_2024. Eine Schwäche bei #acr("GNN") ist die Sensitivität bei kleinen Trainingssätzen. Dies kann zu inkonsistenten Ergebnissen führen @seydgar_comparative_2024.

#pagebreak()
==== Klassifikation basierend auf 3D-Geometrien
Im Gegensatz zu klassischen #acr("ML")-Ansätzen mit manuellem Feature Engineering erlernen #acr("DL")-Modelle relevante Merkmale selbstständig, sind jedoch weniger interpretierbar @koo_automatic_2021. Für die Klassifikation von #acr("IFC")-Objekten wurden in den Studien fünf Repräsentationen der Geometrien eingesetzt:

- *Punktwolken* sind die nativste Form von Scandaten bei Gebäuden und können einfach in andere Darstellungsformen überführt werden @koo_automatic_2021. PointNet, PointNet++ und PointMLP verarbeiten die Punktwolken direkt, sind aber sensitiv gegenüber Rauschen und ungleichmässigem Sampling. PointMLP erreichte auf dem ModelNet40 eine Accuracy von 94,0 % @seydgar_comparative_2024.

- *Voxelbasierte* Ansätze (IFCVoxNet) kodieren Geometrien in ein reguläres Gitter und ermöglichen kontextuelle Klassifikation von Bauelementen im Gebäudemodell. Die Methode zeigte insbesondere bei der Klassifikation kontextuell dominanter Klassen wie Treppen und Geländer starke Ergebnisse und ermöglicht durch ihre Flexibilität den Einsatz bei heterogenen Datenquellen @luttun_ifcvoxnet_2024.

- *Mesh-basierte*-Modelle (MeshCNN, MeshNet) operieren direkt auf triangulierten Oberflächen und können geometrische sowie topologische Beziehungen gut erfassen. Sie sind jedoch stark von der Qualität des Meshes abhängig @hanocka_meshcnn_2019 @du_enabling_2026.

- *#acr("MVCNN")* Ansätze projizieren 3D-Formen in mehrere 2D-Ansichten aus unterschiedlichen Perspektiven, welche anschliessend mit klassischen CNN-Methoden verarbeitet werden. #acr("MVCNN") erzielte 92,0 bis 95,0 % Accuracy @koo_automatic_2021 und #acr("RMVCNN") über 98,0 % auf 9 von 11 Klassen @slusarczyk_machine_2024. Der erhebliche Rendering-Aufwand schränkt trotz den guten Ergebnissen den Einsatz in der Praxis stark ein @seydgar_comparative_2024.

- *#acr("DGCNN")* verbindet die Methoden für eine punktwolken- und graphbasierte Verarbeitung. Dabei arbeiten #acr("EdgeConv") Operationen dynamisch in jeder Schicht des Netzwerks indem Graphen neu berechnet werden. Im Vergleich zu Modellen, die Punkte unabhängig voneinander behandeln, integriert #acr("EdgeConv") Informationen lokaler Nachbarschaften @wang_dynamic_2019.

== Kostenklassifikationen in der Baubranche
=== eBKP-H Standard in der Schweiz (IDC)
Klassifikationssysteme für Bauinformationen entwickelten sich bereits zu Beginn des 20. Jahrhunderts in den USA und Europa. Da sich Gesetze, Vorschriften und die Praktiken in der Branche regional unterscheiden, variieren sich die Methoden für die Klassifikationen global @xun_bim_enabled_2014. Als Reaktion veröffentlichte die #acr("ISO") 1994 den technischen Bericht #acr("ISO") TR 14177 zur Klassifikation von Informationen im Bauprozess. Darauf aufbauend wurde 2001 der Standard #acr("ISO") 12006-2 "Hochbau — Organisation von Informationen über Bauleistungen" veröffentlicht, welcher eine international anerkannte Grundlage für nationale Klassifikationssysteme darstellt. Viele Länder haben ihre nationalen Systeme seither in Anlehnung an diesen Standard neu strukturiert @tang_automatic_2025. Um die Eigenschaften der Gebäude klar zu definieren, müssen baubezogene Informationen in einem Framework für Klassifikationen organisiert werden @austern_incorporating_2024. Zu den etablierten nationalen Systemen gehören #link("https://www.thenbs.com/our-tools/uniclass")[Uniclass] (Grossbritannien) und #link("https://www.csiresources.org/standards/omniclass")[OmniClass] (USA), die beide auf #acr("ISO") 12006-2 basieren @tang_automatic_2025.

In der Schweiz bildet der #link("https://www.crb.ch/de/normen-standards/baukostenplane/baukostenplan-hochbau-ebkp-h")[#acr("eBKP-H")] den massgebenden Standard für die Klassifikation von Bauelementen im Hochbau. Er wird durch den #acr("SIA") herausgegeben und definiert eine hierarchische Gliederung von Baukostenpositionen, die sowohl für die Kostenplanung als auch für die digitale Organisation der Daten in #acr("BIM") Projekten verwendet wird. Die Klassifikation nach #acr("eBKP-H") lässt sich direkt in die #acr("IFC")-Struktur einbetten. Die Möglichkeiten für die Hinterlegung der Informationen ist entweder über "IfcClassification" oder als Referenz über "IfcClassificationReference" gegeben @petrochenko_machine_2024.

Die automatisierte Zuweisung von Klassifikationen auf Basis von Geometrie und #acr("BIM") Daten ist ein aktives Forschungsfeld. #cite(<tang_automatic_2025>, form: "prose") weisen darauf hin, dass regelbasierte Methoden bei umfangreichen Klassifikationsaufgaben und komplexen Daten in Effizienz und Genauigkeit an ihre Grenzen stossen, weshalb sie als Alternative #acr("ML") Methoden erforscht haben. #cite(<banihashemi_machine_2022>, form: "prose") zeigten zudem, dass #acr("BIM") Datenbanken mit kostenrelevanten Standards verknüpft und für die automatisierte Massenermittlung genutzt werden können.

=== Internationale ML-basierte Kostenklassifikationen
Eine genaue Kostenschätzung ist ein zentraler Prozess in Bauprojekten und umfasst das #acr("QTO") als vollständige Auflistung benötigter Mengen und Materialien @banihashemi_machine_2022. Dabei sind Kostenüberschreitungen und der manuelle Aufwand bei Planungsänderungen bekannte Herausforderungen @banihashemi_machine_2022 @shourangiz_flexibility_2011. Trotz diesen bestehenden Ansätzen fehlt es an praxistauglichen Frameworks, welche die Klassifikation von Baukosteninformationen automatisiert abbilden @elfaki_using_2014.

#acr("ML")-Methoden wurden zudem für die automatisierte Klassifikation von Bauelementen im Kostenkontext eingesetzt. #cite(<abualdenien_ensemble_learning_2022>, form: "prose") trainierten #acr("RF") und #acr("XGBoost") mit 16 Features basierend aus der Geometrie für eine automatischen Kontrolle des geometrischen Detaillierungsgrades. Sie erzielten dabei Accuracies zwischen 83,0 % und 85,0 %. #cite(<ma_formalized_2016>, form: "prose") entwickelten ein ontologiebasiertes Framework für eine Repräsentation von Spezifikationen bei Kosten, welches auf verschiedene Standards adaptierbar ist. #cite(<wang_applying_2016>, form: "prose") verknüpften Projektterminpläne aus der #acr("WBS") mit Kostendaten aus der #acr("CBS") im #acr("BIM") Kontext, wobei Mengen direkt aus dem Modell ermittelt werden.

== Kritische Würdigung und Abgrenzung
=== Herausforderungen<challenges>
Obwohl verschiedene Studien bei der Klassifikation von Bauelementen von hohen Accuracies auf Trainings- und Validierungsdaten berichten, zeigt sich bei der Generalisierung auf unbekannte #acr("BIM") Dateien ein deutlicher Einbruch. Die Accuracy aller getesteten Modelle erreichte in der Studie von #cite(<austern_incorporating_2024>, form: "prose") zwischen 81,0 und 90,0 %, sobald Elemente aus #acr("BIM") Dateien klassifiziert wurden, welche nicht bereits Teil des Trainings waren. Die übliche Aufteilung in Trainings- und Validierungssets auf Elementebene reicht daher nicht aus. Modelle müssen zwingend auf vollständig ausgeschlossenen Testdaten evaluiert werden @austern_incorporating_2024. Mehrfache Durchläufe mit wechselnden Testdateien zeigten zudem eine hohe Varianz in der Vorhersagequalität, insbesondere bei kleinen verfügbaren Datensätzen @austern_incorporating_2024.

Die Qualität der Trainingsdaten stellt eine weitere zentrale Herausforderung dar. #acr("ML")-Modelle können nur so gut sein, wie die Daten, auf denen sie trainiert wurden @koo_using_2019. Herausforderungen ergeben sich aus unzureichenden Details für Klassifikationen, Diskrepanzen zwischen dem #acr("BIM") Modellschema und dem Schema der Zielsoftware, Inkonsistenzen beim Export der Daten sowie Fehlern durch mangelhafte Modellierungspraktiken @utkucu_classification_2024.

Bestimmte Elementklassen sind besonders fehleranfällig. So wurden in der Studie von #cite(<koo_using_2019>, form: "prose") 19 von 51 "IfcSlab" Elemente fälschlicherweise als Wände klassifiziert, was zu einem Recallwert von 0,58 führte. Eine Ursache liegt in der geometrischen Ähnlichkeit dieser Klassen. Auch graphenbasierte Modelle sind nicht frei von solchen Fehlern. In der Studie von #cite(<austern_incorporating_2024>, form: "prose") wurden Fenster häufig als Sanitärobjekte klassifiziert, da beide Klassen vorwiegend an Wandelemente grenzen und damit ähnliche Kontextinformationen aufweisen. Klassische Modelle wie #acr("SVM") vermieden diesen Fehler.

Heterogene Variationen der Geometrien innerhalb einer Klasse erschweren die Klassifikation zusätzlich. Bei einer grossen Vielfalt in der Form der Bauelemente innerhalb einer Kategorie stossen Modelle an ihre Grenzen. Im Gegenzug dazu kann die Einführung von Subklassen auf feinerer Granularitätsstufe erforderlich sein @utkucu_classification_2024 @collins_bimgeom_2021 @collins_assessing_2021. Schliesslich fehlt es bislang an einer umfassenden Klassifikation von #acr("BIM") Daten nach standardisierten Systemen. Die bisherigen Studien konzentrierten sich vermehrt auf spezifische Elementtypen und decken nicht die gesamte Bandbreite der #acr("BIM") Objekte ab @tang_automatic_2025.

=== Potenziale
#acr("ML")-Methoden bieten grosses Potenzial um Wissenslücken im Bauwesen zu schliessen und Aufgaben in Planung, Bau und Management zu automatisieren @slusarczyk_machine_2024. Aktuelle Modelle erzielen in spezifischen Aufgaben bereits sehr starke Ergebnisse mit Accuracies von über 99,0 % @petrochenko_machine_2024. #acr("GCN") können zudem relevante Features direkt aus der nativen #acr("IFC")-Geometrie ohne manuelle Feature-Selektion ableiten @collins_assessing_2021. Erzielte Accuracies von über 80,0 % werden bereits als vielversprechender Schritt in Richtung automatisierter Modellkorrektur gewertet, auch wenn für den industriellen Einsatz Werte nahe 100,0 % angestrebt werden @collins_assessing_2021.

#acr("GNN") zeigen besonderes Potenzial für die Verbesserung der Generalisierung. Sie verbessern durch kontextuelle Graphinformationen die Prognosen auf ungesehenen #acr("IFC")-Dateien und weisen bereits bei kleinere Datensätzen gute Resultate auf @austern_incorporating_2024. Semantische Anreicherung kann zudem Inkonsistenzen beim Import und Export von #acr("IFC")-Daten zwischen verschiedenen #acr("BIM") Softwaren beheben @seydgar_comparative_2024. Eine robuste Evaluierung auf Testdaten ist dabei Grundlage, um den tatsächlichen Nutzen verlässlich einschätzen zu können @austern_incorporating_2024.

=== Abgrenzung
Es zeigt sich in der Literaturrecherche, dass die Klassifikation von Bauelementen aus #acr("IFC")-Modellen sowie die Kostenermittlung auf Basis von #acr("IFC")-Dateien aktive, aber noch unvollständig erforschte Gebiete sind. Themen wie die Erkennung und Segmentierung von 3D-Geometrien aus Punktwolken (#link("https://awards.buildingsmart.org/gallery/NpJQxbDr/ArNdXglG?search=008f0660e1c72b45-12")[Scan-to-BIM]) sind zwar eng verwandt, werden in dieser Arbeit jedoch nicht weiterführend behandelt.

Im Bereich der Kostenschätzung mit Hilfe der #acr("BIM")-Methode existieren nach aktuellem Stand keine Arbeiten zur Klassifikation von Bauelementen nach #acr("eBKP-H") auf Basis von #acr("IFC")-Modellen. Diese Arbeit fokussiert sich daher bewusst auf einen ersten explorativen Ansatz mit klassischen #acr("ML")-Algorithmen, um den Grundstein für diesen nationalen Baustandard der Schweiz zu legen. Der Einsatz von komplexeren Modellarchitekturen wie #acr("CNN"), #acr("GCN"), #acr("RMVCNN") oder Transformer-Modellen ist nicht Gegenstand dieser Arbeit und bleibt zukünftigen Forschungsarbeiten vorbehalten, welche potenziell auf den Erkenntnissen dieser Arbeit aufbauen können.
