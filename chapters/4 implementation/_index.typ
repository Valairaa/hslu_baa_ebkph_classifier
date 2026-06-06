#import "@preview/acrostiche:0.7.0": acr
#import "/template/_helpers.typ": format_num, hint, todo

= Realisierung <implementation>

== Systemarchitektur

=== Trainings- und Inferenzframeworks
Als Designentscheid werden die Trainings- und Inferenzframeworks als getrennte Pipelines entwickelt. Die Trainingspipeline umfasst alle relevanten Schritte, von der Erstellung eines geeigneten Datensets bis hin zum Tuning der Modelle und deren Schwellwertanalysen für ein finales #acr("EM"). Die getunten Modelle werden anschliessend mit einem Soft Voting und einem "Confidence"-Schwellwert für das Inferenzframework verwendet. Dieses extrahiert die Features und die aktuellen Labels aus einem beliebigen, ungesäuberten #acr("IFC")-Modell und prognostiziert die vier in @missing_values definierten Labels. Anschliessend werden die Vorhersagen pro Bauelement für die Fachpersonen aufbereitet, wie in @model_pipeline zu sehen ist.

#figure(
  image("./img/1_Training_Inferenz.svg", width: 102%),
  caption: [Die Grafik stellt die beiden unterschiedlichen Trainings- und Inferenz-Frameworks dar],
)<model_pipeline>

=== Modularer Aufbau
Um eine objektorientierte Arbeitsweise zu gewährleisten und die Wiederverwendbarkeit im Code zu garantieren, wurden im Projekt Helpermodule entwickelt. Die Helper bilden den Kern des Codes ab und die Notebooks dienen lediglich der Orchestrierung der Helpermethoden und sind nach dem #link("https://en.wikipedia.org/wiki/Cross-industry_standard_process_for_data_mining")[CRISP-DM] Workflow strukturiert. Eine Übersicht der entwickelten Helper-Dateien ist in @tab_helper_modules dargestellt. Die Abhängigkeiten und die virtuelle Umgebung (.venv) werden mit #link("https://python-poetry.org")[Poetry] verwaltet. Dadurch wird die Reproduzierbarkeit der Python-Umgebung sichergestellt.

#pagebreak()
== Projektmanagement
Für das Projektmanagement wurden klassische Ansätze gewählt, da es sich nicht um eine Teamarbeit handelt. Aufgabenlisten und Meilensteine wurden in OneNote geführt und wöchentlich nach Relevanz und Priorität neu beurteilt. Zudem wurden die aktuellen Arbeiten regelmässig hinterfragt, um neue, bessere Lösungen anzustreben und zielgerichtet arbeiten zu können. Die Hauptmeilensteine wurden in einem Terminprogramm festgehalten und nachgeführt, welches in @project_timeline einsehbar ist.

#figure(
  table(
    columns: (1.1fr, 2fr),
    align: (left + horizon, left + horizon),
    stroke: (x: none, y: none),

    table.hline(),
    table.header([*Helpername*], [*Funktion*]),
    table.hline(),

    [dataloader.py], [Extraktion der Labels aus #acr("IFC")-Modellen, Stratifizierung und Oversampling.],
    [geometric_extraction_helper.py], [Extraktion der sechs Feature-Kategorien],
    [ml_models.py / nn_models.py], [Modelldefinitionen mit Vorverarbeitungs-Pipelines],
    [models_helper.py], [Training, Evaluation, Feature-Importance- und Schwellwertanalyse],
    [wandb_helper.py], [Tracking und Abfrage der Sweep-Resultate],
    [ensemble_helper.py], [Subprozess-basierte Inferenz und Soft-Vote-Aggregation],
    [feedback_helper.py], [Erstellung von BCF-, JSON- und Excel-Berichten],
    [dataviz_helper.py], [Wiederverwendbare Plot- und Tabellenausgaben],
    [run_demo.py], [Skript für die Demo-Pipeline],
    table.hline(),
  ),
  caption: [Übersicht der entwickelten Helperdateien und deren Funktionen],
)<tab_helper_modules>

== Datenvorbereitung

=== #acr("IFC") Parsing mit IfcOpenShell
Beim Parsingprozess werden einmalig die globalen Einstellungen von #link("https://ifcopenshell.org")[IfcOpenShell] gecacht, indem "ifcopenshell.geom.settings()" aufgerufen wird und die beiden Parameter "USE_WORLD_COORDS = False" und "WELD_VERTICES = True" mitgegeben werden. Aus der Analyse der Daten zeigt sich, dass nicht alle Modelle georeferenziert sind und deshalb die lokalen Koordinaten der Modelle entnommen werden, um eine einheitliche Datenbasis bilden zu können. Zudem ermöglicht der Parameter "WELD_VERTICES", dass doppelte Eckpunkte zusammengeführt werden. Dies erzeugt eine Reduktion der Punkte und führt zu einer besseren Performance bei der Bearbeitung.

Bei den #acr("IFC")-Modellen werden alle Entitäten aus dem "IfcProduct"-Baum entnommen, welcher in der @chapter_2_ifc_structure eingesehen werden kann. Dort sind jedoch Entitäten wie "IfcSite", "IfcBuilding" und "IfcBuildingStorey" keine geometrischen Objekte, sondern lediglich Informationsgefässe. Zudem wird die Geometrie von "IfcOpeningElement" nicht gebraucht, da sie nur die Öffnungen in den Modellen abbilden. Die Öffnungen der Gebäude sind aber auch in den platzierten Entitäten wie beispielsweise bei der Wand bereits vorhanden, daher würden diese Duplikate darstellen. Aus diesem Grund werden diese Entitäten aus dem Datensatz entfernt. Für das Matching der Labels wird ein Fuzzy-Pattern-Matching verwendet, damit für die gewünschten Labels immer das erste Element genommen wird, bei welchem das Property-Set und auch der Name der Eigenschaft übereinstimmt.

#pagebreak()
=== Zusammenführung der Datengrundlage und Deduplizierung
Als vorliegende Datengrundlagen sind 16 Excel-Dateien vorhanden. Diese Tabellen beinhalten die Labels bei den 13 unterschiedlichen Projekten. Beim Projekt "ADEM" sind drei unterschiedliche Projektstände vorhanden und beim Projekt "GERB" sind jeweils zwei Projektstände vorhanden. Bei den Excel-Dateien ist jedes einzelne Element vom Modell als Zeile vorhanden und die Spalten geben die Attribute zur Identifizierung und die Labels an. Insgesamt wurden folgende Spalten in den Excel Dateien hinterlegt: Modell, Geschoss, GKS-Typ, #acr("IFC")-Entität, Predefined Type, #acr("GUID"), CHE_eBKP-H 2020 GKS. Wie bereits aus @methods_label_generation entnommen werden kann, wurden diese Attribute mittels den Klassifizierungsregeln im Solibri erstellt und können anschliessend als Excel-Dateien exportiert werden.

Die Excel-Dateien beinhalten das Stichwort "labels" im Dateinamen, damit die Label-Dateien von den anderen abgegebenen Dateien unterschieden werden können. Aus den Excel-Dateien entsteht ein Datensatz von 120'487 Zeilen. Um Duplikate zu vermeiden, wird bereits jedes Element entfernt, welches die gleiche "#acr("IFC")-Entität" und "#acr("GUID")" aufweist. Der Datensatz der Labels wird dadurch auf 100'656 reduziert. Anschliessend werden alle Bauelemente aus den #acr("IFC")-Dateien ausgewertet und mit dem Label-Datensatz abgeglichen und zusammengeführt. Insgesamt konnten aus den Modellen 127'427 Bauelemente extrahiert werden, wovon 100'656 ein Label besitzen. Das Zusammenführen der Elemente zwischen den Labels und den Modellen erfolgt erneut über die "#acr("IFC")-Entität" und "#acr("GUID")". Mit diesem Ansatz wird garantiert, dass die exportierten Labels aus dem Solibri mit den nativen #acr("IFC")-Modellen übereinstimmen. Dabei sind zwischen den Labels aus den Excel-Dateien und den Modellen beim Attribut "Predefined Type" Differenzen detektiert worden. Diese Differenzen wurden bei 94 Elementen erkannt, welche nicht die gleichen Attribute aufwiesen. Da diese Unstimmigkeit nur 0,1 % des Datensatzes ausmacht, wurde sie nicht weiter analysiert und die betroffenen Elemente aus dem Datensatz entfernt. Des Weiteren wurden zur finalen Deduplizierung alle Elemente, die den gleichen "Projekt Code" und "#acr("GUID")" aufweisen, vom Datensatz entfernt. Der Datensatz reduziert sich dadurch auf 108'447 Objekte.

=== Analyse der #acr("eBKP-H") Klassen
Wie bereits in der @data_distribution_per_project ersichtlich ist, gibt es viele Bauelemente, welche den Wert "Nicht Klassifiziert" haben. All diese Elemente wurden zusätzlich aus dem Datenset entfernt, wodurch der Datensatz neu auf 71'922 Bauelementen zu liegen kommt.

Für die Kostenschätzung ab Modell werden bei #acr("eBKP-H") drei Detaillierungsstufen verwendet. Deswegen können Elemente in den folgenden Hierarchiestufen abgebildet werden:
- E Äussere Wandbekleidung Gebäude
- E02 Äussere Wandbekleidung über Terrain
- E02.03 Fassadenbekleidung

Die Abbildung der Beziehungen zwischen Bauelementen und den drei #acr("eBKP-H") Stufen kann zudem im Anhang bei @data_ebkph_sankey eingesehen werden. Dort ist erkennbar, dass nicht alle Bauelemente in die drei #acr("eBKP-H") Stufen unterteilt werden, da nicht alle Bauelemente diese Genauigkeit für eine Kostenschätzung benötigen. Diese Mehrdeutigkeit bei der Klassifikation bei #acr("eBKP-H") hat die Konsequenz, dass für diverse Codes lediglich ein Element genommen wird. Das ist wichtig, um alle benötigten #acr("eBKP-H") Klassen abbilden zu können um eine verlässliche Kostenschätzung erstellen zu können. Da ist beispielsweise in der @data_multilabel_cooccurrence_two_digit ersichtlich. Zudem sind diverse Elemente nur einem oder zwei #acr("eBKP-H") Codes zugewiesen.

Bei den zweistelligen #acr("eBKP-H")-Codes ist ersichtlich, dass ein Bauteiltyp 301-mal vorkommt, welcher auf 13 verschiedene Codes zugewiesen wird. Bei einer genaueren Betrachtung des gemeinsamen Auftretens der #acr("eBKP-H")-Klassen wird in der @data_multilabel_cooccurrence_two_digit ersichtlich, dass es bei diesen Multi-Label-Elementen um ein deterministisches Verhalten handelt. Es bilden jeweils die gleichen Elemente diese Klassen. Lediglich bei den Klassen "G06", "D03" und "D04" werden mehrere Elemente miteinander vertauscht, indem dort einzelne Elemente diesen Klassen zugewiesen werden, aber auch Multi-Label-Elemente dieser Klasse zugewiesen werden.

Beispielsweise ist der Bauteiltyp, welcher 301-mal vorkommt, eine Geschossfläche. Diese bildet den Umfang des Gebäudes als Volumen pro Stockwerk ab. Diese Bauelemente sind für Kostenschätzungen wichtig, um Zuschläge einzurechnen, welche über die Fläche pro Stockwerk gerechnet werden. Da der Modellierungsaufwand für kleinere Objekte zu gross wäre und dadurch ein kleiner Kostenfaktor auf die Geschossfläche zugeschlagen wird, bilden Grob- und Kostenschätzungen deshalb immer einen Näherungswert der möglichen Bausumme ab, welcher nicht abschliessend ist. Deshalb wird diese Geometrie für mehrere #acr("eBKP-H")-Klassen verwendet.

#figure(
  image("./img/data_multilabel_cooccurrence_two_digit.svg", width: 105%),
  caption: [Gemeinsames Auftreten der zweistelligen #acr("eBKP-H")-Klassen],
)<data_multilabel_cooccurrence_two_digit>

=== Anreicherung des Datensatzes

==== Geometrieverarbeitung bei #acr("IFC")-Dateien
Für die Verarbeitung der Geometrie bei den #acr("IFC")-Modellen wird die Bibliothek #link("https://ifcopenshell.org")[IfcOpenShell] verwendet. Für die Arbeit wird die Methode "ifcopenshell.geom.create_shape()" benutzt, welche es ermöglicht, die Objektgeometrien zu triangulieren. Dieser Prozess wird oft als Tessellierung beschrieben und als Mesh-Geometrie deklariert @ifcopenshell_2026. In diesem Prozess werden Oberflächen der Elemente in Dreiecke umgewandelt und die Oberfläche des Meshes besteht danach lediglich aus Dreiecken. Bereits in der Studie von #cite(<collins_assessing_2021>, form: "prose") wurde dieses Verfahren gewählt. Aus diesen Triangulationen können anschliessend die einzelnen Eckpunkte (Nx3) und Flächen (Mx3) extrahiert und als Features eingesetzt werden.

Bei dieser Methode gibt es auch Elemente, welche keine auflösbare Geometrie haben, da die nativen Geometrien im #acr("IFC") als #acr("BRep")-Geometrien abgespeichert sind. Die Entitäten "IfcSite", "IfcBuilding", "IfcBuildingStorey" und "IfcOpeningElement" werden deshalb ignoriert und aus dem Datensatz entfernt, da sie lediglich Datengefässe zu der Parzelle, dem Gelände oder dem Gebäude abbilden und keine geometrische Repräsentation besitzen. Die Öffnungen sind zudem nicht relevant für die Kostenermittlung nach #acr("eBKP-H"), weil diese Öffnungen bereits in den Wänden enthalten sind und dort entnommen werden können.

==== Extraktion geometrischer Eigenschaften
Die Extraktion der geometrischen Features wird mit dem in @methods_geometric_extraction beschriebenen Ansatz umgesetzt. Die Elemente in den Modellen werden effizient über den Generator "iter_elements_with_features()" verarbeitet. Als Grundgeometrie wird ein Geometrieobjekt mit #link("https://ifcopenshell.org")[IfcOpenShell] erzeugt, indem die Methode "ifcopenshell.geom.create_shape(settings, element)" aufgerufen wird. Sie gibt eine geometrische Interpretation zurück, bei welcher wichtige Features wie Eckpunkte oder die triangulierten Flächen direkt mit der Library extrahiert werden können. Dabei werden Elemente ohne darstellbare Geometrie als #acr("NaN")-Werte zurückgegeben. Dasselbe gilt auch für Geometrien ohne Eckpunkte oder ohne Flächen, sogenannte ungültige Geometrien. Zudem wird eine Methode "\_safe_ratio()" bei der Erstellung der Verhältnisse eingesetzt, um eine Division durch Null zu verhindern. Dies wird mit einem Schwellwert von $e^(-12)$ gesichert. Beim Feature für die projizierte Fläche (Grundriss) der Geometrie wird die Bibliothek "ConvexHull" verwendet und diese Fläche kann nur bei mindestens drei einzigartigen Punkten erstellt werden. Dort wird ein #acr("NaN") zurückgegeben, falls es weniger als drei einzigartige Punkte gibt. Bei den Eigenwerten in der #acr("TFBB")-Repräsentation besteht das Problem, dass diese sehr nahe Null kommen könnten. Das bedeutet eine numerische Instabilität bei degenerierten Geometrien. Um dies zu verhindern, werden die Eigenwerte auch auf $e^(-12)$ gekürzt.

Das Feature "layer_count" der Kategorie GEOM gibt an, wie viele Schichten die Geometrie gespeichert hat. Sie wird über die Methode "ifcopenshell.util.element.get_material()" von #link("https://ifcopenshell.org")[IfcOpenShell] ermittelt. Dabei werden alle sechs verschiedenen Materialtypen berücksichtigt und jeweils einzeln behandelt. Falls kein Material gefunden wurde, wird als Rückgabewert 0 ausgegeben und ansonsten die Anzahl gefundener Schichten. Die topologischen Invarianten (TOPO) werden direkt aus der Mesh-Repräsentation berechnet, worin die Anzahl der Eckpunkte, Kanten und Flächen sowie die Euler-Charakteristik und der Genus pro Element ermittelt werden. Die Materialfeatures (MATERIAL) werden ebenfalls über "ifcopenshell.util.element.get_material()" extrahiert, in einzelne Tokens zerlegt und als binäres Encoding pro Element abgespeichert. Weil Bauelemente gleichzeitig mehrere Materialien beinhalten können. Die Anzahl der horizontalen Elemente ober- und unterhalb des Zielelemente wird über Raycasting (RAY) bestimmt. Damit Aufbauten der gleichen Decke nicht mitgezählt werden, wird der Mittelpunkt der Geometrie um einen Offset von einem Meter nach oben bzw. unten verschoben. Dieser Wert entspricht der maximalen Aufbauhöhe von bis zu drei Schichten pro Decke, wie sie in den Modellen vorkommen können.

In einem Gebäude werden beispielsweise Fenster oder Türen möglichst gleich geplant, um die Gesamtkosten des Gebäudes tief zu halten. Dies führt dazu, dass beim Ansatz, die Bauelemente nur mit geometrischen Eigenschaften nach Labels zu klassifizieren, viele Elemente die gleichen Eigenschaften haben. Alle Bauelemente wurden deshalb geprüft und wenn alle 73 Eigenschaften identisch waren, wurde nur das erste Element beibehalten. Dieser Schritt führte zu einer Reduktion des Datensatzes auf 44'343 Elemente. Des Weiteren wurden die Elemente entfernt, bei welchen keine Geometrie erzeugt werden konnte. Das waren insgesamt 12 Elemente. Der Datensatz liegt nun bei 44'331 Elementen.

#pagebreak()
=== Featurekorrelation und PCA
Bei der Korrelations-Heatmap werden die Labels der vier Kategorien "#acr("IFC")-Entität", "Vordefinierter Typ", "Lage" und "Tragend" zunächst als Dummy-Variablen kodiert. Zudem werden Features mit einer Standardabweichung von 0, welche dadurch keine Varianz aufweisen, ausgeschlossen. Anschliessend wird der Pearson-Korrelationskoeffizient $r$ zwischen allen numerischen Features und den kodierten Labels berechnet. Die Darstellung der Heatmap erfolgt auf einer Skala von $-1$ bis $+1$.

Beim #acr("PCA")-Verfahren werden alle Features zunächst mit dem "StandardScaler" von #link("https://scikit-learn.org/stable/")[scikit-learn] standardisiert und auf zwei Hauptkomponenten (PC1, PC2) mit der grössten Streuung reduziert. Die Varianz der beiden Komponenten gibt dabei an, wie viel der ursprünglichen Information in der zweidimensionalen Darstellung erhalten bleibt. Pro Label wird ein Plot erstellt, in dem alle Klassen unterschiedlich eingefärbt sind, um die Gruppierung und Trennbarkeit der Klassen im Featureraum visuell einschätzen zu können.

Bei der Analyse der Abbildungen konnten keine starken Korrelationen entdeckt werden. Es werden daher keine Features vor dem Training entfernt. Die Abbildungen können im Anhang unter @feature_correlation_heatmap und @feature_correlation_pca eingesehen werden.

=== Behandlung untervertretener Klassen<rare_classes>
Um eine Analyse der untervertretenen Klassen zu ermöglichen, wird zuerst der bestehende Datensatz in die drei Splits (Training, Validierung, Test) unterteilt, wie im vorhergehenden @implementation_dataset_splitting erklärt. Als Referenzmodell wird ein #acr("RF") mit den Standardeinstellungen und "n_estimators = 100" verwendet.

Für jedes der vier Labels werden die Klassen analysiert. Wenn ein Label eine Klasse mit weniger als 500 Elementen im Trainingsdatensatz hat, wird das Label genauer untersucht. Dies ist bei "#acr("IFC")-Entität" und "Predefined Type" der Fall, wie in der @learning_curve_label_ifc_entity und in der @learning_curve_label_predefined_type ersichtlich wird. Bei der "#acr("IFC")-Entität" ist gut erkennbar, dass die meisten Klassen bereits ab 50 Samples eine gute Performance erreichen. Bei "IfcRoof" und "IfcCovering" sind die Muster anspruchsvoller und es werden mehr Daten für die Klassifikation benötigt. Dort liegt der ideale Schwellwert bei 150. Bei einer grösseren Datenbasis wäre aufgrund der Performance aller Klassen ein Schwellwert von 350 optimal. Diese Entscheidung würde aber dazu führen, dass drei weitere Klassen aus dem Datensatz entfernt werden.

#figure(
  image("./img/learning_curve_label_ifc_entity.svg", width: 105%),
  caption: [Grafik zur Performance der Klassen mit der Anzahl gewählter Samples beim Attribut "IfcEntity"],
)<learning_curve_label_ifc_entity>

Bei den vordefinierten Typen ("PredefinedType") ist eine ähnliche Tendenz erkennbar. Viele Klassen erreichen bereits bei 25 Samples gute Resultate, während andere mehr Samples benötigen, um wichtige Muster der Geometrien zu erkennen, wie in der @learning_curve_label_predefined_type erkennbar ist. Ein idealer Schwellwert liegt auch hier bei 200, wenn alle Klassen beibehalten werden sollen. Eine Alternative wäre der Ausschluss der Klassen "Baseslab" und "Roof" mit einem Schwellwert von 150. Die Klasse "Partitioning" bricht nach 150 Samples in der Performance ein, aber da es sich hier um eine Analyse untervertretener Klassen handelt, kann dieser Typ ignoriert werden. Damit genügend Klassen für die Vorhersage der Modelle erhalten bleiben, wird der Schwellwert auf 200 gelegt. So wird garantiert, dass die Kosten von Missklassifikationen bei der Verwendung möglichst vieler Klassen auf ein Minimum reduziert werden. Bei der "#acr("IFC")-Entität" werden dadurch vier und bei den vordefinierten Typen 14 Klassen entfernt. Bei den enthaltenen Entitäten "IfcRoof" und "IfcCovering" sowie deren Unterklassen "ROOF" und "BASESLAB" ist die Wahrscheinlichkeit für eine falsche Klassifikation aufgrund der Analyse am grössten. Alle Klassen unter diesem Schwellwert werden aus dem Datensatz gelöscht. Dadurch reduziert sich der Datensatz auf 41'463 Bauelemente.

#figure(
  image("./img/learning_curve_label_predefined_type.svg", width: 105%),
  caption: [Grafik zur Performance der Klassen mit der Anzahl gewählter Samples beim Attribut "PredefinedType"],
)<learning_curve_label_predefined_type>

=== Aufteilung des Datensatzes<implementation_dataset_splitting>
Die im @methods_data_splits beschriebene Aufteilung wird mit der Funktion "dataloader.split_to_datasets()" und "MultilabelStratifiedShuffleSplit" aus der Bibliothek "iterstrat" umgesetzt. Der projektspezifische Fingerprint wird in "build_project_fingerprint()" erzeugt. Dabei werden pro Projekt die Anzahl Elemente je Labelwert binär kodiert.

Konkret wird zuerst ein Testset mit 10 % extrahiert und die verbleibenden 90 % in 72 % Training und 18 % Validierung unterteilt. Nach der Aufteilung werden identische Featurevektoren aus Validierungs- und Testset sowie Klassen, die nicht in allen drei Splits vertreten sind, iterativ entfernt. Dadurch reduziert sich der Datensatz auf 38'984 Bauelemente. Die Grösse und die Projektverteilung der Datensätze sind in der @tab_dataset_sizes ersichtlich und die Projekte können zudem bei der @overview_projects visuell eingesehen werden.

#let stats = json(
  "../../code/3_data_curation_enrichement/3_9_split dataset to datasets and remove rare classes/dataset_stats.json",
)
#figure(
  table(
    columns: 4,
    align: center,
    stroke: (x: none, y: none),

    table.hline(),
    [*Split*], [*Ohne Oversampling*], [*Mit Oversampling*], [*Projekte*],
    table.hline(),

    [Training],
    [#format_num(stats.train)],
    [#format_num(stats.train_over)],
    [CHLI, ESAK, GERB, IMBU, KEHO, RALU, ZEGA, ZUST],
    [Validierung], [#format_num(stats.validation)], [-], [BRUT, GSRH, KEPR],
    [Test], [#format_num(stats.test)], [-], [ADEM, LUMU],
    table.hline(),
  ),
  caption: [Übersicht der Anzahl Bauelemente und deren Projektverteilung pro Datensatz],
)<tab_dataset_sizes>

#pagebreak()
=== Validierung der Schwellwertwahl untervertretener Klassen<implementation_threshold_validation>
Die Schwellwertanalyse aus @rare_classes wurde auf einer früheren Datenaufteilung durchgeführt, bevor die seltenen Klassen entfernt wurden. Durch die Entfernung der untervertretenen Klassen verändert sich die für die Stratifizierung zugrundeliegende Klassenverteilung pro Projekt. Die Methode "MultilabelStratifiedShuffleSplit" erzeugt deshalb trotz identischem "random_state" eine leicht abweichende Projektzuordnung. Bei der Analyse wird klar, dass das Projekt "ADEM" für die erste Schwellwertanalyse beteiligt war, sich jedoch beim finalen Datensplit im Testset befindet. Aus diesem Grund handelt es sich beim  Schwellwert für untervertretene Klassen (n = 200) um ein Datenleck.

#figure(
  image("./img/learning_curve_validated_label_ifc_entity.svg", width: 105%),
  caption: [Validierte Learning-Kurven für "IfcEntity" auf der finalen Trainings-/Validierungsaufteilung (ohne "ADEM")],
)<learning_curve_validated_label_ifc_entity>

Um eine Beeinflussung des Endergebnisses durch die methodische Schwäche ausschliessen zu können, wurde die Schwellwertanalyse erneut mit den finalen Datensätzen im Notebook "validate_rare_classes_threshold.ipynb" aus #ref(<implementation_dataset_splitting>) wiederholt. Die @learning_curve_validated_label_ifc_entity und @learning_curve_validated_label_predefined_type zeigen die erneut berechneten Learning-Kurven. Ideale Knickpunkte liegen dabei erneut im Bereich zwischen 150 bis 250 Samples, wodurch der ursprünglich gewählte Schwellwert von 200 als robust bestätigt wird.

#figure(
  image("./img/learning_curve_validated_label_predefined_type.svg", width: 105%),
  caption: [Validierte Learning-Kurven für "PredefinedType" auf der finalen Trainings-/Validierungsaufteilung (ohne "ADEM")],
)<learning_curve_validated_label_predefined_type>

#pagebreak()
=== Oversampling<oversampling_implementation>
Die Analyse für die Anzahl der zu duplizierenden Elementen erfolgt in der Funktion "dataloader.oversample_training_data()" unter Verwendung von "RandomOverSampler" aus der Bibliothek "imbalanced-learn". Ziel dabei ist es, untervertretene Label-Kombinationen gezielt zu identifizieren. Die vier Labels werden zu einer eindimensionalen Keyword-Spalte miteinander verkettet. Diese kodiert jede eindeutige Kombination der vier Labels als einzelnen Wert. Nur Label-Kombinationen mit weniger als dem definierten "target_count" werden hochgesampelt, indem deren Samples durch zufällige Duplikation bis zur Zielanzahl vervielfacht werden.

Die optimale Zielanzahl wird durch eine Schwellwertanalyse mit den unterschiedlichen Werten (0, 25, 50, 75, 100, 125, 150, 200, 300, 500) bestimmt. Die Analyse wird im Notebook "remove_rare_classes_and_split_datasets.ipynb" durchgeführt, wobei das #acr("RF")-Modell als Basismodell dient und der Macro-F1-Score auf dem Validierungsdatensatz als Optimierungsmetrik verwendet wird. Das beste Resultat wird bei "target_count = 100" erreicht, das einen Mean-Macro-F1 von ungefähr 0,7062 erzielt und in der @oversampling_threshold_analysis ersichtlich ist. Der Trainingsdatensatz wächst dadurch von 26'977 auf 28'756 Samples, wie die @tab_dataset_sizes veranschaulicht. Es wird lediglich der Trainingsdatensatz hochgesampelt, damit das Validierungs- und Testset frei von Duplikaten und die Ergebnisse dadurch aussagekräftig bleiben.

#figure(
  image("./img/oversampling_threshold_analysis.svg", width: 110%),
  caption: [Schwellwertanalyse für die Anzahl der zusätzlichen Samples als Duplikate],
)<oversampling_threshold_analysis>

== Training der Modelle
Die Implementierung der Modelle erfolgt in "ml_models.py" mit den entsprechenden scikit-learn-Klassen. Zudem wird ein statischer Seed von 42 in "\_settings.SEED" für alle Modelltrainings gesetzt, um die Reproduzierbarkeit aller Modelle zu gewährleisten.

=== Baseline-Modelle: Naive Bayes, Logistic Regression, #acr("KNN"), #acr("SVM"), Decision Tree
Für jedes Baselinemodell werden spezifische Hyperparameter definiert: Das #acr("KNN")-Modell wird mit "n_neighbors = 5" konfiguriert, das #acr("SVM")-Modell mit einem "RBF"-Kernel und "C = 1", die Logistic Regression mit "C = 1" und "max_iter = 1000" und der #acr("DT") mit den Standardeinstellungen von scikit-learn. Das Naive Bayes-Modell wird ohne explizite Hyperparameter-Anpassung verwendet.

Entsprechend dem im @methods_multioutput gewählten Ansatz werden alle Baseline-Modelle über den "MultiOutputClassifier"-Wrapper für die vier Labels eingebunden, der intern pro Label ein eigenständiges Modell trainiert.

=== Baumbasierte Ensemble-Modelle: Random Forest, Extra Trees, XGBoost, LightGBM
#acr("RF") wird mit "n_estimators = 100" und "class_weight = balanced" trainiert, um die Balance zwischen den Klassen zu gewährleisten. #acr("ET") wird mit "n_estimators = 100" konfiguriert. #acr("XGBoost") erfordert spezielle Behandlung, da es nur ganzzahlige Labels akzeptiert. Daher wird ein "StringToIntWrapper" implementiert, der die Klassen automatisch konvertiert. Zusätzlich wird "eval_metric = mlogloss" für die Evaluation auf dem Validierungsset gesetzt. #acr("LightGBM") wird mit "n_estimators = 100" und "verbose = -1" trainiert, um die Ausgabe zu minimieren. Ergänzend werden auch die scikit-learn-nativen Varianten "Gradient Boosting" und "Hist Gradient Boosting" mittrainiert.

Bei der Multi-Output-Klassifikation werden unterschiedliche Ansätze je nach Modell gewählt. #acr("RF") und #acr("ET") unterstützen Multi-Outputs nativ und werden direkt mit allen vier Labels trainiert. Die übrigen Modelle werden auch über den "MultiOutputClassifier"-Wrapper eingebunden.

=== #acr("MLP")-Netzwerk
Das #acr("MLP")-Modell verfügt über einen gemeinsamen "Backbone", der alle vier Labels gemeinsam verarbeitet und hat zuletzt je einen separaten "Klassifikationskopf" pro Label. Diese Architektur ermöglicht es dem Modell, Abhängigkeiten zwischen den Labels zu erlernen und gleichzeitig Label-spezifische Klassifikationen durchzuführen. Es unterscheidet sich dadurch stark von den bisherigen #acr("ML")-Methoden.

Der "Backbone" besteht aus vier aufeinanderfolgenden und vollverbundenen Schichten. Als Aktivierungsfunktion wird #acr("ReLU") verwendet. Die Anzahl Parameter in den Schichten wird relativ zum Parameter "n_hidden" gewählt, indem die Anzahl der Parameter bei der dritten Schicht halbiert und bei der vierten Schicht durch 4 geteilt wird. Zudem wird nach den ersten drei Schichten ein "Dropout-Layer" mit einer Standard-Dropout-Rate von 0,3 angewendet, um die Generalisierung des Modells zu stärken. Jeder der vier Klassifikationsköpfe ist eine einzelne Schicht mit der Form "n_hidden / 4, n_classes_label_i", wobei "i" die Anzahl der Klassen für das jeweilige Label bedeutet. Dadurch bekommt jedes Label einen eigenen Klassifikationskopf um die Logits für jede Klasse als Output zu erhalten.

Das Training erfolgt mit "AdamW" und verwendet einen "CrossEntropy"-Loss pro Klassifikationskopf. Der Loss aller vier Köpfe wird zu einer gesamten Zahl aufsummiert, welche für die "Backpropagation" verwendet wird. Bei jeder Trainings-Epoche wird eine Evaluierung auf Basis des Validierungssets durchgeführt.

=== Modellspezifische Vorverarbeitungs-Pipeline
Die im @methods_preprocessing beschriebene Vorverarbeitung wird in "ml_models.py" als scikit-learn-"Pipeline" pro Modelltyp umgesetzt. Bei den Modellen #acr("KNN"), #acr("SVM") und Logistic Regression werden zuerst Ausreisser mit "IQRCapper" entfernt und anschliessend gleicht ein "PowerTransformer" nach dem "Yeo-Johnson"-Verfahren die schiefen Verteilungen an. Dabei werden die Features über "standardize = True" in einem Schritt auf einen Mittelwert von 0 und eine Standardabweichung von 1 standardisiert. Beim Modell "Naive Bayes" wird derselbe "PowerTransformer" mit "standardize = False" ohne Standardisierung eingesetzt. Die baumbasierten Modelle (#acr("DT"), #acr("RF"), #acr("ET"), #acr("XGBoost"), #acr("LightGBM"), Gradient Boosting, Hist Gradient Boosting) und das #acr("MLP")-Netzwerk erhalten keine Vorverarbeitung.

=== Feature-Gruppen-Analyse<feature_group_analysis>
Diese Analyse evaluiert alle möglichen Kombinationen der sechs Feature-Kategorien (@tab_extracted_geometric_features). Insgesamt sind dadurch $2^6 - 1 = 63$ Kombinationen möglich, wobei die leere Kombination ausgeschlossen wird.

Für alle Kombinationen werden sowohl #acr("RF") als auch #acr("XGBoost") mit ihren Standard-Hyperparametern trainiert. Bei jeder Kombination wird mittels des Mean-Macro-F1-Scores basierend auf dem Validierungsdatensatz die Bewertung vorgenommen. Die Evaluierung wird pro Label durchgeführt und die Resultate werden anschliessend über alle Labels aggregiert. Beim Abschluss aller 63 Evaluierungen werden die Feature-Kombinationen identifiziert, welche einen ausgewogenen Mix zwischen Performance und Anzahl Features aufweisen.

Beim #acr("RF") zeigte die Kombination aus allgemeinen geometrischen Eigenschaften, topologischen Invarianten, Materialeigenschaften und der Angabe, wie viele horizontale Elemente ober- und unterhalb (geom+topo+material+ray) sind, mit 46 Features und einem Mean-Macro-F1-Score von 0,709 die besten Ergebnisse, während alle 73 Features lediglich 0,705 erreichen. Bei #acr("XGBoost") lieferte hingegen die Kombination aller 73 Features mit 0,719 das beste Resultat. Eine interessante Alternative stellt die kompaktere Kombination "geom+material+ray" dar, mit der sich die Anzahl der Features von 73 auf lediglich 37 reduziert. Beim #acr("RF") erzielt diese Kombination einen Mean-Macro-F1-Score von 0,707 und verschlechtert sich damit lediglich um 0,002 gegenüber der besten Kombination bei neun Features weniger, während sie sich im Gegensatz zu allen 73 Features um 0,002 verbessert. Bei #acr("XGBoost") erreicht dieselbe Kombination 0,700.

Aufgrund der guten Performance und der minimierten Anzahl der Features bei der Feature-Kombination "geom+material+ray" wird diese Kombination zusätzlich beim Hyperparameter-Tuning trainiert. Die Umsetzung befindet sich in den Notebooks "train_ml_models_main_labels" und "train_advanced_ml_models_main_labels". Die vollständigen Performance-Werte der besten Feature-Gruppen-Kombinationen sind im Anhang in den Tabellen @tab_feature_group_rf und @tab_feature_group_xgboost zu finden.

=== Top-N-Selektion mittels Feature-Importance-Analyse<top_n_selection_analysis>
Im Notebook "analyse_feature_selection_performances.ipynb" wird basierend auf den beiden Modellen #acr("RF") und #acr("XGBoost") eine Schwellwertanalyse bezüglich der wichtigsten Features durchgeführt. Diese werden zuerst nach deren Wichtigkeit sortiert. Beim #acr("RF")-Modell basieren diese Werte auf der mittleren Abnahme der Gini-Impurity und werden über alle Bäume gemittelt. Beim #acr("XGBoost")-Modell werden die "Gain"-Werte verwendet. Diese messen, in welchem Ausmass ein Feature zur Verbesserung der Vorhersagen beiträgt.

#figure(
  image("./img/feature_selection_curve.svg", width: 100%),
  caption: [Performance-Kurve der Top-Features für die Modelle #acr("RF") und #acr("XGBoost")],
)<feature_selection_curve>

Nach der Sortierung werden die Features inkrementell vom Wichtigsten zum Unwichtigsten hinzugefügt. Dadurch werden für jede Kombination die Modelle neu trainiert und jeweils der Macro-F1-Score basierend auf dem Validierungsset ausgewertet. Die resultierenden Werte werden pro Modell in einem Plot dargestellt. Die Analyse dieser @feature_selection_curve zeigt sehr gut, wie die Modelle mit der Zunahme der Features ihre Performance verbessern. Beim #acr("RF")-Modell wird bereits bei "n = 9" Features eine sehr gute Performance erzielt. Das #acr("XGBoost")-Modell kristallisiert einen Knick bei "n = 35" Features heraus. Nach diesem Knick ist mit der Zunahme der Features kein grosser Performancegewinn sichtbar. Deshalb werden diese beiden Top-N-Features (9, 35) bei beiden Modellen für das Hyperparameter-Tuning verwendet. Die wichtigsten Features beider Modelle sind im Anhang in  @tab_feature_importance_rf und @tab_feature_importance_xgboost aufgeführt.

=== Hyperparameter-Tuning
Das Tuning der Modelle wird in den Notebooks im Ordner "4_5_hyperparameter_tuning" durchgeführt. #link("https://wandb.ai")[#acr("WandB")] orchestriert alle Sweeps und die wichtigen Metriken in der Cloud. Insgesamt werden alle relevanten Metriken wie Accuracy, Precision, Recall, F1, Macro-F1 und #acr("MCC") für die jeweiligen Trainings- und Validierungsdaten auf dieser Plattform getrackt. Zusätzlich zu den getrackten Metriken wird auch die Auslastung der Hardware dokumentiert, um allfällige Engpässe in der Hardware zu minimieren.

Für #acr("RF") wird ein Grid Search über alle in der @tab_hyperparam_rf erwähnten Parameter getunt. Beim Modell #acr("XGBoost") wird Bayesian Optimization bei den in der @tab_hyperparam_xgboost dargestellten Parametern mit über 1'000 Runs eingesetzt. Bei diesem Modell ist Bayesian Optimization von Relevanz, da es bereits aufgrund der Ergebnisse den Suchraum selbstständig schliesst und nur in der Richtung lokaler/globaler Minima begrenzt. Das #acr("MLP") wird deshalb auch direkt mit Bayesian Optimization mit den in der @tab_hyperparam_nn angegebenen Parametern einmalig auf allen 73 Features optimiert.

Bei den Modellen #acr("RF") und #acr("XGBoost") werden die Feature-Kombinationen aufgrund der vorherigen Analysen in @feature_group_analysis und @top_n_selection_analysis erweitert. Dadurch werden bei diesen Modellen alle 73 Features, die Feature-Kombination aus "geom+material+ray" und jeweils die Top-N Features mit "n = 9" und "n = 35" trainiert. Die besten Checkpoints werden lokal nach dem Macro-F1-Wert als eigenständige Pickle-Files "best\_Modelltyp\_F1-score.pkl" abgespeichert, um diese später wieder verwenden zu können.

== Ensemble-Inferenz <implementation_ensemble>
Das in @methods_ensemble beschriebene Soft-Vote-Ensemble wird lediglich für die Inferenzpipeline gebraucht. Zuerst werden die besten Modelle aus dem Hyperparameter-Tuning als Pickle-Dateien geladen. Insgesamt werden dafür der #acr("RF"), der #acr("XGBoost") und das #acr("MLP") geladen.

=== Subprozess-basierte Modellausführung
Für die Inferenz des #acr("EM")-Modells wird ein "MacBook Pro M1" verwendet, welches einen Apple-Silicon-Chip mit 16 GB Arbeitsspeicher aufweist. Bei dieser Hardware wurde ein Overhead detektiert, was zu einem Kernel-Crash führte. Die Ursache des Crashes liegt beim gleichzeitigen Importieren von #acr("XGBoost"), sklearn und #link("https://pytorch.org")[torch] in einem einzelnen Python-Interpreter. Die Ursache davon ist eine Kollision der Bibliotheken "libomp" und "OpenMP", da diese von den drei Frameworks mehrfach geladen werden. Als Lösung wird jeder Modelltyp in einem eigenen Python Subprozess via "run_ensemble_model_prediction.py" ausgeführt. Die Klasse "EnsemblePredictor" in "ensemble_helper.py" orchestriert dazu drei Subprozesse parallel mit "subprocess.Popen" und wartet auf die Beendigung aller drei Subprozesse. Jeder Subprozess lädt seinen Checkpoint und die Input-Daten und speichert die Vorhersagen pro Modell als "Hard-Predictions" und deren Wahrscheinlichkeiten pro Klasse der Labels im RAM für das anschliessende Soft-Voting ab.

=== Soft-Vote über drei Modelle
Die Methode "EnsemblePredictor.predict_proba()" mittelt die Wahrscheinlichkeiten der drei Modelle pro Label. Dafür wird zuerst eine gemeinsame Liste aller Klassen erstellt. Dort werden alle Spalten der drei Modellvorhersagen vereint, da nicht jedes Modell zwingend jede Klasse vorhersagen kann. Anschliessend werden mit "reindex(columns=all_classes, fill_value = 0.0)" die Wahrscheinlichkeitsmatrizen auf eine einheitliche Reihenfolge gebracht. Zuletzt werden elementweise über die drei Modelle die Wahrscheinlichkeiten gemittelt und "predict()" wählt mit "idxmax" die Klasse mit der höchsten gemittelten Wahrscheinlichkeit und gibt diese aus.

=== Analyse des Konfidenzniveaus
Die Logik für die Analyse des idealen Konfidenzniveaus ist in "run_demo.py" sowie in im Notebook "analyze_prediction_thresholds.ipynb" implementiert. Wie bereits in @confidence_analysis erläutert, wird zur vorhergesagten Klasse die Konfidenz pro Zeile als Maximum der gemittelten Wahrscheinlichkeiten gespeichert. Beim Anwenden von "CONFIDENCE_THRESHOLDS" wird eine Maske mit den gespeicherten Schwellwerten gebildet. Alle vorhergesagten Bauelemente aus dem #acr("IFC")-Modell werden nur mit ausreichender Konfidenz als finaler Output ausgegeben. Alle anderen werden auf #acr("NaN") gesetzt und nicht ausgegeben.

#figure(
  image("./img/coverage_precision_curve.svg", width: 110%),
  caption: [Coverage-Precision-Kurve für die Modelle #acr("RF") und #acr("XGBoost") auf dem Validierungsdatenset],
)<coverage_precision_curve>

In der @coverage_precision_curve ist ersichtlich, dass alle Labels bis auf das Label "vordefinierter Typ" bereits gute Ergebnisse erzielen. Die Analyse eines optimalen Schwellwerts ist ein Themengebiet, das über diese Arbeit hinausgeht. Für die vorliegende Arbeit wurde deshalb als pragmatischer Entscheid das Ziel gesetzt, dass mindestens 70,0 % der Bauelemente im Datenset vorhergesagt werden müssen. Für die Anwendung in der Praxis hat dies einen höheren Aufwand für die prüfende Person im Zusammenhang mit der Kontrolle der Ergebnisse zur Folge. Es werden dafür jedoch mehr Fehler detektiert. Das finale Dictionary "CONFIDENCE_THRESHOLDS" wurde in der Datei "\_settings.py" mit folgenden Werten fixiert:

#table(
  columns: (auto, auto),
  stroke: none,
  align: (left, right),
  inset: (x: 0pt, y: 0.2em),

  column-gutter: 1.5em,
  [- "label_ifc_entity":], [0,85],
  [- "label_predefined_type":], [0,50],
  [- "label_is_external":], [0,75],
  [- "label_load_bearing":], [0,75],
)

== Prototyp und Feedback-Berichte

=== Demo-Pipeline <implementation_demo>
Für die Demo wird die Klasse "DemoFeedbackGenerator" in "run_demo.py" erstellt, welche ein beliebiges #acr("IFC")-Modell verwendet und folgende vier Schritte durchführt:

1. *Extraktion*: Die vier Labels und die 73 Features werden aus insgesamt drei Quellen zusammengeführt. Die Hauptlabels "label_ifc_entity" und "label_predefined_type" werden direkt aus der "IfcProduct"-Hierarchie entnommen. Die beiden anderen Labels "label_is_external" und "label_load_bearing" werden über die "PROPERTY_MAPPING"-Regeln aus den Property-Sets ausgelesen. Anschliessend werden die 73 Features extrahiert und das resultierende DataFrame wird aus Zeitgründen optional als Parquet-Datei neben dem #acr("IFC")-Modell zwischengespeichert.
2. *Vorverarbeitung*: Analog zur Trainingspipeline werden alle Bauelemente mit nicht auflösbarer Geometrie ("#acr("NaN")") entfernt und nicht vorhandene Werte in den "MATERIAL"- und "RAY"-Features mit "-1" aufgefüllt.
3. *Soft-Vote-Inferenz*: Der "EnsemblePredictor" liefert die gemittelten Wahrscheinlichkeiten pro Label. Vorhersagen, deren Konfidenz die in "CONFIDENCE_THRESHOLDS" definierten Werte unterschreitet, werden auf "#acr("NaN")" gesetzt und nicht ausgegeben.
4. *Report-Generierung*: Die Klassen "BCFCreator" und "MisclassificationCounter" erstellen die drei Reports (BCF, JSON, Excel), welche über die Flags "save_bcf", "save_excel" und "save_json" einzeln aktivierbar sind.

=== Excel-Report
Um schnell einen Überblick über die Klassifikationen zu bekommen, wird ein Excel-Report für die modellprüfenden Personen erstellt. Der Bericht wird über die Klasse "MisclassificationCounter" in "feedback_helper.py" erstellt und enthält vier Arbeitsblätter:
- *overview*: Eine Zusammenfassung pro Label und true-Klasse mit "n_correct", "n_misclassified", "n_unchecked", "n_total" und "error_rate".
- *misclassified*: Alle Bauelemente, bei denen mindestens ein Label falsch vorhergesagt wurde.
- *correct*: Bauelemente mit ausschliesslich korrekten Vorhersagen.
- *unchecked*: Bauelemente, bei denen entweder die Ground Truth "unknown" ist oder die Konfidenz unter den in "CONFIDENCE_THRESHOLDS" definierten Werten lag.

In den Arbeitsblättern werden pro Zeile "project_code", "guid" und für jedes Label eine "\_\_true"- und eine "\_\_ensemble_pred"-Spalte exportiert.

=== BCF-Integration
Für die Integration der Ergebnisse in native #acr("CAD")-Programme oder Solibri wurde die Klasse "BCFCreator" in "feedback_helper.py" implementiert. Sie erstellt pro Modell jeweils eine #acr("BCF")-Datei. Die Ergebnisse werden zuerst gruppiert (Label, true_class, predicted_class) und pro Fehlerkategorie wird ein eigenes Issue-Topic erstellt. Pro Topic wird ein generischer Viewpoint mit den betroffenen #acr("GUID")s als selektierte Komponenten angelegt, wobei die Kameraposition diagonal vor der Bounding Box des Modells positioniert wird.

Die #acr("BCF")-Datei lässt sich direkt in ArchiCAD oder Solibri importieren, womit modellerstellende Fachpersonen die fehlklassifizierten Bauelemente visuell überprüfen können. Zusätzlich wird der gleiche Inhalt als JSON exportiert, damit die Daten auch maschinenlesbar weiterverarbeitet werden können.
