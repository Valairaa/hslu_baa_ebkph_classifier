#import "@preview/acrostiche:0.7.0": acr
#import "@preview/muchpdf:0.1.1": muchpdf
#import "/template/_helpers.typ": fmt, format_num, hint, image_grid, todo
#import "/template/_scheduling.typ": planning-gantt

= Appendix

== Eingereichte Aufgabenstellung<baa_task>
#muchpdf(
  read("./img/baa_task.pdf", encoding: none),
  width: 95%,
)

== 1. Interview mit dem Praxispartner<first_interview_gks>
#muchpdf(
  read("../../meetings/interviews/interview_01.pdf", encoding: none),
  width: 100%,
)

== 2. Interview mit dem Praxispartner<second_interview_gks>
#muchpdf(
  read("../../meetings/interviews/interview_02.pdf", encoding: none),
  width: 100%,
)

== Terminplan<project_timeline>
// ID, Bezeichnung, SW-Start, SW-Ende, Erledigt in %
#let meine-tasks = (
  (1, "Projekt-Setup und Einarbeitung", 1, 3, 100),
  (2, "Literaturrecherche", 1, 3, 100),
  (3, "Aufgabenstellung präzisieren", 1, 2, 100),
  (4, "eBKP-H Mapping erstellen", 2, 3, 100),
  (5, "Datenset erstellen", 2, 3, 100),
  (6, "Datenset für Labels erstellen", 3, 4, 100),
  (7, "Datenset mit Features und Labels zusammenführen", 3, 5, 100),
  (8, "Features aus IFC extrahieren", 3, 5, 100),
  (9, "DQA durchführen", 4, 5, 100),
  (10, "ML Basismodelle trainieren", 6, 7, 100),
  (11, "Komplexere ML-Modelle trainieren", 6, 7, 100),
  (12, "Einfaches MLP entwickeln inkl. Trainingspipeline", 6, 8, 100),
  (13, "Hyperparamter Tuning (RF, XGBoost, MLP)", 7, 9, 100),
  (14, "Analyse der besten Modelle", 8, 9, 100),
  (15, "Erstellung Ensemble Modell (RF, XGBoost, MLP)", 8, 9, 100),
  (16, "Implementation Soft Voting", 9, 11, 100),
  (17, "Confidence Threshold Analyse", 9, 11, 100),
  (18, "Analyse der Missklassifikationen von RF und XGBoost", 11, 12, 100),
  (19, "Erstellung Demo Modell und Feedbacks (Excel, BCF, JSON)", 12, 14, 100),
  (20, "Fazit und Ergebnisse aufbereiten", 13, 15, 100),
  (21, "Korrekturlesen & Feinschliff der Arbeit", 14, 16, 100),
)

// ── Chart rendern ─────────────────────────────────────────────
// Alle Parameter ausser `tasks` sind optional (haben Defaults).
#planning-gantt(
  tasks: meine-tasks,
  title: "Terminprogramm",
  start-day: 16,
  start-month: 2,
  start-year: 2026,
  n-weeks: 16,
)

== Zuweisungsmatrix für Geschossflächen

#figure(
  table(
    columns: 4,
    align: left,
    stroke: (x: none, y: none),
    table.hline(),
    [*Regel*], [*IFC-Entität*], [*Reference*], [*Klassifikation*],
    table.hline(),
    [R1], [IfcSpace], [GF;Geschossfläche], [C Konstruktion Gebäude],
    [R45], [IfcSpace], [GF;Geschossfläche], [C05 Ergänzende Leistung zu Konstruktion],
    [R48], [IfcSpace], [GF;Geschossfläche], [D Technik Gebäude],
    [R49], [IfcSpace], [GF;Geschossfläche], [D01 Elektroanlage],
    [R50], [IfcSpace], [GF;Geschossfläche], [D01.01 Anlage Erzeugung Starkstrom],
    [R51], [IfcSpace], [GF;Geschossfläche], [D01.02 Transformierung Starkstrom],
    [R52], [IfcSpace], [GF;Geschossfläche], [D01.03 Speicherung Starkstrom],
    [R53], [IfcSpace], [GF;Geschossfläche], [D01.04 Installation Starkstrom],
    [R54], [IfcSpace], [GF;Geschossfläche], [D01.05 Verbraucher Starkstrom: Leuchten],
    [R55], [IfcSpace], [GF;Geschossfläche], [D01.06 Verbraucher Starkstrom: Elektrogeräte],
    [R56], [IfcSpace], [GF;Geschossfläche], [D01.07 Anlage Erzeugung Schwachstrom],
    [R57], [IfcSpace], [GF;Geschossfläche], [D01.08 Transformierung Schwachstrom],
    [R58], [IfcSpace], [GF;Geschossfläche], [D01.09 Speicherung Schwachstrom],
    [R59], [IfcSpace], [GF;Geschossfläche], [D01.10 Installation Schwachstrom],
    [R60], [IfcSpace], [GF;Geschossfläche], [D01.11 Verbraucher Schwachstrom],
    [R61], [IfcSpace], [GF;Geschossfläche], [D02 Gebäudeautomation (B)],
    [R62], [IfcSpace], [GF;Geschossfläche], [D03 Sicherheitsanlage],
    [R64], [IfcSpace], [GF;Geschossfläche], [D04 Technische Brandschutzanlage (B)],
    [R74], [IfcSpace], [GF;Geschossfläche], [D06 Kältetechnische Anlage (B)],
    [R82], [IfcSpace], [GF;Geschossfläche], [D07 Lufttechnische Anlage (B)],
    [R90], [IfcSpace], [GF;Geschossfläche], [D08 Wassertechnische Anlage (B)],
    [R93], [IfcSpace], [GF;Geschossfläche], [D09 Abwassertechnische Anlage (B)],
    [R94], [IfcSpace], [GF;Geschossfläche], [D10 Gastechnische Anlage (B)],
    [R95], [IfcSpace], [GF;Geschossfläche], [D11 Anlage für Spezialmedien (B)],
    [R157], [IfcSpace], [GF;Geschossfläche], [F Bedachung Gebäude (B)],
    [R223], [IfcSpace], [GF;Geschossfläche], [G Ausbau Gebäude],
    [R251], [IfcSpace], [GF;Geschossfläche], [G05 Einbauten, Schutzeinrichtung zu Ausbau],
    [R259], [IfcSpace], [GF;Geschossfläche], [G05.06 Sonderbauteil (B)],
    [R260], [IfcSpace], [GF;Geschossfläche], [G05.07 Kleinbauteil, Schutzraumeinrichtung],
    [R261], [IfcSpace], [GF;Geschossfläche], [G06 Ergänzende Leistung zu Ausbau],
    [R264], [IfcSpace], [GF;Geschossfläche], [G06.03 Reinigung],
    [R265], [IfcSpace], [GF;Geschossfläche], [G06.04 Trocknung],
    table.hline(),
  ),
  caption: [Auszug aus der IDC-Zuweisungsmatrix: 32 unterschiedliche #acr("eBKP-H")-Klassen, bei denen IfcSpace mit Reference = GF; Geschossfläche als einziger informierter Eingangswert dient. Alle übrigen Features sind Wildcards (\*)],
)<tab_mapping_ifcspace_gf>

== Beispiel einer der Hilfsklassifikation "isExternal"

#figure(
  image("./img/eBKPh_isExternal.png", width: 93%),
  caption: [Bildausschnitt vom Projekt "ZUST" mit einem dreidimensionalen Schnitt druch das Gebäude der Hilfsklassifikation "isExternal" (Grün = Lage aussen, Rot = Lage innen)],
)<eBKPh_isExternal>

== Verteilung der Bauelemente pro Projekt und der Beziehung der eBKP-H Codes

#figure(
  image("./img/data_ebkph_sankey.svg", width: 93%),
  caption: [Verteilung der Bauelemente pro Projekt und deren Beziehung zwischen den Haupteigenschaften "IFC-Entität" und den drei Stellen vom eBKP-H Code],
)<data_ebkph_sankey>


== Schemata der extrahierten geometrischen Features

#figure(
  image("./img/overview_general_features.svg", width: 100%),
  caption: [Schema der allgemeinen geometrischen Features],
)<overview_general_features>

#figure(
  image("./img/overview_aabb_features.svg", width: 100%),
  caption: [Schema der AABB Features],
)<overview_aabb_features>

#figure(
  image("./img/overview_tfbb_features.svg", width: 100%),
  caption: [Schema der TFBB Features],
)<overview_tfbb_features>

#figure(
  image("./img/overview_topo_features.svg", width: 100%),
  caption: [Schema der topologischen Features],
)<overview_topo_features>

== Übersicht der extrahierten geometrischen Features

#figure(
  kind: table,
  table(
    columns: (0.27fr, 0.73fr),
    align: (center + horizon, left + horizon),
    inset: (x: 6pt, y: 5pt),
    stroke: (x: none, y: 0.5pt + luma(180)),

    table.header(
      table.cell(fill: luma(210))[*Hauptkategorie*],
      table.cell(fill: luma(210))[*Feature*],
    ),

    table.cell(rowspan: 6, fill: luma(235), align: center + horizon)[
      *Allgemeine\ geometrische\ Features*\ _(12)_
    ],
    [geom_volume, geom_surface_area, geom_projected_area],
    [geom_centroid_x, geom_centroid_y, geom_centroid_z],
    [geom_z_min, geom_z_max, geom_z_range],
    [geom_ratio_area_vol],
    [geom_compactness],
    [geom_layer_count],

    table.cell(rowspan: 6, fill: luma(235), align: center + horizon)[
      *achsenausgerichtete\ Begrenzungsbox*\ _(14)_
    ],
    [aabb_min_x, aabb_min_y, aabb_min_z],
    [aabb_max_x, aabb_max_y, aabb_max_z],
    [aabb_len_x, aabb_len_y, aabb_len_z],
    [aabb_ratio_z_x, aabb_ratio_z_y, aabb_ratio_x_y],
    [aabb_diagonal],
    [aabb_volume],

    table.cell(rowspan: 5, fill: luma(235), align: center + horizon)[
      *objektausgerichtete\ Begrenzungsbox*\ _(13)_
    ],
    [tfbb_extent_0, tfbb_extent_1, tfbb_extent_2],
    [tfbb_volume],
    [tfbb_ratio_01, tfbb_ratio_02, tfbb_ratio_12],
    [tfbb_linearity, tfbb_planarity, tfbb_sphericity],
    [tfbb_primary_ax_x, tfbb_primary_ax_y, tfbb_primary_ax_z],

    table.cell(rowspan: 9, fill: luma(235), align: center + horizon)[
      *Topologische\ Invarianten*\ _(9)_
    ],
    [topo_vertex_count],
    [topo_face_count],
    [topo_unique_edge_count],
    [topo_euler_characteristic],
    [topo_genus],
    [topo_max_face_area],
    [topo_avg_face_area],
    [topo_vertex_edge_ratio],
    [topo_connected_components],

    table.cell(rowspan: 6, fill: luma(235), align: center + horizon)[
      *Materialität*\ _(23)_
    ],
    [mat_beton, mat_zement, mat_mörtel, mat_backstein],
    [mat_kalksandstein, mat_naturstein, mat_kunststein],
    [mat_aluminium, mat_metall, mat_stahl],
    [mat_holz, mat_glas, mat_foamglas, mat_kunststoff],
    [mat_dämm, mat_gips, mat_putz, mat_belag, mat_bekleidung],
    [mat_kies, mat_keramik, mat_allgemein, mat_werkstoff],

    table.cell(rowspan: 3, fill: luma(235), align: center + horizon)[
      *Horizontale\ Elemente*\ _(2)_
    ],
    [horizontal_elements_above],
    [horizontal_elements_below],
    [],
  ),
  caption: [Übersicht der extrahierten geometrischen Features als Input für die Klassifikation der Bauelemente nach den ausgewählten Labels],
) <tab_extracted_geometric_features>

== Feature Korrelation der extrahierten Features mittels Heatmap<feature_correlation_heatmap>

#figure(
  image("./img/feature_label_ifc_entity_correlation_heatmap_label_ifc_entity.svg", width: 100%),
  caption: [Korrelations-Heatmap der extrahierten Features zum Label "IFC-Entität"],
)<heatmap_label_ifc_entity>

#figure(
  image("./img/feature_label_predefined_type_correlation_heatmap_label_predefined_type.svg", width: 100%),
  caption: [Korrelations-Heatmap der extrahierten Features zum Label "Vordefinierter Typ"],
)<heatmap_label_predefined_type>

#figure(
  image("./img/feature_label_is_external_correlation_heatmap_label_is_external.svg", width: 100%),
  caption: [Korrelations-Heatmap der extrahierten Features zum Label "Lage der Bauteile"],
)<heatmap_label_is_external>

#figure(
  image("./img/feature_label_load_bearing_correlation_heatmap_label_load_bearing.svg", width: 100%),
  caption: [Korrelations-Heatmap der extrahierten Features zum Label "Tragende Funktion"],
)<heatmap_label_load_bearing>

== Feature Korrelation der extrahierten Features mittels PCA<feature_correlation_pca>

#figure(
  image("./img/feature_label_ifc_entity_pca_projection_label_ifc_entity.svg", width: 100%),
  caption: [PCA-Projektion der extrahierten Features zum Label "IFC-Entität"],
)<pca_label_ifc_entity>

#figure(
  image("./img/feature_label_predefined_type_pca_projection_label_predefined_type.svg", width: 100%),
  caption: [PCA-Projektion der extrahierten Features zum Label "Vordefinierter Typ"],
)<pca_label_predefined_type>

#figure(
  image("./img/feature_label_is_external_pca_projection_label_is_external.svg", width: 100%),
  caption: [PCA-Projektion der extrahierten Features zum Label "Lage der Bauteile"],
)<pca_label_is_external>

#figure(
  image("./img/feature_label_load_bearing_pca_projection_label_load_bearing.svg", width: 100%),
  caption: [PCA-Projektion der extrahierten Features zum Label "Tragende Funktion"],
)<pca_label_load_bearing>

#pagebreak()
== Performance der Feature-Gruppen-Analyse<feature_group_performance>

#let feature_group_table(path, caption) = figure(
  kind: table,
  table(
    columns: (2.2fr, 0.4fr, 1.0fr, 0.9fr, 0.7fr, 0.8fr, 0.7fr),
    align: (left, center, center, center, center, center, center),
    stroke: (x: none, y: none),

    table.hline(),
    [*Kombination*], [*n*], [*IFC-Entität*], [*Vord. Typ*], [*Lage*], [*Tragend*], [*Mean*],
    table.hline(),

    ..json(path)
      .slice(0, 10)
      .map(row => (
        [#row.at("features", default: [---])],
        [#row.n_features],
        [#fmt(row.label_ifc_entity)],
        [#fmt(row.label_predefined_type)],
        [#fmt(row.label_is_external)],
        [#fmt(row.label_load_bearing)],
        [#fmt(row.mean_f1_macro)],
      ))
      .flatten(),

    table.hline(),
  ),
  caption: caption,
)

#feature_group_table(
  "../../code/4_modeling/4_1_train ML models/feature_group_evaluation_random_forest.json",
  [Die zehn besten Feature-Gruppen-Kombinationen für das RF-Modell, sortiert nach dem über alle vier Labels gemittelten Macro-F1-Wert auf dem Validierungsdatensatz],
)<tab_feature_group_rf>

#feature_group_table(
  "../../code/4_modeling/4_2_train advanced ML models/feature_group_evaluation_xgboost.json",
  [Die zehn besten Feature-Gruppen-Kombinationen für das XGBoost-Modell, sortiert nach dem über alle vier Labels gemittelten Macro-F1-Wert auf dem Validierungsdatensatz],
)<tab_feature_group_xgboost>

== Feature-Importance der Modelle RF und XGBoost<feature_importance_ranking>

#let feature_importance_table(path, caption) = figure(
  kind: table,
  table(
    columns: (2fr, 1fr),
    align: (left, center),
    stroke: (x: none, y: none),

    table.hline(),
    [*Feature*], [*Importance*],
    table.hline(),

    ..json(path).slice(0, 20).map(row => ([#row.feature], [#fmt(row.importance)])).flatten(),

    table.hline(),
  ),
  caption: caption,
)

#feature_importance_table(
  "../../code/4_modeling/4_1_train ML models/feature_importance_random_forest.json",
  [Die 20 wichtigsten Features des RF-Modells, basierend auf der mittleren Abnahme der Gini-Impurity (über alle vier Labels gemittelt)],
)<tab_feature_importance_rf>

#feature_importance_table(
  "../../code/4_modeling/4_2_train advanced ML models/feature_importance_xgboost.json",
  [Die 20 wichtigsten Features des XGBoost-Modells, basierend auf dem Gain (über alle vier Labels gemittelt)],
)<tab_feature_importance_xgboost>
#pagebreak()

== Hyperparameter-Suchräume<H:hyperparam_spaces>

#figure(
  table(
    columns: 2,
    align: left,
    stroke: (x: none, y: none),
    table.hline(),
    [*Parameter*], [*Wertebereich*],
    table.hline(),
    [n_estimators], [{50, 100, 150, 200}],
    [max_depth], [{50, 100, 125, 150, 175, 200}],
    [min_samples_split], [{2, 4, 8}],
    [min_samples_leaf], [{1, 2, 4}],
    [bootstrap], [{True, False}],
    [training_oversample], [{True, False}],
    table.hline(),
  ),
  caption: [Hyperparameter-Suchraum für Random Forest],
)<tab_hyperparam_rf>

#figure(
  table(
    columns: 3,
    align: left,
    stroke: (x: none, y: none),
    table.hline(),
    [*Parameter*], [*Verteilung*], [*Wertebereich*],
    table.hline(),
    [max_depth], [ganzzahlig gleichverteilt], [0 bis 10],
    [min_child_weight], [ganzzahlig gleichverteilt], [0 bis 10],
    [gamma], [gleichverteilt], [0,0 bis 5,0],
    [reg_alpha], [gleichverteilt], [0,0 bis 10,0],
    [reg_lambda], [gleichverteilt], [0,0 bis 5,0],
    [colsample_bytree], [gleichverteilt], [0,5 bis 1,0],
    [colsample_bylevel], [gleichverteilt], [0,5 bis 1,0],
    [subsample], [gleichverteilt], [0,3 bis 1,0],
    [learning_rate], [log-gleichverteilt], [0,005 bis 0,3],
    [n_estimators], [diskret], [{200, 500, 1000}],
    [training_oversample], [diskret], [{True, False}],
    table.hline(),
  ),
  caption: [Hyperparameter-Suchraum für XGBoost],
)<tab_hyperparam_xgboost>

#figure(
  table(
    columns: 3,
    align: left,
    stroke: (x: none, y: none),
    table.hline(),
    [*Parameter*], [*Verteilung*], [*Wertebereich*],
    table.hline(),
    [n_hidden], [diskret], [{128, 256, 512, 768, 1024}],
    [dropout], [gleichverteilt], [0,1 bis 0,5],
    [learning_rate], [log-gleichverteilt], [$10^(-8)$ bis $10^(-1)$],
    [batch_size], [diskret], [{64, 128, 256}],
    [epochs], [fix], [200],
    [training_oversample], [diskret], [{True, False}],
    table.hline(),
  ),
  caption: [Hyperparameter-Suchraum für das Multilayer-Perceptron-Netzwerk],
)<tab_hyperparam_nn>

== Fehlermatrix vom Ensemble-Modelle auf dem Validationset<confusion_matrix_ensemble_validation>

#figure(
  image("./img/confusion_matrix_ifc_entity_validation.svg", width: 110%),
  caption: [Fehlermatrix vom Label "IFC-Entität" beim finalen Ensemble-Modell auf dem Validierungsdatensatz],
)<confusion_matrix_ifc_entity_validation>

#figure(
  image("./img/confusion_matrix_predefined_type_validation.svg", width: 110%),
  caption: [Fehlermatrix vom Label "predefined Type" beim finalen Ensemble-Modell auf dem Validierungsdatensatz],
)<confusion_matrix_predefined_type_validation>

#figure(
  image("./img/confusion_matrix_is_external_load_bearing_validation.svg", width: 110%),
  caption: [Fehlermatrix vom Label "isExternal" und "Load Bearing" beim finalen Ensemble-Modell auf dem Validierungsdatensatz],
)<confusion_matrix_is_external_load_bearing_validation>


== Fehlermatrix vom Ensemble-Modelle auf dem Testset<confusion_matrix_ensemble_testset>

#figure(
  image("./img/confusion_matrix_predefined_type_testset.svg", width: 110%),
  caption: [Fehlermatrix vom Label "predefined Type" beim finalen Ensemble-Modell auf dem Test-Datensatz],
)<confusion_matrix_predefined_type_testset>

#figure(
  image("./img/confusion_matrix_is_external_load_bearing_testset.svg", width: 110%),
  caption: [Fehlermatrix vom Label "isExternal" und "Load Bearing" beim finalen Ensemble-Modell auf dem Test-Datensatz],
)<confusion_matrix_is_external_load_bearing_testset>

== Missklassifikationen vom Demo-Modell beim Projekt "LUMU"<missclassifications_demo>
#let misclass_dir = "./img/demo_missclassifications/"
#let misclass_fig(images, caption) = image_grid(
  images.map(name => image(misclass_dir + name, width: 100%)),
  caption,
)

#misclass_fig(
  (
    "need_manual_review_01.png",
    "need_manual_review_02.png",
    "need_manual_review_03.png",
    "need_manual_review_04.png",
  ),
  [Zeigt alle Elemente, welche durch den Confidence-Schwellwert nicht geprüft wurden und eine manuelle Überprüfung benötigen],
)<fig_misclass_need_manual_review>

#misclass_fig(
  (
    "predefined_type-is_BASESLAB-should_FLOOR_01.png",
    "predefined_type-is_BASESLAB-should_FLOOR_02.png",
  ),
  [Label: "Vordefinierter Typ", Ist-Klassifikation: "BASESLAB", Modellvorschlag: "FLOOR". Bei diesen Elementen handelt es sich um Geschossdecken bei den Balkonen und der vorgeschlagene Wert vom Modell ist korrekt],
)<fig_misclass_baseslab_floor>


#misclass_fig(
  (
    "predefined_type-is_NOTDEFINED-should_GUARDRAIL_01.png",
    "predefined_type-is_NOTDEFINED-should_GUARDRAIL_02.png",
    "predefined_type-is_NOTDEFINED-should_GUARDRAIL_03.png",
    "predefined_type-is_NOTDEFINED-should_GUARDRAIL_04.png",
  ),
  [Label: "Vordefinierter Typ", Ist-Klassifikation: "NOTDEFINED", Modellvorschlag: "GUARDRAIL". Das Modell präzisiert korrekt die Elemente und die vorhandenen Informationen sind zu wenig informiert mit "NOTDEFINED"],
)<fig_misclass_notdefined_guardrail>

#misclass_fig(
  (
    "predefined_type-is_NOTDEFINED-should_COLUMN_01.png",
    "predefined_type-is_NOTDEFINED-should_COLUMN_02.png",
  ),
  [Label: "Vordefinierter Typ", Ist-Klassifikation: "NOTDEFINED", Modellvorschlag: "COLUMN". Die Stützen sind bereits mit "NOTDEFINED" genügend korrekt, die weitere Spezifikation ist korrekt, aber wird nicht benötigt],
)<fig_misclass_notdefined_column>

#misclass_fig(
  (
    "predefined_type-is_NOTDEFINED-should_PARTITIONING_01.png",
    "predefined_type-is_NOTDEFINED-should_PARTITIONING_02.png",
    "predefined_type-is_NOTDEFINED-should_PARTITIONING_03.png",
    "predefined_type-is_NOTDEFINED-should_PARTITIONING_04.png",
  ),
  [Label: "Vordefinierter Typ", Ist-Klassifikation: "NOTDEFINED", Modellvorschlag: "PARTITIONING". Das Modell präzisiert korrekt die Elemente und die vorhandenen Informationen sind zu wenig informiert mit "NOTDEFINED"],
)<fig_misclass_notdefined_partitioning>

#misclass_fig(
  (
    "predefined_type-is_NOTDEFINED-should_FLAT_ROOF_01.png",
    "predefined_type-is_NOTDEFINED-should_FLAT_ROOF_02.png",
  ),
  [Label: "Vordefinierter Typ", Ist-Klassifikation: "NOTDEFINED", Modellvorschlag: "FLAT_ROOF". Die meisten dieser Elemente sind vom Modell falsch vorgeschlagen worden, jedoch haben sie ähnliche Geometrien wie ein Flachdach und sind für das Modell schwierig zu unterscheiden],
)<fig_misclass_notdefined_flat_roof>

#misclass_fig(
  (
    "predefined_type-is_NOTDEFINED-should_PLUMBINGWALL_01.png",
    "predefined_type-is_NOTDEFINED-should_PLUMBINGWALL_02.png",
    "predefined_type-is_NOTDEFINED-should_PLUMBINGWALL_03.png",
    "predefined_type-is_NOTDEFINED-should_PLUMBINGWALL_04.png",
  ),
  [Label: "Vordefinierter Typ", Ist-Klassifikation: "NOTDEFINED", Modellvorschlag: "PLUMBINGWALL". Das Modell präzisiert korrekt die Elemente und die vorhandenen Informationen sind zu wenig informiert mit "NOTDEFINED"],
)<fig_misclass_notdefined_plumbingwall>

#misclass_fig(
  (
    "predefined_type-is_NOTDEFINED-should_SOLIDWALL_01.png",
    "predefined_type-is_NOTDEFINED-should_SOLIDWALL_02.png",
    "predefined_type-is_NOTDEFINED-should_SOLIDWALL_03.png",
    "predefined_type-is_NOTDEFINED-should_SOLIDWALL_04.png",
  ),
  [Label: "Vordefinierter Typ", Ist-Klassifikation: "NOTDEFINED", Modellvorschlag: "SOLIDWALL". Die Wände sind bereits mit "NOTDEFINED" genügend korrekt, die weitere Spezifikation ist korrekt, aber wird nicht benötigt],
)<fig_misclass_notdefined_solidwall>

#misclass_fig(
  (
    "predefined_type-is_NOTDEFINED-should_WINDOW_01.png",
    "predefined_type-is_NOTDEFINED-should_WINDOW_02.png",
    "predefined_type-is_NOTDEFINED-should_WINDOW_03.png",
    "predefined_type-is_NOTDEFINED-should_WINDOW_04.png",
  ),
  [Label: "Vordefinierter Typ", Ist-Klassifikation: "NOTDEFINED", Modellvorschlag: "WINDOW". Das ist eine falsche Klassifikation, das Modell schlägt bei Schränken vor, dass es sich um Fenster handelt. Grund dazu sind die ähnlichen Geometrien der beiden Klassen],
)<fig_misclass_notdefined_window>

#misclass_fig(
  (
    "predefined_type-is_WINDOW-should_FLOOR_01.png",
    "predefined_type-is_WINDOW-should_FLOOR_02.png",
    "predefined_type-is_WINDOW-should_FLOOR_03.png",
    "predefined_type-is_WINDOW-should_FLOOR_04.png",
  ),
  [Label: "Vordefinierter Typ", Ist-Klassifikation: "WINDOW", Modellvorschlag: "FLOOR". Das Modell liegt hier richtig, dass ein Fehler vorliegt. Die Elemente wären korrekt als Fassadenbekleidung zu klassifizieren. Das Modell schlägt hier jedoch "FLOOR" vor, was falsch ist, jedoch erkennt es, dass es sich primär um einen Fehler handelt. Die Höhe und das verwendete Material der Fensterbänke sind ähnlich wie die der Decken, deshalb schlägt es "FLOOR" vor],
)<fig_misclass_window_floor>

#misclass_fig(
  (
    "predefined_type-is_WINDOW-should_SOLIDWALL_01.png",
    "predefined_type-is_WINDOW-should_SOLIDWALL_02.png",
  ),
  [Label: "IFC-Entität", "Vordefinierter Typ", Ist-Klassifikation: "WINDOW", Modellvorschlag: "SOLIDWALL". Das Modell liegt hier korrekt. Es handelt sich um Wände, welche fälschlicherweise als Fenster klassifiziert worden sind. Das ist falsch und das Modell konnte den Fehler korrekt identifizieren],
)<fig_misclass_window_solidwall>


== Verwendete Tools<used_tools>

Während der Bearbeitung dieser Arbeit wurden folgende Werkzeuge verwendet:
- Claude Code#footnote[https://claude.com/product/claude-code]
- GitHub Copilot#footnote[https://github.com/features/copilot]

Für das Korrekturlesen wurden folgende Werkzeuge verwendet:
- Claude Code#super("6")
- Grammarly#footnote[https://www.grammarly.com/]
