#import "@preview/acrostiche:0.7.0": acr
#import "/template/_helpers.typ": hint, todo

= Methoden <methods>

== Methodisches Vorgehen<empirical_method>
In der vorliegenden Arbeit wird ein empirisch-experimentelles Vorgehen verfolgt. Basierend auf der im @research aufgeführten Literatur und der zwei abgeleiteten Hypothesen werden systematische Experimente auf realen Projektdaten geprüft. Es ist ein Top-down-Ansatz, da Annahmen aus bekannten Erkenntnissen formuliert und anschliessend quantitativ gemessen und verglichen werden. Für die Strukturierung der Arbeit wird der #link("https://en.wikipedia.org/wiki/Cross-industry_standard_process_for_data_mining")[CRISP-DM] Workflow angestrebt. Die nachfolgenden Kapitel folgen diesem Ansatz ergänzend zur Forschungsmethodik.

== Datenbasis

=== Zur Verfügung gestellter Datensatz
Für die Arbeit wurden von der #link("https://www.gks.ch")[GKS Architekten AG] interne Modelle zur Verfügung gestellt. Sie wurden bereits erfolgreich für eine Kostenschätzung ab Modell nach #acr("eBKP-H") verwendet und durch einen Fachspezialisten für Baumanagement verifiziert. Die Modelle setzen sich aus 13 Projekten zusammen, wie in der @overview_projects entnommen werden kann. Bei den Projekten handelt es sich um Neu- und Umbauten diverser Projektgrössen. Neubauten sind verhältnismässig leicht übervertreten. Die Diversität der Daten ist im Allgemeinen jedoch hoch. Zudem unterscheiden sich die Projekte in den #acr("SIA")-Phasen. Die #acr("SIA")-Phasen sind als Leistungskatalog für das Baugewerbe entwickelt worden.

#figure(
  image("./img/overview_projects.png", width: 100%),
  caption: [Perspektivische Ansichten der 13 Projekte mit Projektkürzel],
)<overview_projects>

Die #acr("SIA")-Phasen beginnen bei der strategischen Planung, welche als Phase 1 definiert wird und erstrecken sich bis zum Unterhalt der Gebäude, welche sich mit Phase 6 als Bewirtschaftung betitelt @sia_102_2020. Beim Projekt "ADEM" sind in den Daten drei unterschiedliche Versionen und beim Projekt "GERB" sind zwei Modellstände vorhanden. Damit möglichst viele Elemente verwendet werden können, werden alle Arbeitsstände einbezogen. In einem Bereinigungsprozess werden die entstandenen Duplikate entfernt, sodass schlussendlich alle Bauelemente einzigartig sind.

In der @data_distribution_per_project ist sichtbar, dass die Anzahl der vorhandenen Elemente stark zwischen den Projekten variiert. Die Abbildung ist nicht normalisiert. Projekte mit mehreren Arbeitsständen haben daher mehr Elemente. Bei der Abbildung ist erkennbar, dass die Projekte "CHLI", "BRUT" und "ZUST" die meisten Bauteile beinhalten.  Dies ist unter anderem auf ihre Projektgrösse und der fortgeschrittenen #acr("SIA")-Phasen zurückzuführen. Das Projekt "BRUT" setzt sich aus drei Hochhäusern zusammen und die Projekte "CHLI" und "ZUST" befinden sich dazu bereits in fortgeschrittenen #acr("SIA")-Phasen, in denen die Detailplanung bereits abgeschlossen ist und die Gebäude bereits auf der Baustelle realisiert werden.

#figure(
  image("./img/data_distribution_per_project.svg", width: 105%),
  caption: [Anzahl Bauelemente pro Projekt und der dazugehörigen #acr("SIA")-Phase],
)<data_distribution_per_project>

=== Hintergrundinformationen zum Mapping nach #acr("eBKP-H")<general_labels>
Die #link("https://www.idc.ch")[IDC AG] ist der offizielle Supportdienst der CAD-Software ArchiCAD, welche von der #link("https://www.gks.ch")[GKS Architekten AG] für die Planung der Bauprojekte eingesetzt wird. Sie unterhalten die regelmässigen Updates der Software in der Schweiz und sind die einzige Anlaufstelle für den Softwaresupport. Für sämtliche Schweizer Nutzende haben sie eine Zuweisungsmatrix entwickelt, womit Bauexpert:innen mittels #acr("IFC")-Modellen einzelne Bauteile nach #acr("eBKP-H") zuweisen können. Diese Zuweisungsmatrix beinhaltet 21 unterschiedliche Eigenschaften wie beispielsweise "isExternal", welche beschreibt, ob es ein aussenliegendes oder innenliegendes Bauteil ist. Die Zuweisung ermöglicht durch den nationalen und standardisierten Baukostenplan die Ausmasse der Bauteile zu entnehmen und mit den aktuellen Kostenindexen zu hinterlegen.

Dieser Standard wurde ausschliesslich für die ArchiCAD-Software ausgearbeitet, wo die Modelle informiert und exportiert werden. Bei der Kontrolle der Bauteile wurde als Standard das Programm Solibri konzipiert. Alle Prüfregeln können als eigene Prüfmaske von der #link("https://www.idc.ch")[IDC AG] benutzt werden, wenn eine aktive Lizenz im Unternehmen vorhanden ist. Dort können Fachpersonen visuell die Klassifikationen und Mappings kontrollieren und via #acr("BCF")-Protokoll falsche oder fehlende Elemente den modellerstellenden Personen rückmelden. Diese können wiederum das #acr("BCF")-Protokoll direkt im #acr("CAD") integrieren und zugleich visuell alle betroffenen Elemente einsehen.

Die Liste ist deterministisch und von den 21 Eigenschaften werden nicht alle Eigenschaften für eine korrekte Zuweisung benötigt. Zahlreiche Bauteile haben bei den meisten Features einen Stern hinterlegt. Der Stern ist eine Wildcard und bedeutet, dass diese Eigenschaft für das Mapping der Zeile keine Relevanz hat. Ein Beispiel dazu ist die Zuweisung nach C02.02 Innenwandkonstruktion. Dort gibt es insgesamt drei unterschiedliche Möglichkeiten, Wände als Innenwände zu klassifizieren, wie in der @tab_mapping_innenwand zu sehen ist.

#figure(
  table(
    columns: 6,
    align: left,
    stroke: (x: none, y: none),

    table.hline(),
    [*Regel*], [*IFC-Entität*], [*Predefined Type*], [*IsExternal*], [*LoadBearing*], [*Klassifikation*],
    table.hline(),

    [R22], [IfcWall], [PARAPET], [false], [\*], [C02.02 Innenwandk.],
    [R23], [IfcWall], [SOLIDWALL], [false], [\*], [C02.02 Innenwandk.],
    [R24], [IfcWall], [\*], [false], [true], [C02.02 Innenwandk.],
    table.hline(),
  ),
  caption: [Zuweisungsbeispiel für die Klasse C02.02 Innenwandkonstruktion],
)<tab_mapping_innenwand>

Bereits bei dieser Veranschaulichung wird klar, dass das Mapping primär gemacht wurde, um die Planenden bei der Klassifikation der Bauelemente nach #acr("eBKP-H") zu unterstützen. Deshalb stellt sich in dieser Arbeit die Frage, ob die verwendeten Features als Labels für das Mapping nach #acr("eBKP-H") geeignet sind oder eine direkte Klassifikation nach #acr("eBKP-H") der Bauelemente zutreffender ist. Basierend auf der Grundlage, dass die Liste deterministisch ist und viele Labels untervertreten sind, wird in dieser Arbeit vorgeschlagen, die benötigten Eigenschaften für das #acr("eBKP-H")-Mapping als Labels vorherzusagen. Des Weiteren ist die Interpretierbarkeit gewährleistet, da direkt eingesehen werden kann, welche Features korrekt und welche falsch sind. Als weiterer Vorteil bleiben die Eigenschaften bei Änderungen der Zuweisungstabelle erhalten.

=== Visuelle Validierung der Labels mit Solibri<methods_label_generation>
Zusätzlich zu den #acr("IFC")-Modellen wurden von der #link("https://www.gks.ch")[GKS Architekten AG] die verwendeten Solibridateien abgegeben. Sie enthalten die Klassifikationsregeln, mit denen die Bauelemente für die Kostenschätzungen klassifiziert und überprüft wurden. Die Regeln und deren Klassen können in der @eBKPh_all_rules auf der linken Seite der Abbildung eingesehen werden.

#figure(
  image("./img/eBKPh_all_rules.png", width: 100%),
  caption: [Bildausschnitt vom Projekt "ZUST" mit den zugeteilten #acr("eBKP-H")-Codes],
)<eBKPh_all_rules>

Für das Mapping gibt es eine Hauptklassifikation mit 19 Hilfsklassifikationen. Die Hilfsklassifikationen dienen dazu, dass bei Fehlern systematisch einzelne, untergeordnete Regeln visuell überprüft werden können. Ein Beispiel dafür wird in der @eBKPh_isExternal gezeigt, wo die aussenliegenden Bauteile grün und die innenliegenden rot eingefärbt sind. Dadurch wird bei Fachpersonen bereits bei der Betrachtung und beim Navigieren im Modell innert Kürze ersichtlich, sollten einzelne Elemente falsch klassifiziert sein. Grössere Bauelemente haben ein grösseres Ausmass und sind deshalb relevanter für Kostenschätzungen. Diese werden mit der visuellen Prüfung schnell erkannt. Bei kleineren Bauteilen bleibt jedoch das Risiko, dass diese aufgrund der geringen Kostenrelevanz einfacher übersehen werden.

=== Duplikate in den Label-Daten
Die Projekte "ADEM" und "GERB" haben unterschiedliche Modellstände und weisen das Risiko auf, dass sich Duplikate im Datensatz befinden. Nicht geänderte Bauelemente zwischen den Versionen führen beispielsweise dazu. Zudem wurde beim Projekt "ZUST" pro Gebäude ein #acr("IFC")-Modell exportiert. Dies kann dazu führen, dass das gleiche Element im #acr("CAD") bei verschiedenen Gebäuden durch falsche Exporteinstellungen vorkommen könnte. Damit diese Problematik behoben wird, werden alle Elemente, bei denen der "Projektcode" und die "#acr("GUID")" gleich sind, entfernt. Bei der Duplikatsentfernung wird standardmässig jeweils der erste Eintrag behalten und die anderen gelöscht. Eine Schwachstelle bei diesem Ansatz könnte sein, dass bestehende Bauelemente sich zwischen den Versionen verändert haben und beide Geometrien brauchbar für das Training der Modelle sein könnten. Eine qualitative Prüfung all dieser Elemente ist nicht im Rahmen der Arbeit und würde weitere Fachexpertise benötigen. Zudem wurden beide Modellstände bereits durch Fachpersonen geprüft und verifiziert.

In der weiterführenden Analyse der Daten ist aufgefallen, dass das Label "predefined_type" bei einigen Elementen unterschiedliche Werte hat. Diese Bauteile wurden aufgrund des Widerspruchs aus dem Datensatz entfernt. Ob es sich dabei um einen Fehler bei den Labeldaten aus dem Solibri oder dem vorhandenen Wert im #acr("IFC")-Modell handelt, kann nicht abschliessend beurteilt werden. Eine entsprechende Ermittlung und Behebung der Ursache würde die Einschätzung durch eine Fachperson pro Bauteil benötigen und damit die Kapazität der vorliegenden Arbeit übersteigen.

=== Behandlung fehlender Werte als explizite Klasse<missing_values>
Wie bereits im @general_labels erwähnt, basieren viele Klassifikationen auf Wildcards. Daher werden für die Klassifikation nach #acr("eBKP-H") nicht immer alle Eigenschaften benötigt. Dies wird in der @label_property_status veranschaulicht. Dabei wird bereits klar, dass viele der geforderten Klassen nicht ausgefüllt und diesbezüglich auch nicht benötigt werden. Insgesamt sind gemäss der Zuweisungsmatrix der #link("https://www.idc.ch")[IDC AG] 21 Labels von Relevanz. Für die #link("https://www.gks.ch")[GKS Architekten AG] sind dabei lediglich 13 davon von Relevanz. Bei einer genaueren Betrachtung der @label_property_status wird erkennbar, dass die zwei Labels "#acr("IFC")-Entität" und "Vordefinierter Typ" in den Modellen vollständig informiert werden. Dies führt dazu, dass die "#acr("IFC")-Entität" die Hauptklasse der Bauelemente ist und der "Vordefinierter Typ" die dazugehörige Präzisierung zur Hauptklasse darstellt. Die Labels "Lage" und "Tragend" sind bei über der Hälfte der Bauelemente klassifiziert. Acht weitere Labels beinhalten nur wenige Informationen in den Bauteilen und neun Labels wurden nie in den Modellen der #link("https://www.gks.ch")[GKS Architekten AG] gepflegt.

Für das Training werden ausschliesslich die vier Labels "#acr("IFC")-Entität", "Vordefinierter Typ", "Lage" und "Tragend" verwendet. Die Labels "Lage" und "Tragend" enthalten #acr("NaN")-Werte, weil beispielsweise eine Gipswand die Eigenschaft "Tragend" nicht benötigt (Gipswände sind per Definition nicht tragend). Aus diesem Grunde, werden die #acr("NaN")-Werte nicht entfernt, sondern als explizite Kategorie "unknown" kodiert. Dadurch wird das #acr("NaN")-Problem in ein strukturiertes Klassifikationsproblem überführt, bei dem "unknown" eine eigenständige, valide Klasse darstellt. Eine zusätzliche Eigenschaft "irrelevant" wäre sinnvoll, würde aber eine Fachperson pro Element erfordern und übersteigt den Rahmen dieser Arbeit.

#figure(
  image("./img/label_property_status.svg", width: 100%),
  caption: [Übersicht der vorhandenen Label der Bauelemente],
)<label_property_status>

== Geometrische Feature-Extraktion<methods_geometric_extraction>
Eine der Hauptliteraturen für eine Klassifikation basierend auf geometrischen Features ist die Arbeit von #cite(<ma_3d_2018>, form: "prose"). Sie zeigen explizit auf, dass geometrische Features (Extent, Orientierung, Volumen und Zentroid) ausreichend für die Klassifikation von Bauelementen sind. Deshalb baut diese Arbeit auf der bestehenden Literatur auf und adaptiert die Stärke der geometrischen Eigenschaften für die Klassifikation der im @missing_values ausgewählten Labels. Die Geometrie als einzig verlässliche Quelle wird zudem in weiteren Arbeiten behandelt @bloch_comparing_2018 @wu_automated_2018 @du_bim_2024.

Die Literaturen beinhalten Unterscheidungen bezüglich der Geometrie wie die Linearität @ma_3d_2018, Planarität @ma_3d_2018, Sphärizität @luttun_ifcvoxnet_2024 und Topologie @utkucu_classification_2024 @collins_assessing_2021. Durch die Extraktion dieser Werte soll das implizite Fachwissen aus den Bauteilen kodiert werden und eine konzeptionelle Brücke zwischen der Geometrie und den ausgewählten Labels konstruiert werden. Für die vorliegende Arbeit werden aus diesen Unterscheidungen sechs Feature-Kategorien vorgeschlagen, um die Geometrien der Bauelemente korrekt erfassen zu können. Die sechs Kategorien sind in den folgenden Unterkapiteln genauer erläutert. Im Anhang der @tab_extracted_geometric_features sind alle verwendeten Features aufgeführt.

=== Allgemeine geometrische Features
Als erste Kategorie für die Beschreibung einer Geometrie werden allgemeine Features der Bauelemente gesammelt, wie in der @overview_general_features eingesehen werden kann. Das Volumen der Elemente wird ausgehend von einem Tetraeder berechnet, indem alle einzelnen Faces mit deren Volumen aufsummiert werden. Diese Volumenberechnung wurde in der Studie #cite(<ma_3d_2018>, form: "prose") als Alternative zur Voxelisierung vorgeschlagen, welche aus der ursprünglichen Literatur von #cite(<zhang_proceedings_2001>, form: "prose") stammt. Als weitere Features werden alle Oberflächen aufsummiert und die projizierte Fläche der Achsen X und Y (Grundriss) mittels der Bibliothek "ConvexHull" erstellt @koo_using_2019 @wang_framework_2024. Zudem wird der Zentroid des Elementes extrahiert, welcher sich aus dem flächengewichteten Mittelwert der Triangulationen zusammensetzt @ma_3d_2018. Die Ausdehnung wird in Z-Richtung der Geometrie @utkucu_classification_2024, @belsky_semantic_2016 und das Verhältnis zwischen Fläche und Volumen @koo_using_2019 ausgewertet. Als letzte Eigenschaft wird die Kompaktheit der Geometrie analysiert, indem das Verhältnis von Volumen zu Oberfläche mit dem einer idealen Kugel verglichen wird. Je näher der Wert bei 1 ist, desto kompakter ist das Element. Des Weiteren sind bei Decken oder Wänden die Anzahl der Schichten relevant. Beispielsweise sind Decken immer einschichtig und Aufbauten bei Decken oder Aussenwänden immer mehrschichtig. Daraus resultierend werden die Anzahl der Schichten der Bauteile zusätzlich ausgewertet.

=== #acr("AABB") Features als Basis
Federführend für das Konzept der Bounding Box ist die Studie von #cite(<belsky_semantic_2016>, form: "prose"). Dort wird erstmals über die Verwendung der Bounding Box Features gesprochen. Ausgehend von der Bounding Box werden die Dimensionen in alle drei Richtungen, die absolute Lage pro Achse sowie die Verhältnisse der Seiten extrahiert @utkucu_classification_2024. Zusätzlich zu diesen Features erfolgt die Extraktion der Diagonalen sowie des Volumens der Bounding Box @belsky_semantic_2016. Eine visuelle Übersicht ist in der @overview_aabb_features zu finden.

=== #acr("TFBB") als weiterführende Features
In der Studie von #cite(<ma_3d_2018>, form: "prose") wurde für die Klassifikation der Caliper-Algorithmus verwendet, welcher in der Studie von #cite(<jylanki_exact_2015>, form: "prose") erstmals eingesetzt wurde. Dieser Algorithmus ist sehr rechenintensiv, wie in der @compare_geometries zu sehen ist. Deshalb wird dieser Algorithmus nicht in der vorliegenden Arbeit verwendet. Die #acr("TFBB")-Methode wird als effizientere Alternative vorgeschlagen.

#figure(
  image("./img/compare_geometries.svg", width: 100%),
  caption: [Vergleich verschiedener Abstraktionslevels bei Geometrien],
)<compare_geometries>

Dieses Verfahren stützt sich auf die Studie von #cite(<bassier_point_2020>, form: "prose") ab. Dort nutzen sie gewichtete #acr("PCA") für die Beschreibung der Gebäudeelemente. Die Projektachsen werden aus den Eckpunkten der Geometrie abgeleitet, indem über die Kovarianzmatrix die Hauptachsen entlang der Richtungen grösster Streuung bestimmt werden. Dieser Algorithmus ist numerisch robuster als der Caliper-Algorithmus und hat aufgrund der Eigenschaft, dass er kein iterativer Algorithmus ist, eine Komplexität von $O(n)$ anstelle der $O(n^3)$ vom Caliper-Algorithmus. Ein Nachteil des Algorithmus besteht darin, dass, wenn die Oberflächen der Geometrien asymmetrisch verteilt sind, die projizierte Bounding Box nicht exakt der ausgerichteten Geometrie entspricht und dementsprechend verzerrt sein kann. Aus diesem Grund wird mit diesem Verfahren ein annähernd optimales #acr("TFBB") erzeugt, welches einen akzeptablen Trade-off für die Genauigkeit im Vergleich zur Inferenz darstellt.

Aus der #acr("TFBB")-Repräsentation wird die Ausdehnung entlang der Hauptachsen, das Volumen sowie die Verhältnisse der Achsen als Features entnommen @ma_3d_2018. Als weitere Features werden die Linearität, Planarität und Sphärizität extrahiert @bassier_point_2020. Um die Hauptorientierung abzubilden, werden für diese Kategorie die primären Eigenvektoren der #acr("TFBB")-Geometrie entnommen @ma_3d_2018, wie in der @overview_tfbb_features zu finden ist.

=== Topologische Invarianten
Als vierte Kategorie werden topologische Features extrahiert. Diese Features werden direkt aus der Meshgeometrie abgeleitet. Zuerst erfolgt die Extraktion der Anzahl Eckpunkte, Kanten und Flächen extrahiert @utkucu_classification_2024. Des Weiteren extrahierte #cite(<utkucu_classification_2024>, form: "prose") die Euler-Charakteristik, um die Anzahl der Objekte bei Geometrien beschreiben zu können. Beispiele können in der @overview_euler unterhalb eingesehen werden.

#figure(
  image("./img/overview_euler.svg", width: 100%),
  caption: [Vergleich verschiedener Euler-Werte bei Geometrien],
)<overview_euler>

Als weitere Eigenschaft verwendeten sie die Genus-Eigenschaft. Diese gibt die Anzahl der Löcher der Geometrie an, wie in der @overview_genus illustriert wird. Beide dieser Eigenschaften können wichtig sein, um Wände mit Fenstern oder Türen zu unterscheiden, da all diese drei Kategorien vertikale Geometrien sind.

#figure(
  image("./img/overview_genus.svg", width: 100%),
  caption: [Vergleich verschiedener Genus-Werte bei Geometrien],
)<overview_genus>

Weitere Eigenschaften, welche der Meshgeometrie entnommen werden, sind das Verhältnis zwischen Eckpunkten und Kanten sowie die Anzahl zusammenhängender Komponenten @utkucu_classification_2024. Als letzte Eigenschaften werden die maximale Meshfläche und die durchschnittliche Facefläche extrahiert @utkucu_classification_2024 @wang_framework_2024.

=== Hinterlegte Baustoffe in den Geometrien
Baustoffe sind für die Kostenschätzung von hoher Relevanz, da jeder Baustoff einen eigenen Preisindex hat, der neben dem Material selbst auch die Herstellungs- und Montagekomplexität widerspiegelt. Aus diesem Grund wird in der vorliegenden Arbeit vorgeschlagen, die Baustoffe, welche in den Geometrien mitgespeichert sind, als Features zu verwenden.

Über alle Projekte werden die Materialien aus den vorhandenen Schichten der Geometrien ausgelesen und analysiert. Dabei werden alle relevanten Materialbezeichnungen als Tokens in eine Liste aufgenommen. Falls mehrere Wörter vorkommen, werden die Wörter im Namen durch das Leerzeichen als Delimiter in einzelne Tokens aufgeteilt. Nicht relevante Begriffe wie "weniger", "vertikal", "ausgerichtet" oder "braun" werden aussortiert, um ausschliesslich die Grundbaustoffe der Objekte zu erfassen. Diese Eigenschaft ist je nach Projektphase unterschiedlich verlässlich:

- Frühe #acr("SIA")-Phasen (bspw. Vorprojekt): Bauteile werden ohne Materialdifferenzierung dargestellt, weshalb Farbbezeichnungen wie "braun" vorkommen können.
- Fortgeschrittene #acr("SIA")-Phasen (bspw. Ausschreibung): Baustoffe werden mit Schraffurtypen visualisiert, wodurch das Risiko falsch zugewiesener Materialien minimal ist.

Die erstellte Liste der Tokens wird danach als binäres Encoding pro Bauelement gespeichert, wobei jedes Token angibt, ob der entsprechende Baustoff in den Schichten vorkommt. Dies ist wichtig, da Elemente mehrschichtig sein können. Das heisst, es können mehrere Baustoffe in einem Element hinterlegt sein. Beispielsweise können bei einer Aussenwand "Dämmung" und "Backstein" zugleich vorkommen.

=== Anzahl horizontaler Elemente unter- und oberhalb der Bauelemente
Bei planaren Objekten wie "Bodenplatten", "Decken" oder "Dächer" ist es für einen Klassifikationsalgorithmus schwierig, diese voneinander zu unterscheiden. Sie haben oft eine ähnliche Geometrie und unterscheiden sich nur minimal. Obwohl Dächer stets die obersten Elemente eines Gebäudes sind, fehlt diese räumliche Repräsentation bei den vorhandenen Features. Aus diesem Grund wird in der vorliegenden Arbeit eine sechste Kategorie vorgeschlagen, bei der für jedes Element die horizontalen Elemente unter- und oberhalb gezählt werden. Diese Kategorie wird im Folgenden als RAY-Kategorie bezeichnet, da sie mit einem Raycasting-Verfahren gelöst wird.

#figure(
  image("./img/overview_horizontal_elements_count.svg", width: 80%),
  caption: [Beispiele verschiedener Szenarien bei der Anzahl horizontaler Elemente über dem Bauelement],
)<overview_horizontal_elements_count>

Damit die Elemente gezählt werden können, werden vorerst alle horizontalen Elemente ausgewählt. Alle anderen Elemente werden von der Prüfung ausgeschlossen und mit #acr("NaN") versehen. Nach der Analyse erhalten diese Elemente den Wert "-1", da nicht alle #acr("ML")-Modelle mit #acr("NaN")-Werten umgehen können. Anschliessend wird für jedes Element der Mittelpunkt als Basis genommen. Modelle können bis zu drei Schichten pro Decke beinhalten. Aufbauten werden dabei ober- und unterhalb von tragenden Schichten einzeln modelliert. Der Mittelpunkt wird daher um ein Offset nach oben bzw. unten verschoben. Als Beispiel für Elemente oberhalb des Objektes dient die @overview_horizontal_elements_count. Das Gleiche gilt für Elemente unterhalb, indem der Mittelpunkt nach unten verschoben wird. Das Offset ist wichtig, damit die Aufbauten nicht mitgezählt werden.

=== Featurekorrelation
Um die Relevanz der extrahierten Features sowie deren Korrelation zu den Labels festzustellen, werden eine Korrelations-Heatmap und ein #acr("PCA")-Verfahren eingesetzt. Ziel ist es, frühzeitig Features ohne Mehrwert zu erkennen und entfernen. Über das #acr("PCA")-Verfahren kann des Weiteren abgeschätzt werden, wie komplex die Klassifikation zu den ausgewählten Labels (siehe @missing_values) ist.

== Behandlung untervertretener Klassen
Bei diversen Labels wie beispielsweise dem «vordefinierten Typ» gibt es Klassen, welche unterrepräsentiert sind. Diese können das Training beeinträchtigen und falsche Klassifikationen fördern. In der Arbeit wird mittels einer Schwellwertanalyse festgestellt, wie viele Samples pro Klasse mindestens vorhanden sein müssen, damit unterrepräsentierte Klassen das Training nicht negativ beeinflussen. Die Entfernung von unterrepräsentierten Klassen birgt das Risiko, dass bei einem Label nur noch eine Klasse verbleibt. Diese Labels sind für das Training redundant und werden vom Datensatz entfernt.

Als weitere Massnahme, um die untervertretenen Klassen nach dem Entfernen zu stärken, wird die Oversampling-Methode angewendet. Dabei werden untervertretene Label-Kombinationen aus allen vier Labels im Trainingsdatensatz gezielt mit Duplikaten ergänzt, damit ihre Repräsentation stärker gewichtet wird. Oversampling birgt das Risiko, dass sich das Modell bei zu vielen Duplikaten zu stark auf die untervertretenen Klassen konzentriert. Deshalb wird mittels einer Schwellwertanalyse der optimale Zielwert ermittelt, damit die Performance sich verbessert. Als Basismodell wird dafür das Modell #acr("RF") verwendet.

== Datensatzaufteilung<methods_data_splits>
Der Datensatz wird in drei Teilmengen für Training, Validierung und Evaluation aufgeteilt, wobei das Testset ausschliesslich für die finale Evaluation zurückgehalten wird. Zunächst werden 10 % als Testset reserviert und die verbleibenden 90 % werden mit 80 / 20 aufgeteilt @collins_assessing_2021. Dadurch umfasst das Trainingsset 72 %, das Validierungsset 18 % und das Testset 10 % des Datensatzes.

Um einen Data Leakage zu verhindern, wird jedes Projekt vollständig einem einzigen Split zugewiesen, sodass Bauelemente desselben Projekts nie in verschiedenen Teilmengen vorkommen. Die Stratifizierung basiert auf einem projektspezifischen Fingerprint, welcher binär kodiert, wie viele Elemente pro Labelwert im jeweiligen Projekt vorhanden sind. Damit wird sichergestellt, dass die Labelverteilung über alle drei Datensätze möglichst proportional erhalten bleibt, wobei die exakten Prozentanteile aufgrund der Projektgrössen abweichen können. Die Aufteilung erfolgt mit der Methode "MultilabelStratifiedShuffleSplit" der Bibliothek #link("https://pypi.org/project/iterative-stratification/")[iterstrat]. Nach der Aufteilung werden zwei Bereinigungsschritte durchgeführt:

- Elemente aus dem Validierungs- und Testset, deren Featurevektor identisch mit einem Trainingselement ist, werden entfernt.
- Klassen, die nicht in allen drei Splits vertreten sind, werden iterativ entfernt.

Durch diese Massnahmen wird ein Data Leakage weitgehend verhindert. Ein verbleibender Risikofaktor besteht darin, dass sich ähnliche Featurevektoren von unterschiedlichen Projekten im Validierungs- und Testset befinden könnten. Dadurch könnten beim finalen Evaluieren des Testsets die Metriken leicht überschätzt werden.

== Modellauswahl
Da bisher keine Arbeiten zur Klassifikation nach #acr("eBKP-H") existieren, legt diese Arbeit das Fundament für eine #acr("ML")-gestützte Klassifikation. Der Fokus liegt auf klassischen #acr("ML")-Algorithmen, da diese bei tabellarischen Daten häufig besser performen als neuronale Netzwerke und effizienter skalieren als regelbasierte Ansätze @dopazo_automated_2024 @wang_framework_2024.

Als Baselinemodelle werden Naive Bayes, Logistic Regression, #acr("KNN"), #acr("SVM") und #acr("DT") gewählt. In der Studie von #cite(<dopazo_automated_2024>, form: "prose") wurden #acr("KNN"), #acr("DT") und Logistic Regression für die Baukostenklassifikation als Baselinemodelle verwendet. Naive Bayes wurde als Baselinemodell für die #acr("BIM")-Clash-Detection eingesetzt @zabin_applications_2022. Zudem wird #acr("SVM") in diversen Arbeiten als Baselinemodell verwendet @zabin_applications_2022 @xu_automatic_2022, wobei der Algorithmus bei Fenster- und Türklassifikationen eine Accuracy von 88,0 % erreicht @slusarczyk_machine_2024.

Als finale Modelle werden die baumbasierten Ensembles #acr("RF"), #acr("ET"), #acr("LightGBM") und #acr("XGBoost") eingesetzt, da diese in vergleichbaren #acr("IFC")-Klassifikationen die robustesten und leistungsstärksten Algorithmen sind @xu_automatic_2022 @lyu_regionbased_2022 @wang_framework_2024 @dopazo_automated_2024. Ergänzend dazu werden die nativen Varianten "GradientBoosting" und "HistGradientBoosting" von #link("https://scikit-learn.org/stable/")[Scikit-learn] mittrainiert. Um die Reproduzierbarkeit zu gewährleisten wird ein statische Seed (42) gewählt.

Zum Vergleich mit neuronalen Netzwerken wird zusätzlich ein einfaches #acr("MLP")-Modell auf Basis von #link("https://pytorch.org")[PyTorch] trainiert. Das Modell verfügt über einen gemeinsamen Backbone sowie je einen Klassifikationskopf pro Label und unterstützt die Multi-Output-Klassifikation damit nativ.

== Vorverarbeitungs-Pipeline<methods_preprocessing>
Geometrische Features weisen häufig schiefe Verteilungen und Ausreisser auf, da Bauteilgeometrien in realen Projekten stark variieren. Je nach Modelltyp wird eine unterschiedliche Vorverarbeitung angewendet.

Für #acr("KNN"), #acr("SVM") und Logistic Regression wird eine dreistufige Pipeline eingesetzt. Zuerst werden Ausreisser mit einem #acr("IQR")-basierten Capper begrenzt, damit extreme Werte die nachfolgende Skalierung nicht verzerren. Danach wird eine Power-Transformation nach "Yeo-Johnson" angewendet, um schiefe Verteilungen anzugleichen. Abschliessend werden die Features auf einen Mittelwert von 0 und eine Standardabweichung von 1 normiert. Ohne diese Schritte würden beispielsweise #acr("KNN") und #acr("SVM")-Features mit grösseren Wertebereichen übergewichten, da beide auf Distanzberechnungen basieren. Bei der Logistic Regression würde die L2-Regularisierung ohne Normierung einzelne Features bevorzugen.

Naive Bayes erhält nur eine Power-Transformation nach "Yeo-Johnson", da das Modell für jedes Feature eine Gauss-Verteilung annimmt. Ausreisser und Skalierung sind dabei unproblematisch, weil die Wahrscheinlichkeiten über die geschätzte Varianz normalisiert werden.

Baumbasierte Modelle (#acr("DT"), #acr("RF"), #acr("ET"), #acr("XGBoost"), #acr("LightGBM"), GradientBoosting, HistGradientBoosting) benötigen keine Vorverarbeitung, da sie ausschliesslich auf Schwellwertvergleichen basieren und damit unabhängig von Skalierung und Verteilungsform sind. Das Gleiche gilt für das #acr("MLP")-Netzwerk, da die erste vollverbundene Schicht während des Trainings eine implizite Skalierung pro Feature über dessen Gewichte lernt.

== Multi-Output-Klassifikation<methods_multioutput>
Die vier ausgewählten Labels vom @missing_values stellen ein Multi-Output-Klassifikationsproblem dar, bei dem für jedes Label eine separate Vorhersage getroffen werden muss. Bei einem Multi-Output-Problem gibt es grundsätzlich zwei Möglichkeiten. Als erster Ansatz kann ein einzelnes Modell alle Labels gleichzeitig vorhersagen und dabei potenzielle Abhängigkeiten zwischen den Labels ausnutzen. Ein Problem dieses Ansatzes ist, dass das Modell nicht für jedes Label individuell optimiert wird und einzelne, seltenere Labels bei einer Prognose vernachlässigt werden können. Der zweite Ansatz besteht darin, pro Label ein eigenes #acr("ML")-Modell zu trainieren. Dieser Ansatz bietet für die vorliegende Arbeit mehrere Vorteile, indem jedes Label unabhängig optimiert und eine differenzierte Fehleranalyse pro Label ermöglicht wird. Zudem können Trainings- und Vorhersageschritte pro Label parallelisiert werden, was bei vier Labels eine Effizienzsteigerung bewirkt. Zuletzt ist dieser Ansatz mit Klassifikatoren kompatibel, welche per Standard keine Multi-Output-Klassifikation unterstützen, wie etwa #acr("SVM") oder logistische Regression.

Aus diesen Gründen wird für die vorliegende Arbeit bei den #acr("ML")-Modellen pro Label ein eigenständiges Modell trainiert. Beim #acr("MLP")-Modell wird hingegen der erste Ansatz gewählt, da neuronale Netzwerke ihre Stärke in der
gemeinsamen Repräsentation mehrerer Labels entfalten und damit Abhängigkeiten zwischen Labels nativ entwickeln können. Die Implementation der #acr("ML")-Modelle erfolgt mit der Bibliothek #link("https://scikit-learn.org/stable/")[Scikit-learn]. Klassifikatoren mit nativer Multi-Output-Unterstützung wie Random Forest und Extra Trees werden direkt eingesetzt. Bei allen übrigen Modellen wird "MultiOutputClassifier"-Wrapper entwickelt, welcher intern pro Label ein eigenständiges Modell trainiert.

== Feature-Selektion
Für die Feature-Selektion werden zwei Ansätze vorgeschlagen: Eine Feature-Gruppen-Analyse und eine stufenweise Schwellwertanalyse. Beide Analysen werden für #acr("RF") und #acr("XGBoost") separat durchgeführt, da unterschiedliche Modelle unterschiedliche Feature-Prioritäten aufweisen können.

Bei baumbasierten Modellen wie #acr("RF") und #acr("XGBoost") steht das Attribut "feature_importances\_" zur Verfügung, das angibt, wie wichtig die einzelnen Features für die Klassifikation der Labels sind. Beim #acr("RF") basiert der Wert auf der mittleren Abnahme der Gini-Impurity und wird über alle Bäume gemittelt. Beim #acr("XGBoost") wird der Gain verwendet, der misst, wie stark ein Feature zur Verbesserung der Vorhersagen beiträgt. Da beide Modelle Multi-Output nativ unterstützen, werden alle vier Labels gemeinsam trainiert und die Importances über alle Labels aggregiert. Die Features werden nach den sechs Hauptkategorien (GENERAL, AABB, TFBB, TOPO, MATERIAL, RAY) gruppiert dargestellt, um die Relevanz der einzelnen Featurekategorien interpretieren zu können.

Für die inkrementelle Schwellwertanalyse werden die Features sequenziell vom wichtigsten zum unwichtigsten hinzugefügt. Nach jeder Erweiterung wird das Modell neu trainiert und der Macro-F1-Score auf dem Validierungsset bewertet. Die Ergebnisse werden dabei als Performance-Kurve dargestellt. Der Punkt, an dem die Kurve abflacht und weitere Features keinen wesentlichen Mehrwert mehr bringen, wird als Knick bezeichnet. Die dort identifizierte Featureanzahl wird in den Feature-Konfigurationen für das Hyperparameter-Tuning berücksichtigt.

#pagebreak()
== Hyperparameter-Tuning
Modelle wie der #acr("RF") erzielen mit den Standardeinstellungen bereits gute Resultate. Dennoch ist das Tuning wichtiger Hyperparameter notwendig, um das Overfitting zu minimieren. Als Kandidaten werden der #acr("RF"), #acr("XGBoost") sowie das #acr("MLP")-Netzwerk ausgewählt. Die Plattform #link("https://wandb.ai")[#acr("WandB")] wird für das Tracking und die Orchestrierung der Sweep-Experimente eingesetzt und der Macro-F1-Score dient als Optimierungsmetrik auf dem Validierungsdatensatz.

Für den #acr("RF") wird Grid Search eingesetzt, die alle Parameterkombinationen durchläuft. Für #acr("XGBoost") wird Bayesian Optimization gewählt, die den Parameterraum iterativ auf Basis vorheriger Ergebnisse erkundet. Die Feature-Konfigurationen werden pro Modell anhand der Feature-Gruppen-Analyse und der Schwellwertanalyse ermittelt.

Dabei werden pro Modell vier unterschiedliche Feature-Kombinationen analysiert:
- Alle Features
- Die drei besten Feature-Gruppen-Kombinationen aus der Feature-Gruppen-Analyse
- Top-n Features aus dem ersten Knick der Schwellwertanalyse, separat für #acr("RF") und #acr("XGBoost")

Für das #acr("MLP")-Modell wird ebenfalls Bayesian Optimization eingesetzt und als Input dienen alle Features. Die vollständigen Parametersuchräume sind in @tab_hyperparam_rf, @tab_hyperparam_xgboost und @tab_hyperparam_nn im Anhang aufgeführt.

== Ensemble-Strategie <methods_ensemble>
Nach dem Tuning der drei Modelltypen #acr("RF"), #acr("XGBoost") und #acr("MLP") werden diese in der vorliegenden Arbeit zu einem Ensemble kombiniert. Der Grundgedanke dahinter ist, dass die einzelnen Modelle aufgrund ihrer unterschiedlichen Lernverfahren unterschiedliche Stärken und Schwächen aufweisen. Eine Kombination reduziert systematische Schwächen durch deren komplementäre Fehlermuster und verbessert die Generalisierung deutlich @sagi_ensemble_2018 @abualdenien_ensemble_learning_2022.

=== Soft Voting als finale Entscheidung
Als finale Entscheidungsstrategie für das #acr("EL")-Model wird Soft Voting vorgeschlagen. Mit diesem Vorgehen geben die drei Basismodelle für jedes Bauelement und jedes Label eine vollständige Wahrscheinlichkeitsverteilung über alle Klassen aus, diese werden elementweise gemittelt (@eq_soft_voting).

Anschliessend wird die Klasse mit der höchsten gemittelten Wahrscheinlichkeit pro Bauelement mit "$arg max(p_"avg")$" als finale Ensemble-Vorhersage gewählt. Soft Voting wird gegenüber Hard Voting bevorzugt, weil es unsichere Mehrheitsentscheidungen vermeidet. Im Vergleich zu komplexeren Aggregationen wie Stacking oder per-Klassen-Routing hat es zusätzlich den Vorteil, keine weiteren Hyperparameter zu benötigen. Dadurch ist es einfach reproduzierbar und die Entscheidungen pro Bauelement sind direkt erklär- und nachvollziehbar.

#figure(
  kind: math.equation,
  $ p_"avg" = (p_"rf" + p_"xgb" + p_"nn") / 3 $,
  caption: [Soft Voting der Klassenwahrscheinlichkeiten],
)<eq_soft_voting>

wobei $p_"rf"$, $p_"xgb"$ und $p_"nn"$ die Vektoren der Klassenwahrscheinlichkeiten der jeweiligen Modelle #acr("RF"), #acr("XGBoost") und #acr("MLP") bezeichnen und $p_"avg"$ die gemittelte Wahrscheinlichkeitsverteilung ergibt.

#pagebreak()
=== Analyse des Konfidenzniveaus für das Inferenzmodell<confidence_analysis>
Die direkte Verwendung des trainierten #acr("EL")-Modells würde für jedes Element bei neuen Modellen eine Klassenvorhersage erzeugen. Dies ist nicht im Sinne der Aufgabenstellung, da bei den vorhandenen Modellen viele nicht informierte Objekte aus dem Datensatz entfernt worden sind. Dadurch würden ungeeignete Objekte eine Klasse erhalten, welche falsch wäre. Aus diesem Grund soll ein geeigneter Schwellwert für das #acr("EL")-Modell analysiert werden, um ein praxistaugliches Modell zu gewährleisten und unsichere Vorhersagen zu eliminieren. Der Trade-off bei diesem Vorgehen besteht zwischen der Präzision der Vorhersagen und der Abdeckung aller Elemente.

Dazu wird pro Label ein Threshold der jeweiligen Wahrscheinlichkeiten eingeführt. Vorhersagen unter diesem Schwellwert werden zurückgehalten. Das Tuning des Hyperparameters erfolgt mittels des Validierungssets, indem für jeden Schwellwert die Trade-offs zwischen dem Anteil der Vorhersagen und der Precision beobachtet werden. Das Testset wird erst nach Fixierung der Schwellwerte einmalig zur Verifikation der Demo-Performance verwendet, um eine unverzerrte Schätzung der Generalisierung sicherzustellen.

== Fehleranalyse und Demo-Pipeline<methods_misclassification_demo>
Das finale Modell für die Demo wird anhand der zwei Projekte im Testset geprüft. Dadurch soll qualitativ analysiert werden, wie gut das Modell auf ein ungesäubertes #acr("IFC")-Modell performt und wie sich die Missklassifikationen charakterisieren und gruppieren lassen. Die Analyse erfolgt mittels einer Konfusionsmatrix pro Label, womit man alle korrekten, falschen und nicht geprüften Vorhersagen einsehen und analysieren kann. Diese Kategorien werden pro Projekt zu Paaren aggregiert, um Paare aus Ground-Truth und Vorhersage zu bilden. Dies soll anschliessend im @feedback_methods verwendet werden, um alle gruppierten Missklassifikationen visuell im Solibri darstellen zu können. Dadurch können die häufigsten Fehlerquellen identifiziert und eine Plausibilisierung der Praxis-Tauglichkeit gewährleistet werden.

=== Feedback Berichte für Fachpersonen<feedback_methods>
Um bereits schnell eine Übersicht der Klassifikationen zu bekommen, wird zuerst ein Excel-Bericht aus den Prognosen erstellt. In vier unterschiedlichen Arbeitsblättern soll aufgezeigt werden, welche Elemente falsch oder korrekt klassifiziert sind und welche nicht geprüft werden. Das erste Arbeitsblatt zeigt eine Übersicht aller Elemente über diese drei Klassifikationsgruppen. Zudem sollen die Fachpersonen auch einen Report direkt in ihr natives #acr("CAD") oder in das Solibri laden können. Dazu wird zusätzlich ein #acr("BCF") Bericht mit den Vorhersagepaaren aus dem @methods_misclassification_demo erstellt. Fachpersonen können dadurch direkt alle Bauelemente grafisch am #acr("IFC")-Modell überprüfen. Das Excel soll hauptsächlich den Fachpersonen der Bauökonomie für einen Sanity-Check dienen und das #acr("BCF") wird primär für die modellierenden Personen eingesetzt.

#pagebreak()
== Evaluierungsstrategie

=== Metriken
Als Hauptmetriken dienen der Macro-F1-Score (@eq_macro_avg) und der #acr("MCC") (@eq_mcc), da die Klasse "unknown" in diversen Labels dominant vertreten ist und dadurch ein Klassenungleichgewicht entsteht. Der Macro-F1-Score bildet den ungewichteten Durchschnitt des F1-Scores über alle Klassen und gewichtet damit untervertretene Klassen gleichwertig.

#figure(
  kind: math.equation,
  $ overline("F1")_"macro" = 1/C sum_(i=1)^(C) (2 dot "TP"_i) / (2 dot "TP"_i + "FP"_i + "FN"_i) $,
  caption: [Macro-F1-Score],
)<eq_macro_avg>

wobei $C$ die Gesamtanzahl Klassen, $"TP"_i$ die True Positives, $"FP"_i$ die False Positives und $"FN"_i$ die False Negatives der Klasse $i$ bezeichnen.

Der #acr("MCC") berücksichtigt alle Einträge der Konfusionsmatrix und ist dadurch robust gegenüber Klassenungleichgewichten, da er systematische Fehlklassifikationen stärker bestraft als zufällige. Beide Metriken werden pro Label berechnet und nicht über alle Labels aggregiert, was eine gezielte Fehleranalyse pro Label ermöglicht. Accuracy, Precision, Recall und gewichteter F1-Score werden ergänzend erfasst und dienen zur Fehleranalyse.

#figure(
  kind: math.equation,
  $ "MCC" = ("TP" times "TN" - "FP" times "FN") / sqrt(("TP"+"FP")("TP"+"FN")("TN"+"FP")("TN"+"FN")) $,
  caption: [#acr("MCC")],
)<eq_mcc>

wobei $"TP"$ True Positives, $"TN"$ True Negatives, $"FP"$ False Positives und $"FN"$ False Negatives bezeichnen.
