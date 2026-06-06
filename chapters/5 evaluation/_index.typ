#import "@preview/acrostiche:0.7.0": acr
#import "/template/_helpers.typ": delta_pct, fmt, hint, todo

= Validation und Evaluation <evaluation>

== Evaluierung der unterschiedlichen Schwellwertanalysen<eval_rare_classes_threshold>
Aufgrund der unterschiedlichen Datenaufteilungen ergibt sich die Möglichkeit, aus dieser Not eine Tugend zu machen. Wenn beide Analysen der unterschiedlichen Projektkombinationen untersucht werden, wird in den Abbildungen ersichtlich, wie unterschiedlich die Geometrien pro Projekt sind und dementsprechend die Modelle die Muster gewisser Klassen besser lernen können. Ein Beispiel dazu ist die Klasse "IfcCovering" der #acr("IFC")-Entität. Beim ersten Split in der @learning_curve_label_ifc_entity kann gesehen werden, dass das #acr("RF")-Modell bereits erste Muster für "IfcCovering" erkennen kann und mit der Zunahme der Samples die Performance steigt. Wenn jedoch andere Projekte für Training und Evaluierung herangezogen werden, dann ist das Lernverhalten dieser Klasse nicht mehr gewährleistet, wie in der @learning_curve_validated_label_ifc_entity ersichtlich ist. Gleiche Verhaltensmuster wurden auch bei den Klassen "PARAPET", "PARTITIONING", "WASHHANDBASIN" und "FLOORING" bei den vordefinierten Typen und bei "IfcRoof" bei der "#acr("IFC")-Entität" erkannt. Jedoch wurde aufgrund von Softwareupdates im ArchiCAD der vordefinierte Typ von "FLOOR" auf "FLOORING" geändert, was somit keinen Fehler darstellt.

== Gesamtübersicht der Modellperformances

#let baseline_metrics = json("../../code/4_modeling/4_1_train ML models/baseline_model_metrics.json")
#let advanced_metrics = json("../../code/4_modeling/4_2_train advanced ML models/advanced_model_metrics.json")
#let all_model_metrics = baseline_metrics + advanced_metrics

#figure(
  table(
    columns: (2.3fr, 1fr, 1.2fr, 1.1fr, 1fr, 1.2fr),
    align: (left, center, center, center, center, center, center),
    stroke: (x: none, y: none),

    table.hline(),
    [], table.cell(colspan: 2, align: center)[*Training*], table.cell(colspan: 3, align: center)[*Validierung*],
    table.hline(start: 1, end: 3), table.hline(start: 3, end: 7),
    [*Modell*], [*MCC*], [*F1-Macro*], [*Accuracy*], [*MCC*], [*F1-Macro*],
    table.hline(),

    ..all_model_metrics
      .map(row => (
        [#row.model],
        [#fmt(row.train_mcc)],
        [#fmt(row.train_f1_macro)],
        [#fmt(row.val_accuracy)],
        [#fmt(row.val_mcc)],
        [#fmt(row.val_f1_macro)],
      ))
      .flatten(),

    table.hline(),
  ),
  caption: [Trainings- und Validierungsmetriken aller getesteten Baseline- und komplexeren #acr("ML")-Modelle, trainiert auf dem oversampelten Datensatz und über die vier Labels gemittelt],
)<tab_all_models_comparison>

Beim Training der unterschiedlichen #acr("ML")-Modelle sind bei allen Modellen ausser beim Modell "Naive Bayes" gute Resultate erzielt worden. Zudem liegt die Performance bei baumähnlichen und Ensemble-Modellen am höchsten, wie in der @tab_all_models_comparison sichtbar ist. Ein gutes Indiz für das Verhalten der Modelle liegt beim Vergleich zwischen den Trainings- und Validierungsdaten. Die Modelle lernen bereits sehr gute Muster basierend auf den gegebenen Trainingsprojekten. Bei der Generalisierung zeigen sich jedoch bereits erste Schwächen der Modelle. Dies zeigt sich daran, dass die Metriken für die Validierung bis zu 39,7 % sinken können, wie bei #acr("DT") bei der Metrik #acr("MCC") zu sehen ist.

=== Einfluss vom Oversampling
Wie in der @tab_oversampling_comparison ersichtlich ist, bringt "Oversampling" einen Gewinn in der Performance für alle drei Modelle. Besonders beim Macro-F1-Wert ist der Gewinn bei den Modellvorhersagen ersichtlich. Bei der Metrik #acr("MCC") dagegen schneidet nur das #acr("RF")-Modell besser ab als ohne "Oversampling". Diese Tendenz basiert auf der Tatsache, dass die Schwellwertanalyse im @oversampling_implementation ausschliesslich für das #acr("RF")-Modell gemacht wurde. Aus diesem Grund ist es nachvollziehbar, dass dieses Modell am meisten vom Oversampling profitiert. Aufgrund der Anreicherung des Datensatzes durch die wenigen Duplikate, welche bei untervertretenen Klassen angewendet wurden, ist das Risiko eines zusätzlichen "Overfitting" gering.

#let best_runs = json(
  "../../code/5_evaluation/5_1_get_best_runs_wandb/best_by_model_type.json",
)

#let rf_os = best_runs.random_forest.oversampling.best_val_f1_macro.metrics
#let rf_no = best_runs.random_forest.no_oversampling.best_val_f1_macro.metrics
#let xgb_os = best_runs.xgboost.oversampling.best_val_f1_macro.metrics
#let xgb_no = best_runs.xgboost.no_oversampling.best_val_f1_macro.metrics
#let nn_os = best_runs.plain_neural_network.oversampling.best_val_f1_macro.metrics
#let nn_no = best_runs.plain_neural_network.no_oversampling.best_val_f1_macro.metrics

#figure(
  table(
    columns: (1.6fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, center, center, center, center, center, center),
    stroke: (x: none, y: none),

    table.hline(),
    [], table.cell(colspan: 3, align: center)[*Macro-F1*], table.cell(colspan: 3, align: center)[*MCC*],
    table.hline(start: 1, end: 4), table.hline(start: 4, end: 7),
    [*Modell*], [*mit OS*], [*ohne OS*], [*Δ*], [*mit OS*], [*ohne OS*], [*Δ*],
    table.hline(),

    [Random Forest],
    [#fmt(rf_os.at("val/f1_macro"))],
    [#fmt(rf_no.at("val/f1_macro"))],
    [#delta_pct(rf_os.at("val/f1_macro"), rf_no.at("val/f1_macro"))],
    [#fmt(rf_os.at("val/mcc"))],
    [#fmt(rf_no.at("val/mcc"))],
    [#delta_pct(rf_os.at("val/mcc"), rf_no.at("val/mcc"))],

    [XGBoost],
    [#fmt(xgb_os.at("val/f1_macro"))],
    [#fmt(xgb_no.at("val/f1_macro"))],
    [#delta_pct(xgb_os.at("val/f1_macro"), xgb_no.at("val/f1_macro"))],
    [#fmt(xgb_os.at("val/mcc"))],
    [#fmt(xgb_no.at("val/mcc"))],
    [#delta_pct(xgb_os.at("val/mcc"), xgb_no.at("val/mcc"))],

    [Neural Network],
    [#fmt(nn_os.at("val/f1_macro"))],
    [#fmt(nn_no.at("val/f1_macro"))],
    [#delta_pct(nn_os.at("val/f1_macro"), nn_no.at("val/f1_macro"))],
    [#fmt(nn_os.at("val/mcc"))],
    [#fmt(nn_no.at("val/mcc"))],
    [#delta_pct(nn_os.at("val/mcc"), nn_no.at("val/mcc"))],
    table.hline(),
  ),
  caption: [Vergleich der besten Validierungsresultate mit und ohne Oversampling (OS) pro Modelltyp],
)<tab_oversampling_comparison>

== Hyperparameter-Tuning
Wie in der @tab_best_runs_per_sweep aufgeführt wird, ist das beste Modell über alle Feature-Kombinationen #acr("XGBoost"). Das Modell konnte einen Macro-F1-Wert von 0,7276 und einen MCC von 0,7035 auf dem Validierungsset erreichen. Die Einstellungen dazu waren die besten 35 Features und es konnte sich gegenüber dem Run mit allen 73 Features um 0,0052 verbessern. Dies zeigt, dass für #acr("XGBoost") nicht alle Features von Relevanz sind. Beim #acr("RF")-Modell dagegen ist der beste Run jener mit den Kategorien (gen + mat + ray). Dies zeigt, dass beide Analysen basierend auf den Kategorien und den Top-N-Features von Relevanz waren. Bei diesem Modell haben die Top-N-Features beim Macro-F1 um 0,0302 und 0,0337 schlechter abgeschnitten.

#let best_runs_per_sweep = json("../../code/5_evaluation/5_1_get_best_runs_wandb/best_runs_per_sweep.json")
// "general_topo_ray_categories"-Sweeps werden ausgeschlossen
#let best_per_sweep = (
  best_runs_per_sweep
    .values()
    .map(runs => runs.at(0))
    .filter(row => not row.sweep_name.ends-with("general_topo_ray_categories"))
    .sorted(key: row => -row.at("val/f1_macro"))
)
#let model_display = (
  "plain_neural_network": "MLP",
  "xgboost": "XGBoost",
  "random_forest": "Random Forest",
)
#let feature_count_by_config = (
  "all categories": 73,
  "top 9 features": 9,
  "top 35 features": 35,
  "general material ray categories": 37,
)

#figure(
  table(
    columns: (1.6fr, 2.6fr, 1fr, 1.2fr, 1.1fr),
    align: (left, left, center, center, center, center),
    stroke: (x: none, y: none),

    table.hline(),
    [*Modell*], [*Einstellungen*], [*Features*], [*MCC*], [*Macro-F1*],
    table.hline(),

    ..best_per_sweep
      .map(row => {
        let config = row.sweep_name.split("_").slice(1).join(" ")
        (
          [#model_display.at(row.model_type)],
          [#config],
          [#feature_count_by_config.at(config)],
          // bugfix of not tracked mlp mcc score, for now ok for the report
          if row.at("val/mcc") == none { [#fmt(nn_os.at("val/mcc"))] } else { [#fmt(row.at("val/mcc"))] },
          [#fmt(row.at("val/f1_macro"))],
        )
      })
      .flatten(),

    table.hline(),
  ),
  caption: [Bester Run pro Wandb-Sweep mit Oversampling und über alle vier Labels gemittelt auf Basis vom Validierungsdatensatz (absteigend nach F1-Macro sortiert)],
)<tab_best_runs_per_sweep>

Das #acr("MLP")-Modell wurde lediglich basierend auf allen Features trainiert und hier zeigt sich bereits ein Trend. Die Performance vom Macro-F1 liegt bei 0,6784 und zeigt eine Verschlechterung von 0,0492 gegenüber dem besten #acr("XGBoost")-Modell. Gegenüber den Modellen ohne Tuning konnten sich die Modelle #acr("XGBoost") um 1,08 % und #acr("RF") um 0,81 % beim Macro-F1-Wert verbessern (@tab_all_models_comparison). Die Suchbereiche für das Tuning sind im Anhang in @tab_hyperparam_rf, @tab_hyperparam_xgboost und @tab_hyperparam_nn ersichtlich.

== Soft-Vote-Ensemble der drei Modelle
Die Methode vom finalen Soft-Vote-Ensemble-Modell wurde im @methods_ensemble methodisch erläutert und die technische Umsetzung ist im @implementation_ensemble zu finden.

=== Ergebnisse bei der Evaluation vom Testset<results_ensemble_testset>
Beim Vergleich mit den einzelnen und getunten Modellen aus @tab_best_runs_per_sweep kann gesehen werden, dass das Zusammenführen der einzelnen besten Modelle mit unterschiedlichen Architekturen eine weitere Verbesserung der Performance darstellt. Der Macro-F1-Wert verbessert sich dadurch um weitere 0,52 % gegenüber dem besten #acr("XGBoost")-Modell.

Dies ist zwar keine grosse Verbesserung, jedoch ist das primäre Ziel vom Ensemble-Modell die Verbesserung gegenüber neuen, ungesehenen Daten. Da die einzelnen Modelle stark dazu neigen, die Daten zu overfitten, ist ein Ensemble eine Massnahme, um dieses Risiko zu minimieren. Die Architekturen lernen unterschiedliche Muster der Daten und entscheiden schlussendlich gemeinsam, welche Klassen die korrekten Klassen sind. Eine Bestätigung dieser Feststellung kann in der @tab_ensemble_soft_vote eingesehen werden. Der Macro-F1-Wert bleibt ähnlich im Testset gegenüber dem Datensatz für die Validierung und erzielt eine Zunahme von 0,4 %. Diese Zunahme ist jedoch aufgrund der Datenqualität mit Vorsicht zu geniessen. Es kann sein, dass die Projekte für die Validierung Ähnlichkeiten haben, welche auch beim Testset vorkommen. Zudem wurden beim @implementation_dataset_splitting alle ähnlichen Daten zwischen Trainingsset und den anderen Splits entfernt. Zwischen Validierungs- und Testset hingegen wurden keine ähnlichen Daten entfernt. Dies kann ein Grund für die leicht höhere Performance des Testsets sein.

#let ensemble_metrics = json("../../code/5_evaluation/5_3_soft_vote_ensemble_model/ensemble_soft_vote_metrics.json")
#let label_display = (
  "label_ifc_entity": "IFC-Entität",
  "label_predefined_type": "Vordefinierter Typ",
  "label_is_external": "Lage der Bauteile",
  "label_load_bearing": "Tragende Funktion",
)
#let labels_order = ("label_ifc_entity", "label_predefined_type", "label_is_external", "label_load_bearing")

#figure(
  table(
    columns: (1.9fr, 1.1fr, 1fr, 1.2fr, 1.1fr, 1fr, 1.2fr),
    align: (left, center, center, center, center, center, center),
    stroke: (x: none, y: none),

    table.hline(),
    [], table.cell(colspan: 3, align: center)[*Validierung*], table.cell(colspan: 3, align: center)[*Test*],
    table.hline(start: 1, end: 4), table.hline(start: 4, end: 7),
    [*Label*], [*Accuracy*], [*MCC*], [*Macro-F1*], [*Accuracy*], [*MCC*], [*Macro-F1*],
    table.hline(),

    ..labels_order
      .map(lbl => (
        [#label_display.at(lbl)],
        [#fmt(ensemble_metrics.validation.at(lbl).accuracy)],
        [#fmt(ensemble_metrics.validation.at(lbl).mcc)],
        [#fmt(ensemble_metrics.validation.at(lbl).f1_macro)],
        [#fmt(ensemble_metrics.test.at(lbl).accuracy)],
        [#fmt(ensemble_metrics.test.at(lbl).mcc)],
        [#fmt(ensemble_metrics.test.at(lbl).f1_macro)],
      ))
      .flatten(),

    table.hline(),
    [*Mittelwert*],
    [#fmt(ensemble_metrics.validation.mean.accuracy)],
    [#fmt(ensemble_metrics.validation.mean.mcc)],
    [#fmt(ensemble_metrics.validation.mean.f1_macro)],
    [#fmt(ensemble_metrics.test.mean.accuracy)],
    [#fmt(ensemble_metrics.test.mean.mcc)],
    [#fmt(ensemble_metrics.test.mean.f1_macro)],
    table.hline(),
  ),
  caption: [Performance des finalen Soft-Vote-Ensembles je Label auf Validierungs- und Testset],
)<tab_ensemble_soft_vote>

In der @confusion_matrix_ifc_entity_testset ist ersichtlich, dass viele der Klassen bei der "#acr("IFC")-Entität" vom Modell korrekt vorhergesagt werden. Die Schwächen beim Modell liegen aktuell bei der Unterscheidung zwischen horizontalen Elementen wie "IfcCovering", "IfcSlab" und "IfcRoof". Dies liegt an der Tatsache, dass die Geometrien sehr ähnlich sind. Auch aus dem zweiten Interview mit dem Leiter der Abteilung Baumanagement bei #link("https://www.gks.ch")[GKS Architekten AG] Patrick Muff (@second_interview_gks) ging hervor, dass bei diesen Elementen bereits erste Ähnlichkeiten sichtbar sind. Bei den modellierenden Personen liegt auch bei diesen Kategorien die Fehlerquelle bei den ersten Prüfungen der Modelle, da die Unterscheidung nicht immer trivial ist. Ein weiteres Bauteil, welches das Modell nicht erkannt hat, sind die Fenster. Dort war sich das Modell nicht sicher, ob es sich dabei um "IfcSanitaryTerminal", "IfcSlab" oder "IfcWall" handelt. Auch hier sind die Geometrien aller Klassen ähnlich zueinander. Zuletzt sind auch bei den Klassen "IfcColumn", "IfcPlate" und "IfcRailing" falsche Vorhersagen erkannt worden. Die weiteren Fehlermatrizen sind im Anhang unter @confusion_matrix_ensemble_validation für das Validierungsset und @confusion_matrix_ensemble_testset für das Testset zu finden.

#figure(
  image("./img/confusion_matrix_ifc_entity_testset.svg", width: 110%),
  caption: [Fehlermatrix vom Label "#acr("IFC")-Entität" beim finalen Ensemble-Modell auf dem Test-Datensatz.],
)<confusion_matrix_ifc_entity_testset>

== Analyse der Fehlklassifikationen<evaluation_misclassification>

=== Fehlklassifikationen bei Fenstern (IfcWindow)
Wie bereits im vorherigen @results_ensemble_testset erkannt, werden die Fehlklassifikationen der Fenster in diesem Unterkapitel für das #acr("RF")-Modell genauer untersucht. Bei vier ausgewählten Beispielen klassifizierte das Modell anhand der trainierten Entscheidungsbäume die jeweiligen Bauelemente als zweithäufigste Klassifikation korrekterweise als "IfcWindow". Dem gegenüber stehen doppelt so viele Entscheidungsbäume, welche die Klassifikation eines Fensters fälschlicherweise als "IfcDoor" vornehmen. Das #acr("RF") kann demnach Türen nicht exakt von Fenstern unterscheiden. Nur wenige Entscheidungsbäume führen jeweils zu anderen ähnlichen Klassen wie "IfcWall", "IfcRailing" oder "IfcSanitaryTerminal". Deshalb ist das Modell bereits stark in der Unterscheidung anderer Klassen im Vergleich zu Türen und Fenstern.

#let window_examples = json(
  "../../code/5_evaluation/5_4_misclassification_analysis/misclassification_examples_ifc_window.json",
)

#figure(
  table(
    columns: (0.4fr, 1.5fr, 1.5fr, 1.5fr, 2.0fr),
    align: (center, center, center, center, center, center),
    stroke: (x: none, y: none),

    table.hline(),
    [*Nr.*], [*Top 1*], [*Top 2*], [*Top 3*], [*Top 4*],
    table.hline(),

    ..window_examples
      .enumerate()
      .map(pair => {
        let i = pair.at(0)
        let row = pair.at(1)
        ([#(i + 1)], ..row.top_5_votes.map(v => [#v.at(0) (#v.at(1))]))
      })
      .flatten(),

    table.hline(),
  ),
  caption: [Top-4 Vorhersagen der 200 Entscheidungsbäume beim besten #acr("RF")-Modell aus den "IfcWindow"-Fehlklassifikationen],
)<tab_misclassification_examples_ifc_window>

In der Analyse der 73 Features wurde zudem festgestellt, dass das Material "Glas" nicht aus den Materialien entnommen wird. Dies führt dazu, dass die "Helper-Methode" für die Extraktion der Materialien noch nicht vollumfänglich angewendet wird. Die Materialeigenschaft von Fenstern sind aktuell an einem anderen Ort im #acr("IFC")-Schema hinterlegt als diese im Modell gesucht werden. Die vollständige und korrekte Integration der "Helper-Methode" könnte zu einer besseren Unterscheidung zwischen Türen und Fenstern führen. Zudem wird das Modell bei Balkontüren, welche meistens verglast und einem Fenster sehr ähnlich sind, Schwierigkeiten in der Unterscheidung haben. Eine Erweiterung von Features, welche diese Unterscheidung klarer darstellen, könnte eine mögliche Massnahme sein.

=== Fehlklassifikationen bei Aufbauten (IfcCovering)
Ein weiterer Fall konnte sich bei @results_ensemble_testset herauskristallisieren, wo die Aufbauten nicht von den Decken unterschieden werden können. In der @xgb_ifc_covering_misses_contributions werden über alle Klassen die Werte für die korrekt klassifizierten Elemente als grüner Balken und für die falsch klassifizierten Elemente als roter Balken dargestellt. Sie zeigt die Analyse beim #acr("XGBoost")-Modell, wobei die Features nach Wichtigkeit absteigend sortiert sind. Beim Feature "tfbb_ratio_12" wird das Verhältnis der ersten zur zweiten Streuungsachse dargestellt. Dadurch werden flächigere Bauelemente erkannt. Dieses Verhältnis ist für #acr("XGBoost") bei der Klasse "IfcCovering" von grosser Relevanz und es kann bereits bestätigt werden, dass bei den falsch klassifizierten Elementen die Geometrie diesbezüglich anders ist. Die falsch klassifizierten Elemente sind eher kompakter als jene bei den korrekten Vorhersagen. Zudem sind korrekt klassifizierte Elemente nicht sehr hoch, was der grüne Balken bei "aabb_max_z" zeigt.

#figure(
  image("./img/xgb_ifc_covering_misses_contributions.svg", width: 100%),
  caption: [Übersicht der Falschklassifikationen vom Ensemble-Modell über alle Vorhersagen bei der #acr("IFC")-Entität "IfcCovering"],
)<xgb_ifc_covering_misses_contributions>

Bei den falsch klassifizierten Elementen handelt es sich deshalb eher um wandähnliche Typen. Weitere Features wie "mat_beton" und "mat_metall" sind ausschliesslich bei den falsch klassifizierten Elementen auch vorhanden. Es wird angenommen, dass deshalb diverse Elemente im verwendeten Datensatz nicht korrekt sind. Solche Aufbauten, welche meistens Dämmungen (IfcCovering) sind, enthalten nie Materialien wie Metall oder Beton im Bauteil. Die erwähnten Fehlanalysen sind nicht abschliessend und bilden einen Auszug aus der gemachten Analysen dar. Weitere Fehlanalysen können im Notebook "misclassification_analysis.ipynb" eingesehen werden.

== Ergebnisse der Hypothesen

=== Hypothese 1: Geometrische Features sind ausreichend
Die erste Hypothese ist teilweise erfüllt. Wie in der @tab_ensemble_soft_vote ersichtlich ist, beträgt der Mittelwert über alle Labels beim Macro-F1-Wert auf dem Testset 0,7368 und liegt damit über der geforderten Schwelle von 0,70. Zudem erfüllen die drei Labels "#acr("IFC")-Entität", "IsExternal" und "LoadBearing" die Hypothese auch individuell. Die geometrischen Features sind somit für die oben genannten Labels ausreichend, was sich mit den Ergebnissen verwandter Studien deckt, die ebenfalls hohe Genauigkeiten bei den Klassifikationen allein auf Basis geometrischer Features erzielen @ma_3d_2018 @koo_using_2019 @abualdenien_ensemble_learning_2022. Einzig das Label "Vordefinierter Typ" erfüllt die Hypothese mit einem Macro-F1-Wert von 0,5477 nicht. Besonders die Klassen "NOTDEFINED" und "PARTITIONING" zeigen sich als sehr herausfordernd für das finale #acr("EM"). Wie aber im folgenden @validation_with_client zu entnehmen ist, werden vom finalen Modell viele Elemente präziser spezifiziert, als sie sein sollten. Deshalb ist die Performance des Labels "predefined_type" schlechter dargestellt, als sie effektiv ist, da Elemente oft genauer vorgeschlagen werden, als sie in den abgegebenen Daten definiert sind. Zudem sind diverse Klassen unterrepräsentiert und der Datensatz ist mehrheitlich unausgewogen.

=== Hypothese 2: Gradient Boosting vs. Random Forest
Aufgrund der tiefen Performance beim Modell #acr("LightGBM"), welche in der @tab_all_models_comparison ersichtlich ist, wurde dieses Modell nicht für das Hyperparameter-Tuning verwendet und es wurden lediglich das Gradient-Boosting-Modell #acr("XGBoost") und das #acr("RF")-Modell hinsichtlich Performance und Trainingszeit gemessen. Für das Hyperparameter-Tuning wurde der #link("https://gpuhub.labservices.ch")[GPUHub] der #acr("HSLU") benutzt. Beim Gebrauch dieses Dienstes wird pro Login eine NVIDIA A16 Grafikkarte für das Training der Modelle zur Verfügung gestellt. Des Weiteren steht serverseitig eine Intel(R) Xeon(R) Gold 5117 CPU @ 2,00GHz mit insgesamt 792,11 GB Arbeitsspeicher zur Verfügung. Auf Basis dieser Hardware wurden die Runs erstellt und mit #acr("WandB") die Trainingszeit sowie die Metriken gespeichert.

#let training_stats = json(
  "../../code/5_evaluation/5_1_get_best_runs_wandb/training_stats.json",
)

#figure(
  table(
    columns: (1.5fr, 1fr, 1fr, 1.1fr, 1fr, 1fr, 1.1fr),
    align: (left, center, center, center, center, center, center),
    stroke: (x: none, y: none),

    table.hline(),
    [],
    table.cell(colspan: 3, align: center)[*mit Oversampling*],
    table.cell(colspan: 3, align: center)[*ohne Oversampling*],
    table.hline(start: 1, end: 4), table.hline(start: 4, end: 7),
    [*Modell*], [*Anzahl*], [*Mean*], [*Median*], [*Anzahl*], [*Mean*], [*Median*],
    table.hline(),

    [Random Forest],
    [#str(training_stats.random_forest.oversampling.count)],
    [#fmt(training_stats.random_forest.oversampling.mean_seconds) s],
    [#fmt(training_stats.random_forest.oversampling.median_seconds) s],

    [#str(training_stats.random_forest.no_oversampling.count)],
    [#fmt(training_stats.random_forest.no_oversampling.mean_seconds) s],
    [#fmt(training_stats.random_forest.no_oversampling.median_seconds) s],

    [XGBoost],
    [#str(training_stats.xgboost.oversampling.count)],
    [#fmt(training_stats.xgboost.oversampling.mean_seconds) s],
    [#fmt(training_stats.xgboost.oversampling.median_seconds) s],
    [#str(training_stats.xgboost.no_oversampling.count)],
    [#fmt(training_stats.xgboost.no_oversampling.mean_seconds) s],
    [#fmt(training_stats.xgboost.no_oversampling.median_seconds) s],

    table.hline(),
  ),
  caption: [Trainingszeit zwischen den Modellen #acr("RF") und #acr("XGBoost") mit und ohne Oversampling in Sekunden und der Anzahl der Experimente],
)<tab_rf_vs_xgboost_training_duration>

Erkennbar zwischen beiden Modellen ist, dass #acr("XGBoost") eine bessere Performance als #acr("RF") erzielte (@tab_best_runs_per_sweep). Somit erreicht das #acr("XGBoost")-Modell vergleichbare Werte wie das #acr("RF")-Modell und bestätigt die Performance-Aussage der Hypothese, was sich mit den Ergebnissen früherer Vergleichsstudien deckt @li_ensemble-learning-based_2022 @sagi_ensemble_2018. Bei der Trainingszeit wird die Hypothese hingegen widerlegt. In diesem Anwendungsfall benötigt #acr("XGBoost") im Durchschnitt 23,04 Sekunden mehr Trainingszeit als #acr("RF"). Mögliche Ursachen sind, dass #acr("XGBoost") die Entscheidungsbäume sequenziell als Boosting-Verfahren über viele Iterationen aufbaut, während #acr("RF") diese parallel trainiert. Dies führt insgesamt zu einer längeren Trainingszeit beim #acr("XGBoost")-Modell. Dieses Ergebnis sorgt für Überraschung, da #acr("XGBoost") in der Literatur häufig als effizient beschrieben wird @li_ensemble-learning-based_2022.

== Ergebnisse der Filterung auf Basis der Modell-Konfidenz
Damit ein praxisnahes Modell entstehen kann, wird für das finale #acr("EM") ein Confidence-Schwellwert analysiert. Wie bereits im @methods_ensemble methodisch beschrieben, wurden die idealen Schwellwerte beim @implementation_ensemble eruiert. Bei diesem Ansatz kann bereits in der @tab_threshold_test_verification gesehen werden, dass die Performance der Modelle viel besser wird, wenn nur noch Elemente ab einer gewissen Sicherheit des Modells vorhergesagt werden. Bei komplexeren Klassen wie "vordefinierter Typ" sind die Schwellwerte tiefer, damit trotzdem mindestens 70,0 % der Bauteile vorhergesagt werden. Dadurch bleibt jedoch die Performance tief und erhöht sich nicht sehr. Dagegen profitieren die anderen Labels ungemein von diesem Schwellwert und erhöhen deren Performance. Die Performance der Lage der Bauteile erhöht sich dadurch beispielsweise um 7,81 %. Bei der "#acr("IFC")-Entität" verschlechtert sich dabei der Macro-F1-Wert um 0,78 %, jedoch erhöht sich der #acr("MCC")-Wert um 9,52 %. Der #acr("MCC") ist nur gewichtet, deshalb kann sich dieser Wert stärker verändern als ein Macro-F1-Wert.

#let threshold_results = json(
  "../../code/5_evaluation/5_5_threshold_inference_analysis/threshold_analysis_results.json",
)
#let threshold_label_display = (
  "label_ifc_entity": "IFC-Entität",
  "label_predefined_type": "Vordefinierter Typ",
  "label_is_external": "Lage der Bauteile",
  "label_load_bearing": "Tragende Funktion",
)

#figure(
  table(
    columns: (1.8fr, 1.2fr, 1.0fr, 1.0fr, 1.0fr, 0.5fr, 1.2fr),
    align: (left, center, center, center, center, center, center),
    stroke: (x: none, y: none),

    table.hline(),
    [*Label*], [*Confidence*], [*Coverage*], [*Accuracy*], [*Precision*], [*MCC*], [*F1-Macro*],
    table.hline(),

    ..threshold_results
      .test_verification
      .map(row => (
        [#threshold_label_display.at(row.label)],
        [#fmt(row.tau)],
        [#fmt(row.coverage)],
        [#fmt(row.accuracy)],
        [#fmt(row.precision)],
        [#fmt(row.mcc)],
        [#fmt(row.f1_macro)],
      ))
      .flatten(),

    table.hline(),
  ),
  caption: [Performance des Soft-Vote-Ensembles auf dem Testset nach Anwendung der label-spezifischen Konfidenz-Schwellwerte],
)<tab_threshold_test_verification>

== Praxisvalidierung der Demo-Pipeline<validation_with_client>
Zur Validierung, ob die entwickelte Demo-Pipeline praxistauglich für die #link("https://www.gks.ch")[GKS Architekten AG] ist, wird ein zweites Interview mit dem Praxispartner gemacht. In diesem Interview wurde die Demo-Pipeline vorgestellt und die erkannten Abweichungen zwischen der Ground-Truth der abgegebenen Daten und den vorhergesagten Labels mit Patrick Muff gemeinsam begutachtet. Damit kein Datenleck entsteht, wurde nur das Projekt "LUMU" präsentiert, welches bei beiden Datensatzaufteilungen ausschliesslich im Testset vorkam. Die qualitativen Rückmeldungen ergänzen die quantitative Auswertung dieses Kapitels um die Perspektive des Praxispartners, indem die Praxistauglichkeit verifiziert wird.

Das Interview kann im Anhang unter dem @second_interview_gks eingesehen werden. Erkannte Probleme vom Modell liegen beispielsweise bei einer Fehleinschätzung zwischen den Klassen "IfcSlab", "IfcCovering" und "IfcRoof", welche laut der Aussage von Patrick Muff auch bei modellierenden Fachpersonen ein Problem bei der ersten Modellabgabe darstellt. Häufig fehlt dort das notwendige Wissen, um diese Unterscheidung für kostenrelevante Unterscheidungen treffen zu können. Eine weitere Fehlerquelle liegt in der Unterscheidung zwischen sanitären Objekten und Waschbecken. Diese Unterscheidung ist jedoch für die Kostenschätzung nicht von Relevanz, da die Anzahl dieser Elemente über andere Dokumente bezogen wird und sie häufig in der frühen Phase nicht mit modelliert werden. Bei diversen Elementen neigt das Modell dazu, diese mit dem "vordefinierten Typ" weiter zu spezifizieren, obwohl dies nicht notwendig ist und die Klasse "NOTDEFINED" genügend wäre. Da es sich bei diesen Modellen um eine zusätzliche Spezifizierung handelt, welche aber korrekt wäre, kann diese Fehlklassifikation ignoriert werden. Dies traf oft bei Stützen und Wänden ein. Zuletzt wurde mittels der gemeinsamen Analyse bei vielen Anomalien erkannt, dass die abgegebenen Daten Fehler enthielten. Diese Fehler wurden meistens für die Kostenschätzung entfernt, jedoch nicht dem Team mitgeteilt. Deshalb ist davon auszugehen, dass die abgegebenen Daten allgemein einen Fehleranteil enthalten. Dabei bilden diese Daten die Ground-Truth.

Es zeigt sich insgesamt, dass die Performance von der Demo-Pipeline beim Praxispartner überzeugt und in der Praxis eingesetzt werden kann. Besonders überzeugt die Rückmeldung mittels des #acr("BCF")-Berichts, wo alle Anomalien gruppiert rückgemeldet werden, damit eine effiziente Fehleranalyse durchgeführt werden kann. Der Excel-Bericht ist gut als Ergänzung und genügend kompakt. Primär ist aber das #acr("BCF") entscheidend für alle Beteiligten, da so die Anomalien direkt in das native #acr("CAD") oder in das Solibri importiert werden können. Das Modell soll in den bestehenden monatlichen "Pre-Check" integriert werden, welcher bereits bei der #link("https://www.gks.ch")[GKS Architekten AG] im Einsatz ist. Da das Modell deterministisch immer die gleichen Fehler vorschlägt, sollen Elemente, welche durch Fachpersonen bereits geprüft worden sind, in zukünftigen Prüfungen nicht mehr erneut angezeigt werden. Lediglich bei einer Veränderung sollen diese neu beurteilt werden. Zudem genügt die Performance vom finalen Modell für eine alleinige Prüfung nicht, jedoch ist sie bereits genügend gut, um als weitere Qualitätssicherung zu fungieren. Beispielbilder der erkannten Anomalien können im @missclassifications_demo eingesehen werden.
