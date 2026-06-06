# !/usr/bin/env python3
import os
import re
import numpy as np
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from collections import defaultdict
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

from _settings import SEED

# static variables for the helpers

_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

_CHAPTER_PATHS = {
    "methods": os.path.join(_ROOT, "chapters", "3 methods", "img"),
    "implementation": os.path.join(_ROOT, "chapters", "4 implementation", "img"),
    "evaluation": os.path.join(_ROOT, "chapters", "5 evaluation", "img"),
    "outlook": os.path.join(_ROOT, "chapters", "6 outlook", "img"),
    "appendix": os.path.join(_ROOT, "chapters", "7 appendix", "img"),
}

_LEVEL_PATTERNS = {
    "letter":    re.compile(r'^[A-Z]$'),
    "two_digit": re.compile(r'^[A-Z]\d{2}$'),
    "four_digit": re.compile(r'^[A-Z]\d{2}\.\d{2}$'),
}

_LEVEL_LABELS = {
    "letter": "Einstellig",
    "two_digit": "Zweistellig",
    "four_digit": "Dreistellig",
}

_LEVEL_TITLES = {
    "letter": "e-BKP-H Verteilung — Einstellig",
    "two_digit": "e-BKP-H Verteilung — Zweistellig",
    "four_digit": "e-BKP-H Verteilung — Dreistellig",
}

_LEVEL_COLORS = {
    "letter": "#636EFA",
    "two_digit": "#EF553B",
    "four_digit": "#00CC96",
}

_MULTILABEL_LEVELS = [
    ("n_letter", "letter"),
    ("n_two_digit", "two_digit"),
    ("n_four_digit", "four_digit"),
]

_IDC_COLS_DEFAULT = [
    "label_is_external", "label_load_bearing", "label_unter_terrain", "label_deckbelag", "label_bekleidung",
    "label_aussenliegendes_bauteil", "label_erdverbunden", "label_unterkonstruktion",
    "label_verdunkelung", "label_schutzschicht", "label_sonnenschutz", "label_einbau", "label_aufzugstyp",
]

# shared helper functions

def _validate_level(level):
    if level not in _LEVEL_PATTERNS:
        raise ValueError(f"level must be one of: {list(_LEVEL_PATTERNS.keys())}")


def _save_fig(fig, name, chapter):
    """Save figure as <name>.svg into the chapter's img folder. Strips the title and tightens the top margin so the SVG embeds cleanly into the Typst report. The interactive figure is restored afterwards."""
    if chapter not in _CHAPTER_PATHS:
        raise ValueError(f"chapter must be one of: {list(_CHAPTER_PATHS.keys())}")
    
    out_dir = _CHAPTER_PATHS[chapter]
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, f"{name}.svg")

    saved_title = fig.layout.title.text
    saved_margin_t = fig.layout.margin.t

    # strip the title and tighten the top margin only if the plot did not set one explicitly
    fig.update_layout(title_text=None, margin_t=saved_margin_t if saved_margin_t is not None else 20)
    fig.write_image(path)
    fig.update_layout(title_text=saved_title, margin_t=saved_margin_t)

    print(f"figure saved: {path}")


def _finalize(fig, save, chapter, name_suffix=""):
    """Save and show the figure. Replaces the save/show boilerplate at the end of every plot_* function."""
    if save:
        _save_fig(fig, save + name_suffix, chapter)
    fig.show()


def _ebkph_level_title(level, n_cats):
    return f"{_LEVEL_TITLES[level]} ({n_cats} Kategorien)"

# internal helper functions for eBKPh analysis

def _get_level_cols(df, level):
    pat = _LEVEL_PATTERNS[level]
    return [
        c for c in df.columns
        if c.startswith("eBKPh_")
        and c not in ("eBKPh_original", "eBKPh_status")
        and df[c].dtype == bool
        and pat.match(c.replace("eBKPh_", "").replace("_", "."))
    ]


def _col_to_code(c):
    return c.replace("eBKPh_", "").replace("_", ".")


def _get_ebkph_counts(df, level):
    cols = _get_level_cols(df, level)
    counts = pd.DataFrame({
        "Code": [_col_to_code(c) for c in cols],
        "Anzahl": [df[c].sum() for c in cols],
    })
    return counts


def _add_label_counts(df):
    df = df.copy()
    for col, level in _MULTILABEL_LEVELS:
        df[col] = df[_get_level_cols(df, level)].sum(axis=1)
    return df

def _get_top_combinations(df, cols, top_n):
    codes = [_col_to_code(c) for c in cols]
    cooc = df[cols].values.astype(int).T @ df[cols].values.astype(int)
    combos = [
        (codes[i], codes[j], int(cooc[i, j]))
        for i in range(len(codes))
        for j in range(i + 1, len(codes))
        if cooc[i, j] > 0
    ]
    combos.sort(key=lambda x: -x[2])
    return combos[:top_n]


# existing distribution plots

def plot_ebkph_treemap(df, level, width = 1400, height = 800, save = None, chapter = None):
    """Shows the eBKPh-Codes on the three different levels as a treemap."""
    _validate_level(level)

    counts = _get_ebkph_counts(df, level)
    counts["Label"] = counts["Code"] + "<br><i>" + counts["Anzahl"].astype(str) + "</i>"

    fig = go.Figure(
        go.Treemap(
            ids=counts["Code"],
            labels=counts["Label"],
            parents=[""] * len(counts),
            values=counts["Anzahl"],
            hovertemplate="%{id}<br>Anzahl: %{value}<extra></extra>",
        )
    )
    fig.update_traces(textfont=dict(size=16))
    fig.update_layout(title=_ebkph_level_title(level, len(counts)), width=width, height=height)
    _finalize(fig, save, chapter)


def plot_ebkph_bar(df, level, width = 1400, height = 800, save = None, chapter = None):
    """Shows the eBKPh-Codes on the three different levels as a bar chart."""
    _validate_level(level)

    counts = _get_ebkph_counts(df, level)
    fig = go.Figure(
        go.Bar(
            x=counts["Code"],
            y=counts["Anzahl"],
            hovertemplate="%{x}<br>Anzahl: %{y}<extra></extra>",
        )
    )
    fig.update_layout(
        title=_ebkph_level_title(level, len(counts)),
        xaxis_title="Code",
        yaxis_title="Anzahl",
        width=width,
        height=height,
    )
    _finalize(fig, save, chapter)


def plot_ebkph_sankey(df, title = "Relationen zwischen Projektcode, IFC Entität und eBKP-H Hierarchien", min_count = 100, width = 1600, height = 900, save = None, chapter = None):
    """Sankey plot: project_code -> ifc_entity -> eBKPh letter -> two_digit -> four_digit"""
    letter_cols     = _get_level_cols(df, "letter")
    two_digit_cols  = _get_level_cols(df, "two_digit")
    four_digit_cols = _get_level_cols(df, "four_digit")

    sources, targets, values = [], [], []
    all_nodes, seen = [], set()

    def add_node(n):
        if n not in seen:
            all_nodes.append(n)
            seen.add(n)

    def add_flow(s, t, v):
        sources.append(s)
        targets.append(t)
        values.append(v)
        add_node(s)
        add_node(t)

    # flow 1: project_code -> ifc_entity
    f1 = df.groupby(["project_code", "label_ifc_entity"]).size().reset_index(name="count")
    f1 = f1[f1["count"] >= min_count]
    for _, row in f1.iterrows():
        add_flow(f"PC:{row['project_code']}", f"IFC:{row['label_ifc_entity']}", int(row["count"]))
    valid_entities = {f"IFC:{e}" for e in f1["label_ifc_entity"].unique()}

    # flow 2: ifc_entity -> eBKPh letter
    for lc in letter_cols:
        lcode = _col_to_code(lc)
        sub = df[df[lc]].groupby("label_ifc_entity").size().reset_index(name="count")
        sub = sub[sub["count"] >= min_count]
        for _, row in sub.iterrows():
            entity_node = f"IFC:{row['label_ifc_entity']}"
            if entity_node in valid_entities:
                add_flow(entity_node, f"L:{lcode}", int(row["count"]))

    # flow 3: letter -> two_digit (only if letter node exists from flow 2)
    for tc in two_digit_cols:
        tcode = _col_to_code(tc)
        count = int(df[tc].sum())
        letter_node = f"L:{tcode[0]}"
        if count >= min_count and letter_node in seen:
            add_flow(letter_node, f"2D:{tcode}", count)

    # flow 4: two_digit -> four_digit (only if two_digit node exists from flow 3)
    for fc in four_digit_cols:
        fcode = _col_to_code(fc)
        count = int(df[fc].sum())
        two_digit_node = f"2D:{fcode[:3]}"
        if count >= min_count and two_digit_node in seen:
            add_flow(two_digit_node, f"4D:{fcode}", count)

    node_idx = {n: i for i, n in enumerate(all_nodes)}
    labels = [n.split(":", 1)[1] for n in all_nodes]

    color_map = {
        "PC": "rgba(99,110,250,0.8)",
        "IFC": "rgba(239,85,59,0.8)",
        "L": "rgba(0,204,150,0.8)",
        "2D": "rgba(171,99,250,0.8)",
        "4D": "rgba(255,161,90,0.8)",
    }
    tier_x = {"PC": 0.01, "IFC": 0.25, "L": 0.5, "2D": 0.75, "4D": 0.99}
    node_colors = [color_map[n.split(":")[0]] for n in all_nodes]
    node_x = [tier_x[n.split(":")[0]] for n in all_nodes]
    node_y = []

    tier_counts: dict = defaultdict(int)
    tier_index: dict = defaultdict(int)

    for n in all_nodes:
        tier_counts[n.split(":")[0]] += 1

    for n in all_nodes:
        tier = n.split(":")[0]
        idx = tier_index[tier]
        count = tier_counts[tier]
        node_y.append(max(0.01, min(0.99, (idx + 1) / (count + 1))))
        tier_index[tier] += 1

    fig = go.Figure(go.Sankey(
        arrangement="fixed",
        node=dict(
            pad=12,
            thickness=18,
            line=dict(color="black", width=0.4),
            label=labels,
            color=node_colors,
            x=node_x,
            y=node_y,
        ),
        link=dict(
            source=[node_idx[s] for s in sources],
            target=[node_idx[t] for t in targets],
            value=values,
        ),
    ))
    fig.update_layout(
        title=dict(text=title, font_size=16),
        font_size=11,
        width=width,
        height=height,
    )
    _finalize(fig, save, chapter)


def plot_label_property_status(df, cols=None, col_prefix="label_", width=1400, height=600, title="Übersicht der Eigenschaften für eBKP-H Mapping", save = None, chapter = None):
    """Grouped bar chart showing how many elements have a real value vs. NaN for each specified column."""
    if cols is None:
        cols = [c for c in df.columns if c.startswith(col_prefix)]
    has_value = [int(df[c].notna().sum()) for c in cols]
    is_nan    = [int(df[c].isna().sum())  for c in cols]
    label_cols = cols

    fig = go.Figure([
        go.Bar(name="Werte vorhanden", x=label_cols, y=has_value, marker_color="#636EFA"),
        go.Bar(name="NaN",      x=label_cols, y=is_nan,    marker_color="#bdc3c7"),
    ])
    fig.update_layout(
        barmode="group",
        title=title,
        xaxis_title="Eigenschaft",
        yaxis_title="Anzahl Elemente",
        xaxis_tickangle=-45,
        width=width,
        height=height,
    )
    _finalize(fig, save, chapter)


def plot_ebkph_status_by_project(df, sia_phase_mapping=None, title="Elemente pro Projekt nach eBKPh-Status", width=1400, height=600, save=None, chapter=None):
    """Grouped bar chart showing classified / not classified / NaN elements per project. If sia_phase_mapping is provided as dict {project_code: sia_phase}, it will be added as subtitle to the x-axis labels."""
    def _classify(val):
        if pd.isna(val):
            return "NaN"
        if val == "Nicht klassifiziert":
            return "Nicht klassifiziert"
        return "Klassifiziert"

    summary = df.assign(_status=df["eBKPh"].apply(_classify)) \
                .groupby(["project_code", "_status"]).size() \
                .unstack(fill_value=0)

    project_codes = summary.index.tolist()
    if sia_phase_mapping:
        tick_labels = [
            f"{code}<br>({sia_phase_mapping[code]})" if code in sia_phase_mapping else code
            for code in project_codes
        ]
    else:
        tick_labels = project_codes

    colors = {"Klassifiziert": "#2ecc71", "Nicht klassifiziert": "#e67e22", "NaN": "#e74c3c"}
    fig = go.Figure()
    for status in ["Klassifiziert", "Nicht klassifiziert", "NaN"]:
        if status in summary.columns:
            fig.add_trace(go.Bar(
                name=status,
                x=project_codes,
                y=summary[status],
                marker_color=colors[status],
            ))
    fig.update_layout(
        barmode="group",
        title=title,
        xaxis_title="Projektkürzel",
        yaxis_title="Anzahl Elemente",
        xaxis=dict(
            tickmode="array",
            tickvals=project_codes,
            ticktext=tick_labels,
        ),
        width=width,
        height=height,
    )
    _finalize(fig, save, chapter)


# multi-label analysis

def plot_multilabel_summary(df):
    """Print multi-label element counts and rates for all three hierarchy levels."""
    df_ml = _add_label_counts(df)
    print(f"Klassifizierte Elemente total: {len(df_ml):,}\n")

    for col, level in _MULTILABEL_LEVELS:
        multi = (df_ml[col] > 1).sum()
        print(f"{_LEVEL_LABELS[level]:<12}: {multi:6,} / {len(df_ml):,} Elemente ({multi / len(df_ml):.1%}) haben mehrere Labels")


def plot_multilabel_overview(df, width = 1400, height = 480, save = None, chapter = None):
    """3 donut pie charts: single vs. multi-label share per hierarchy level."""
    df_ml = _add_label_counts(df)
    COLORS = {1: "#2ecc71", 2: "#e67e22", 3: "#e74c3c", "4+": "#9b59b6"}
    titles = ["Einstellig (Buchstabe)", "Zweistellig (z.B. C02)", "Dreistellig (z.B. C02.01)"]
    fig = make_subplots(
        rows=1, cols=3,
        specs=[[{"type": "domain"}] * 3],
        subplot_titles=titles,
    )

    for i, (col, _) in enumerate(_MULTILABEL_LEVELS, 1):
        vc = df_ml[col].value_counts().sort_index()
        counts = {k: int(v) for k, v in vc.items() if k <= 3}
        count_4plus = int(vc[vc.index >= 4].sum())
        if count_4plus > 0:
            counts["4+"] = count_4plus
        labels = [f"{k} Label{'s' if k != 1 else ''}" for k in counts]
        fig.add_trace(
            go.Pie(
                labels=labels,
                values=list(counts.values()),
                marker_colors=[COLORS.get(k, "#bdc3c7") for k in counts],
                hole=0.4,
                textinfo="label+percent",
            ),
            row=1, col=i,
        )
    fig.update_layout(
        title="Anteil Elemente mit mehreren eBKP-H Labels je Hierarchiestufe",
        showlegend=False,
        width=width, height=height,
    )
    _finalize(fig, save, chapter)


def plot_multilabel_distribution(df, title="Verteilung der Anzahl Labels pro Element je Hierarchiestufe", width = 1200, height = 550, save = None, chapter = None):
    """Grouped bar: number-of-labels distribution per element and hierarchy level."""
    df_ml = _add_label_counts(df)
    max_x = int(max(df_ml[col].max() for col, _ in _MULTILABEL_LEVELS))
    x_vals = list(range(0, max_x + 1))
    fig = go.Figure()

    for col, level in _MULTILABEL_LEVELS:
        vc = df_ml[col].value_counts()
        fig.add_trace(go.Bar(
            name=_LEVEL_LABELS[level],
            x=[str(x) for x in x_vals],
            y=[int(vc.get(x, 0)) for x in x_vals],
            marker_color=_LEVEL_COLORS[level],
        ))
    fig.update_layout(
        barmode="group",
        title=title,
        xaxis_title="Anzahl Labels",
        yaxis_title="Anzahl Elemente",
        width=width, height=height,
    )
    _finalize(fig, save, chapter)


def plot_multilabel_rate_by_entity(df, min_count = 10, width = 1400, height = 600, save = None, chapter = None):
    """Grouped bar: % of elements with >1 label per IFC entity, sorted by two-digit rate."""
    df_ml = _add_label_counts(df)
    entity_stats = []

    for entity, group in df_ml.groupby("label_ifc_entity"):
        if len(group) < min_count:
            continue
        row = {"label_ifc_entity": entity}
        for col, level in _MULTILABEL_LEVELS:
            row[f"rate_{level}"] = (group[col] > 1).sum() / len(group)
        entity_stats.append(row)

    entity_df = pd.DataFrame(entity_stats).sort_values("rate_two_digit", ascending=False)

    fig = go.Figure()
    for _, level in _MULTILABEL_LEVELS:
        fig.add_trace(go.Bar(
            name=_LEVEL_LABELS[level],
            x=entity_df["label_ifc_entity"],
            y=(entity_df[f"rate_{level}"] * 100).round(1),
            marker_color=_LEVEL_COLORS[level],
        ))
    fig.update_layout(
        barmode="group",
        title="Multi-Label Rate je IFC-Entität (% der Elemente mit > 1 Label)",
        xaxis_title="IFC Entität",
        yaxis_title="Anteil Multi-Label Elemente [%]",
        xaxis_tickangle=-30,
        width=width, height=height,
    )
    _finalize(fig, save, chapter)


def plot_multilabel_cooccurrence(df, title="Co-Occurrence Heatmap" ,level = "letter", normalized = False, width = 900, height = 750, save = None, chapter = None):
    """Co-occurrence heatmap for a given hierarchy level for three levels. Rows are normalized so values show relative co-occurrence (diagonal is zeroed to focus on cross-label overlap)"""
    _validate_level(level)

    cols  = _get_level_cols(df, level)
    codes = [_col_to_code(c) for c in cols]
    mat   = df[cols].values.astype(int)
    cooc  = mat.T @ mat
    label = _LEVEL_LABELS[level]

    if normalized:
        diag = np.diag(cooc).astype(float)
        with np.errstate(invalid="ignore"):
            z = np.where(diag[:, None] > 0, cooc / diag[:, None], 0.0)
        np.fill_diagonal(z, 0)
        colorscale, zmin, zmax = "Reds", 0, 1
        hover = "Basis: %{y}<br>Co-Code: %{x}<br>Anteil: %{z:.1%}<extra></extra>"
        title = (
            f"Co-Occurrence Heatmap — {label} (normalisiert)<br>"
            "<sup>Wert = Anteil der Elemente mit Zeilen-Code, die auch Spalten-Code haben</sup>"
        )
        text_template = "%{z:.0%}"
    else:
        z = cooc.astype(float)
        colorscale, zmin, zmax = "Blues", None, None
        hover = "Codes: %{y} + %{x}<br>Anzahl: %{z:,}<extra></extra>"
        text_template = "%{z:,.0f}"

    fig = go.Figure(go.Heatmap(
        z=z, x=codes, y=codes,
        colorscale=colorscale,
        zmin=zmin, zmax=zmax,
        text=z,
        texttemplate=text_template,
        hovertemplate=hover,
    ))
    fig.update_layout(
        title=title,
        xaxis_tickangle=-45,
        width=width, height=height,
    )
    _finalize(fig, save, chapter)


def plot_multilabel_top_combinations(df, level = "two_digit", top_n = 20, width = 1400, height = 580, save = None, chapter = None):
    """Bar chart of the top pairwise label co-occurrences for one hierarchy level."""
    _validate_level(level)

    cols   = _get_level_cols(df, level)
    combos = _get_top_combinations(df, cols, top_n=top_n)

    fig = go.Figure(go.Bar(
        x=[f"{a} + {b}" for a, b, _ in combos],
        y=[v for _, _, v in combos],
        marker_color=_LEVEL_COLORS.get(level, "#636EFA"),
        hovertemplate="%{x}<br>Anzahl: %{y:,}<extra></extra>",
    ))
    fig.update_layout(
        title=f"Häufigste paarweise Label-Kombinationen — {_LEVEL_LABELS[level]}",
        xaxis_title="Kombination",
        yaxis_title="Anzahl Elemente",
        xaxis_tickangle=-45,
        width=width, height=height,
    )
    _finalize(fig, save, chapter)

# IDC property distribution plots

def plot_idc_property_distributions(df, cols = None, ncols = 2, bar_height = 300, width = 1400, save = None, chapter = None):
    """One bar chart per IDC property (excluding Konstruktionsergänzung) showing value distribution including NaN/None as an explicit category."""
    if cols is None:
        cols = [c for c in _IDC_COLS_DEFAULT if c in df.columns]

    nrows = -(-len(cols) // ncols)  # ceiling division
    fig = make_subplots(
        rows=nrows, cols=ncols,
        subplot_titles=cols,
        vertical_spacing=0.03,
        horizontal_spacing=0.1,
    )

    for i, col in enumerate(cols):
        row, col_idx = divmod(i, ncols)
        counts = df[col].fillna("None / NaN").value_counts().sort_index()
        bar = go.Bar(
            x=counts.index.tolist(),
            y=counts.values.tolist(),
            text=counts.values.tolist(),
            textposition="outside",
            marker_color=[
                "rgba(200,200,200,0.7)" if v == "None / NaN" else "rgba(99,110,250,0.8)"
                for v in counts.index
            ],
            showlegend=False,
        )
        fig.add_trace(bar, row=row + 1, col=col_idx + 1)
        # extend y-axis range so outside-text labels are not clipped
        y_max = int(counts.max()) if len(counts) else 1
        fig.update_yaxes(range=[0, y_max * 1.2], row=row + 1, col=col_idx + 1)

    fig.update_layout(
        title=dict(text="IDC-Eigenschaften – Werteverteilung", font_size=16),
        height=bar_height * nrows,
        width=width,
    )
    fig.update_yaxes(title_text="Anzahl")
    _finalize(fig, save, chapter)


def plot_idc_property_by_entity(df, cols=None, entity_col="label_ifc_entity", bar_height=300, width=1400, save = None, chapter = None):
    """One stacked bar chart per IDC property showing value distribution per entity. Each subplot spans the full width (single column layout)."""
    if cols is None:
        cols = [c for c in _IDC_COLS_DEFAULT if c in df.columns]
    elif isinstance(cols, str):
        cols = [cols]

    color_palette = [
        "rgba(99,110,250,0.85)",
        "rgba(0,204,150,0.85)",
        "rgba(239,85,59,0.85)",
        "rgba(255,161,90,0.85)",
        "rgba(171,99,250,0.85)",
    ]

    fig = make_subplots(
        rows=len(cols), cols=1,
        subplot_titles=cols,
        vertical_spacing=0.04,
    )

    added_to_legend = set()

    for i, col in enumerate(cols):
        tmp = df[[entity_col, col]].copy()
        tmp[col] = tmp[col].fillna("None / NaN")
        grouped = tmp.groupby([entity_col, col], observed=True).size().unstack(fill_value=0)

        all_vals = [v for v in grouped.columns if v != "None / NaN"] + ["None / NaN"]
        value_colors = {v: color_palette[j % len(color_palette)] for j, v in enumerate(v for v in all_vals if v != "None / NaN")}
        value_colors["None / NaN"] = "rgba(200,200,200,0.7)"

        entities = grouped.index.tolist()
        for val in all_vals:
            if val not in grouped.columns:
                continue
            show = val not in added_to_legend
            if show:
                added_to_legend.add(val)
            fig.add_trace(go.Bar(
                name=str(val),
                x=entities,
                y=grouped[val].tolist(),
                marker_color=value_colors[val],
                legendgroup=str(val),
                showlegend=show,
            ), row=i + 1, col=1)

    fig.update_layout(
        title=dict(text="IDC-Eigenschaften - Werteverteilung nach IFC-Entity", font_size=16),
        barmode="stack",
        height=bar_height * len(cols),
        width=width,
        legend=dict(title="Wert"),
    )
    fig.update_yaxes(title_text="Anzahl")
    _finalize(fig, save, chapter)


def plot_label_distribution(df, col, plot_title = None, min_count = 100, width = 1400, height = 600, save = None, chapter = None):
    """Bar chart showing element counts for any label column (filtered by min_count)."""
    counts = df[col].value_counts()
    nan_count = df[col].isna().sum()
    counts = counts[counts >= min_count]

    x = list(counts.index.astype(str)) + (["NaN"] if nan_count > 0 else [])
    y = list(counts.values) + ([nan_count] if nan_count > 0 else [])
    colors = ["#636EFA"] * len(counts) + (["#bdc3c7"] if nan_count > 0 else [])

    fig = go.Figure(go.Bar(
        x=x,
        y=y,
        marker_color=colors,
        hovertemplate="%{x}<br>Anzahl: %{y:,}<extra></extra>",
    ))
    fig.update_layout(
        title=f"Verteilung: {col}" if plot_title is None else plot_title,
        xaxis_title=col,
        yaxis_title="Anzahl",
        width=width,
        height=height,
    )
    _finalize(fig, save, chapter)


def plot_aussenliegende_unter_terrain(df, col_aussen="label_aussenliegendes_bauteil", col_terrain="label_unter_terrain", min_count=0, width=1400, height=500, save=None, chapter=None):
    """Two horizontal aligned bar charts: Aussenliegende Bauteile (left) and Unter Terrain (right)."""
    fig = make_subplots(
        rows=1, cols=2,
        subplot_titles=("Aussenliegende Bauteile", "Unter Terrain"),
        horizontal_spacing=0.12,
    )

    for col_idx, col in enumerate([col_aussen, col_terrain], start=1):
        if col not in df.columns:
            continue
        counts = df[col].value_counts()
        nan_count = int(df[col].isna().sum())
        if min_count > 0:
            counts = counts[counts >= min_count]
        x = list(counts.index.astype(str)) + (["NaN"] if nan_count > 0 else [])
        y = list(counts.values) + ([nan_count] if nan_count > 0 else [])
        colors = ["rgba(99,110,250,0.85)"] * len(counts) + (["rgba(200,200,200,0.7)"] if nan_count > 0 else [])
        fig.add_trace(
            go.Bar(
                x=x,
                y=y,
                marker_color=colors,
                text=y,
                textposition="outside",
                hovertemplate="%{x}<br>Anzahl: %{y:,}<extra></extra>",
                showlegend=False,
            ),
            row=1, col=col_idx,
        )
        y_max = max(y) if y else 1
        fig.update_yaxes(range=[0, y_max * 1.2], row=1, col=col_idx)
        fig.update_xaxes(tickangle=-30, row=1, col=col_idx)

    fig.update_yaxes(title_text="Anzahl Elemente", col=1)
    fig.update_layout(width=width, height=height)
    _finalize(fig, save, chapter)


def plot_konstruktionsergaenzung(df, title = "Konstruktionsergänzung - Werteverteilung", width = 1400, height = 700, save = None, chapter = None):
    """Bar chart for Konstruktionsergänzung showing all occurring values including NaN/None."""
    col = "label_konstruktionsergaenzung"
    counts = df[col].fillna("None / NaN").value_counts().sort_values(ascending=False)

    colors = [
        "rgba(200,200,200,0.7)" if v == "None / NaN" else "rgba(0,204,150,0.8)"
        for v in counts.index
    ]

    fig = go.Figure(go.Bar(
        x=counts.index.tolist(),
        y=counts.values.tolist(),
        text=counts.values.tolist(),
        textposition="outside",
        marker_color=colors,
    ))
    fig.update_layout(
        title=dict(text=title, font_size=16),
        xaxis_title="Wert",
        yaxis_title="Anzahl Elemente",
        xaxis_tickangle=-30,
        width=width,
        height=height,
    )
    _finalize(fig, save, chapter)


def plot_confusion_matrices(cms, label=None, ncols=2, cell_size=55, normalize=False, width=1400, height= 800, save=None, chapter=None):
    """Return a subplot grid of confusion matrices for one or more labels. If label is specified, only that label's matrix is shown. If normalize=True, values are normalized by row and shown as percentages."""
    if label is not None:
        if isinstance(label, list):
            resolved = []
            for lbl in label:
                if lbl not in cms and f"label_{lbl}" in cms:
                    lbl = f"label_{lbl}"
                if lbl not in cms:
                    raise ValueError(f"Label '{lbl}' not found. Available: {list(cms.keys())}")
                resolved.append(lbl)
            cms = {lbl: cms[lbl] for lbl in resolved}
        else:
            if label not in cms and f"label_{label}" in cms:
                label = f"label_{label}"
            if label not in cms:
                raise ValueError(f"Label '{label}' not found. Available: {list(cms.keys())}")
            cms = {label: cms[label]}

    labels = list(cms.keys())
    n = len(labels)
    nrows = -(-n // ncols)

    subplot_titles = [lbl.replace("label_", "") for lbl in labels]
    fig = make_subplots(
        rows=nrows, cols=ncols,
        subplot_titles=subplot_titles,
        vertical_spacing=0.12 / max(nrows, 1),
        horizontal_spacing=0.08,
    )

    colorscale = "Blues"
    for idx, lbl in enumerate(labels):
        row, col_idx = divmod(idx, ncols)
        cm_df = cms[lbl]
        classes = list(cm_df.index)
        z = cm_df.values.astype(float)

        if normalize:
            row_sums = z.sum(axis=1, keepdims=True)
            with np.errstate(invalid="ignore"):
                z = np.where(row_sums > 0, z / row_sums, 0.0)
            text_template = "%{z:.0%}"
            hover = "True: %{y}<br>Predicted: %{x}<br>Recall: %{z:.1%}<extra></extra>"
        else:
            text_template = "%{z:,d}"
            hover = "True: %{y}<br>Predicted: %{x}<br>Count: %{z:,}<extra></extra>"

        heatmap = go.Heatmap(
            z=z,
            x=classes,
            y=classes,
            colorscale=colorscale,
            showscale=False,
            text=z,
            texttemplate=text_template,
            hovertemplate=hover,
            xgap=2,
            ygap=2,
        )
        fig.add_trace(heatmap, row=row + 1, col=col_idx + 1)

        fig.update_xaxes(title_text="Predicted", tickangle=-40, row=row + 1, col=col_idx + 1)
        fig.update_yaxes(title_text="True", autorange="reversed", row=row + 1, col=col_idx + 1)

    title_text = "Confusion Matrices" + (" (normalisiert)" if normalize else "")

    fig.update_layout(
        title=dict(text=title_text, font_size=16),
        width=width,
        height=height,
    )
    _finalize(fig, save, chapter)


def plot_learning_curves(results, label_name="", width=1400, height=400, save=None, chapter=None, x_max=400, legend_rows=1, threshold=None, yaxis=[0, 1]):
    """Multi-trace line chart showing per-class F1 learning curves. Result is a dict mapping class labels to (sizes, scores) """
    del legend_rows
    fig = go.Figure()
    for class_label, (sizes, scores) in results.items():
        fig.add_trace(go.Scatter(
            x=sizes, y=scores, mode="lines+markers", name=str(class_label)
        ))

    if threshold is not None:
        fig.add_vline(
            x=threshold,
            line=dict(color="darkblue", dash="dash", width=2),
            annotation_text=f"Schwellwert: {threshold}",
            annotation_position="bottom right",
        )
    fig.update_layout(
        title=f"Lernkurven - {label_name}" if label_name else "Lernkurven",
        xaxis_title="Samples der Zielklasse",
        xaxis=dict(range=[0, x_max]),
        yaxis_title="F1-Score",
        yaxis=dict(range=yaxis),
        legend=dict(title="", yanchor="top", y=1.0, xanchor="left", x=1.02),
        width=width,
        height=height,
    )
    _finalize(fig, save, chapter)


def plot_feature_selection_curve(df, width=1400, height=600, title=None, xaxis_range=None, yaxis_range=None, save=None, chapter=None):
    """Line chart of F1-macro vs. number of features."""
    COLORS = [
        "#636EFA", "#EF553B", "#00CC96", "#AB63FA", "#FFA15A",
        "#19D3F3", "#FF6692", "#B6E880", "#FF97FF",
    ]
    fig = go.Figure()
    multi = "model" in df.columns
    groups = df.groupby("model", sort=False) if multi else [("", df)]
    for (model_name, group), color in zip(groups, COLORS):
        fig.add_trace(go.Scatter(
            x=group["n_features"],
            y=group["f1_macro"],
            mode="lines+markers",
            name=model_name if multi else None,
            text=group["last_feature_added"],
            hovertemplate="Features: %{x}<br>Last added: %{text}<br>F1-Macro: %{y:.4f}<extra></extra>",
            line=dict(color=color),
            marker=dict(size=6),
            showlegend=multi,
        ))
    fig.update_layout(
        title=title,
        xaxis_title="Anzahl Features",
        yaxis_title="F1-Macro (Validation)",
        xaxis=dict(tickmode="linear", tick0=1, dtick=1, range=xaxis_range),
        yaxis=dict(range=yaxis_range if yaxis_range is not None else [0, 1]),
        legend_title="Modell" if multi else None,
        width=width,
        height=height,
    )
    _finalize(fig, save, chapter)


def plot_feature_importance(df_imp, feature_groups, group_colors=None, title="Random Forest Feature Importance", width=1400, height=500, save=None, chapter=None):
    """Grouped bar chart of feature importances coloured by feature group."""
    _default_colors = {"geom": "#636EFA", "aabb": "#EF553B", "tfbb": "#00CC96", "topo": "#AB63FA", "material": "#FFA15A", "ray": "#19D3F3"}
    if group_colors is None:
        group_colors = _default_colors

    df_imp = df_imp.copy()
    group_lookup = {feature: group for group, keys in feature_groups.items() for feature in keys}
    df_imp["group"] = df_imp["feature"].map(group_lookup)

    fig = go.Figure()
    for group, color in group_colors.items():
        mask = df_imp["group"] == group
        fig.add_trace(go.Bar(
            x=df_imp[mask]["feature"],
            y=df_imp[mask]["importance"],
            name=group,
            marker_color=color,
            hovertemplate="%{x}<br>Importance: %{y:.4f}<extra></extra>",
        ))
    fig.update_layout(
        title=title,
        xaxis_title="Feature",
        yaxis_title="Importance",
        xaxis_tickangle=-45,
        barmode="group",
        width=width,
        height=height,
    )
    _finalize(fig, save, chapter)


def plot_coverage_precision_curve(thr_df, label_cols, title="Threshold sweep: coverage vs precision on covered subset", width=1400, height=500, save=None, chapter=None):
    """Plot coverage vs. precision for one or more labels across a sweep of confidence thresholds. Expects a DataFrame with columns: label, conf_threshold, coverage, precision."""
    fig = go.Figure()
    for label in label_cols:
        sub = thr_df[thr_df["label"] == label].sort_values("conf_threshold")
        fig.add_trace(go.Scatter(
            x=sub["coverage"],
            y=sub["precision"],
            mode="lines+markers",
            name=label,
            text=[f"conf_threshold={t:.2f}" for t in sub["conf_threshold"]],
            hovertemplate="%{text}<br>coverage=%{x:.3f}<br>precision=%{y:.4f}<extra>" + label + "</extra>",
        ))
    fig.update_layout(
        title=title,
        xaxis_title="Coverage (fraction of elements predicted)",
        yaxis_title="Precision on covered subset",
        width=width, height=height,
        legend=dict(orientation="h", yanchor="bottom", y=-0.25),
    )
    _finalize(fig, save, chapter)


def plot_class_contribution_comparison(features, contrib_wrong, contrib_true, wrong_label, true_label, title="Per-feature contribution to class logit", width=1400, height=None, save=None, chapter=None):
    """Horizontal grouped bar chart comparing per-feature contributions to the predicted logit for a wrong class vs. the true class for a single example."""
    height = height or max(400, len(features) * 30)
    fig = go.Figure()
    fig.add_trace(go.Bar(
        y=features, x=contrib_wrong, orientation="h",
        name=f"wrong class: '{wrong_label}'", marker_color="#d62728",
    ))
    fig.add_trace(go.Bar(
        y=features, x=contrib_true, orientation="h",
        name=f"true class: '{true_label}'", marker_color="#2ca02c",
    ))
    fig.update_layout(
        title=title,
        xaxis_title="Contribution to class logit",
        barmode="group",
        yaxis=dict(autorange="reversed"),
        width=width, height=height,
    )
    _finalize(fig, save, chapter)


def plot_float_boxplots(df, cols, title="Boxplots", ncols=3, col_height=300, width=1400, log_y=False, save = None, chapter = None):
    """Subplot grid of boxplots for a list of float columns."""

    nrows = -(-len(cols) // ncols)
    fig = make_subplots(rows=nrows, cols=ncols, subplot_titles=cols)
    for i, col in enumerate(cols):
        row, col_idx = divmod(i, ncols)
        vals = df[col].dropna()
        fig.add_trace(
            go.Box(y=vals, name=col, showlegend=False),
            row=row + 1, col=col_idx + 1,
        )
    fig.update_layout(title=title, height=nrows * col_height, width=width)
    if log_y:
        fig.update_yaxes(type="log")
    _finalize(fig, save, chapter)


def plot_feature_pca(df, feature_keys, label_col, max_samples=5000, height=700, width=1100, x_range=None, y_range=None, save=None, chapter=None):
    """PCA scatter plot of features coloured by given label class."""
    # convert features to numeric, drop non-informative features, and align labels
    feature_df = df[feature_keys].apply(pd.to_numeric, errors="coerce").fillna(0)
    feature_df = feature_df.loc[:, feature_df.std() > 0]
    labels = df[label_col].astype(str)

    # if there are too many samples, randomly sample to speed up PCA and plotting
    if len(feature_df) > max_samples:
        idx = feature_df.sample(max_samples, random_state=SEED).index
        feature_df = feature_df.loc[idx]
        labels = labels.loc[idx]

    # standardize features before PCA
    X = StandardScaler().fit_transform(feature_df)
    pca = PCA(n_components=2, random_state=SEED)
    components = pca.fit_transform(X)
    var1_pct, var2_pct = pca.explained_variance_ratio_[0] * 100, pca.explained_variance_ratio_[1] * 100

    pca_df = pd.DataFrame({
        "PC1": components[:, 0],
        "PC2": components[:, 1],
        label_col: labels.values,
    })

    fig = px.scatter(
        pca_df,
        x="PC1",
        y="PC2",
        color=label_col,
        opacity=0.6,
        title=f"PCA der Features für Label: {label_col}",
        labels={
            "PC1": f"PC1 ({var1_pct:.1f}% Varianz)",
            "PC2": f"PC2 ({var2_pct:.1f}% Varianz)",
        },
    )
    fig.update_traces(marker=dict(size=4))
    fig.update_layout(
        width=width,
        height=height,
        xaxis=dict(range=x_range),
        yaxis=dict(range=y_range),
    )
    _finalize(fig, save, chapter, name_suffix=f"_{label_col}")


def plot_feature_label_correlation(df, feature_keys, label_col, height=800, width=1400, save=None, chapter=None):
    """Plot an interactive heatmap of Pearson r between numeric features and label classes."""
    feature_df = df[feature_keys].apply(pd.to_numeric, errors="coerce").fillna(0)
    feature_df = feature_df.loc[:, feature_df.std() > 0]


    label_dummies = pd.get_dummies(df[label_col].astype(str))
    corr = label_dummies.apply(lambda col: feature_df.corrwith(col))

    fig = px.imshow(
        corr.T,
        color_continuous_scale="RdBu_r",
        color_continuous_midpoint=0,
        zmin=-1,
        zmax=1,
        aspect="auto",
        title=f"Feature Korrelationsmatrix für das Label: {label_col}",
        labels={"x": "Feature", "y": "Label class", "color": "Pearson r"},
    )
    fig.update_layout(
        width=width,
        height=height,
        xaxis_tickangle=-45,
    )
    _finalize(fig, save, chapter, name_suffix=f"_{label_col}")