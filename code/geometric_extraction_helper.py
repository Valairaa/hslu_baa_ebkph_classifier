# geometric_extraction_helper.py
import re
import numpy as np
import ifcopenshell
import ifcopenshell.geom
import ifcopenshell.util.element
import sys
from scipy.spatial import ConvexHull

# load helper functions
sys.path.insert(0, "../../")
from dataloader import _get_material_names

# set global variables
_IGNORE_TYPES = {"IfcSite", "IfcBuilding", "IfcBuildingStorey", "IfcOpeningElement"}
_GEOM_SETTINGS = None
_WORLD_GEOM_SETTINGS = None
_SPLIT_PATTERN = re.compile(r'[,/]|\s+[--]\s+|_|\s+|-')

GENERAL_KEYS = [
    "volume",
    "surface_area",
    "projected_area",
    "centroid_x",
    "centroid_y",
    "centroid_z",
    "z_min",
    "z_max",
    "z_range",
    "ratio_area_vol",
    "compactness", # new proposal, not found in literature papers
    "layer_count" # new proposal, not found in literature papers
]
GENERAL_KEYS = [f"geom_{geom}" for geom in GENERAL_KEYS]

AABB_KEYS = [
    "min_x", "min_y", "min_z",
    "max_x", "max_y", "max_z",
    "len_x", "len_y", "len_z",
    "ratio_z_x",
    "ratio_z_y",
    "ratio_x_y",
    "diagonal",
    "volume",
    ]
AABB_KEYS = [f"aabb_{aabb}" for aabb in AABB_KEYS]

TFBB_KEYS = [
    "extent_0",
    "extent_1",
    "extent_2",
    "volume",
    "ratio_01",
    "ratio_02",
    "ratio_12",
    "linearity",
    "planarity",
    "sphericity",
    "primary_ax_x",
    "primary_ax_y",
    "primary_ax_z",
]
TFBB_KEYS = [f"tfbb_{tfbb}" for tfbb in TFBB_KEYS]

TOPO_KEYS = [
    "vertex_count",
    "face_count",
    "unique_edge_count",
    "euler_characteristic",
    "genus",
    "max_face_area",
    "avg_face_area",
    "vertex_edge_ratio",
    "connected_components",
]
TOPO_KEYS = [f"topo_{topo}" for topo in TOPO_KEYS]

# important materials for the elements, new proposal, not found in literature papers
_MATERIAL_TOKENS = [
    "allgemein",
    "aluminium",
    "backstein",
    "bekleidung",
    "belag",
    "beton",
    "dämm",
    "foamglas",
    "gips",
    "glas",
    "holz",
    "werkstoff",
    "kalksandstein",
    "keramik",
    "kies",
    "kunststein",
    "kunststoff",
    "metall",
    "mörtel",
    "naturstein",
    "putz",
    "stahl",
    "zement"
]
MATERIAL_KEYS = [f"mat_{tok}" for tok in _MATERIAL_TOKENS]

# raycasting features, new proposal, not found in literature papers
RAY_KEYS = ["horizontal_elements_above", "horizontal_elements_below"]
_HORIZONTAL_THRESHOLD = 0.7

ALL_FEATURE_KEYS = AABB_KEYS + GENERAL_KEYS + TFBB_KEYS + TOPO_KEYS + MATERIAL_KEYS + RAY_KEYS
FEATURE_COUNT = len(ALL_FEATURE_KEYS)

def _get_settings(world_coords = False):
    """Returns cached IfcOpenShell geometry settings. Use world_coords=True for raycasting."""
    global _GEOM_SETTINGS, _WORLD_GEOM_SETTINGS

    # for raycasting, world coordinates are needed to get the correct absolute positions of the elements in the model
    if world_coords:
        if _WORLD_GEOM_SETTINGS is None:
            s = ifcopenshell.geom.settings()
            s.set(s.USE_WORLD_COORDS, True)
            s.set(s.WELD_VERTICES, True)
            _WORLD_GEOM_SETTINGS = s
        return _WORLD_GEOM_SETTINGS
    
    # for general geometry extraction use local coordinates are sufficient and in all models consistent
    else:
        if _GEOM_SETTINGS is None:
            s = ifcopenshell.geom.settings()
            s.set(s.USE_WORLD_COORDS, False)
            s.set(s.WELD_VERTICES, True)
            _GEOM_SETTINGS = s
        return _GEOM_SETTINGS

def _get_geometry(element, settings = None):
    """Returns vertices and faces for an IFC element using IfcOpenShell geometry engine."""
    if settings is None:
        settings = _get_settings()

    # get vertices and faces from IfcOpenShell geometry
    try:
        shape = ifcopenshell.geom.create_shape(settings, element)
    except RuntimeError:
        # return None if geometry cannot be created
        return None, None

    verts = np.array(shape.geometry.verts, dtype=np.float64).reshape(-1, 3)
    faces = np.array(shape.geometry.faces, dtype=np.int32).reshape(-1, 3)

    # if geometry is missing or invalid, return None
    if len(verts) == 0 or len(faces) == 0:
        return None, None

    return verts, faces

def _nan_dict(keys):
    """Returns a dict with given keys and NaN values (for missing/invalid geometry)."""
    return {k: float("nan") for k in keys}

def _safe_ratio(numerator, denominator):
    """Calculates a ratio with protection against division by zero (returns NaN if denominator is too small)."""
    return numerator / denominator if abs(denominator) > 1e-12 else float("nan")

def _projected_area_xy(verts):
    """Calculates the projected area of the vertices onto the XY plane using a convex hull."""
    # if less than 3 unique points, convex hull area is not defined
    pts_2d = verts[:, :2]
    
    # calculate convex hull area if there are at least 3 unique points, otherwise return NaN
    if len(np.unique(pts_2d, axis=0)) >= 3:
        try:
            hull = ConvexHull(pts_2d)
            # will close the hull and area count is an upper bound (holes will be ignored)
            # example: an L-Shape will be approximated by the area of the bounding rectangle of its projection
            return float(hull.volume)
        except Exception:
            # ignoring collinear points or other issues
            return float("nan")

def _count_connected_components_fast(faces: np.ndarray, n_verts: int) -> int:
    """Returns the number of connected components in the mesh using a fast Union-Find algorithm on faces."""
    # disjoint set data structure for connected components
    parent = list(range(n_verts))

    # find with path compression
    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    # only the number of connected components is needed, so the union operation can be simplified to just connect vertices of the same face
    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    # connect vertices of the same face
    for f in faces:
        union(int(f[0]), int(f[1]))
        union(int(f[1]), int(f[2]))

    # only consider vertices that are actually used in faces
    used_verts = set(faces.flatten().tolist())
    roots = {find(i) for i in used_verts}

    return len(roots)

def _get_layer_count(element):
    """Extracts the layer counts and gives 1 for simple materials without layers, 0 if no material is assigned or if there is an error."""
    material = ifcopenshell.util.element.get_material(element)

    try:
        if material is None:
            return 0

        # for walls, slabs, roofs, etc. with layered materials
        if material.is_a('IfcMaterialLayerSet'):
            return len(material.MaterialLayers)
        
        if material.is_a('IfcMaterialLayerSetUsage'):
            return len(material.ForLayerSet.MaterialLayers)

        # for windows, doors, etc. with constituent materials
        if material.is_a('IfcMaterialConstituentSet'):
            return len(material.MaterialConstituents) if material.MaterialConstituents else 1

        # for profiles with material sets
        if material.is_a('IfcMaterialProfileSet'):
            return len(material.MaterialProfiles) if material.MaterialProfiles else 1
            
        if material.is_a('IfcMaterialProfileSetUsage'):
            return len(material.ForProfileSet.MaterialProfiles) if material.ForProfileSet.MaterialProfiles else 1

        # for simple materials without layers, count as 1 layer
        if material.is_a('IfcMaterial'):
            return 1
            
        if material.is_a('IfcMaterialList'):
            return len(material.Materials)

        return 0
    except Exception:
        return 0

# extract general geometric features
# Source: Ma et al. (2018) for centroid, Koo et al. (2019) for area/volume ratios
def extract_general_features(verts, faces, element=None):
    """Returns general geometric features: volume, surface area, projected area, centroid, z-range, area/volume ratio, compactness and layer counts."""

    # if geometry is missing or invalid, return NaN for all general features except layer_count (0)
    if verts is None or faces is None or len(faces) == 0:
        result = _nan_dict(GENERAL_KEYS)
        return result
    
    # get layyer count if it is given for element
    layer_count = _get_layer_count(element) if element is not None else 0

    # get X, Y and Z vertices of each face
    v0 = verts[faces[:, 0]]
    v1 = verts[faces[:, 1]]
    v2 = verts[faces[:, 2]]

    # get face areas with cross product (Ma et al. 2018)
    edges_a = v1 - v0
    edges_b = v2 - v0

    # get normal vectors and their norms for area calculation
    cross_products = np.cross(edges_a, edges_b)
    cross_norms = np.linalg.norm(cross_products, axis=1)

    # calculate face areas, 0.5 because it is the are of the triangle
    face_areas = 0.5 * cross_norms
    surface_area = float(face_areas.sum())

    # calculate volume based on tetrahedron V = 1 / 3 * A * h for all faces. 
    # A (Area) is cross product of two edges (v1, v2) divided by 2 and the height is v0.
    raw_volume = ((v0 * np.cross(v1, v2)).sum(axis=1) / 6.0).sum()
    volume = float(abs(raw_volume)) # makes volume positive, even if face orientation is inconsistent

    # calculate centroid as area-weighted average of triangle centroids
    centroids_tri = (v0 + v1 + v2) / 3.0 
    total_area = face_areas.sum()

    # for small volumes/areas, fallback to simple average of vertices is necessary
    if total_area > 1e-12:
        centroid = (centroids_tri * face_areas[:, None]).sum(axis=0) / total_area
    else:
        centroid = verts.mean(axis=0)

    # calculate projected area in XY plane using convex hull
    projected_area = _projected_area_xy(verts)

    # calculate z-ranges
    z_min = float(verts[:, 2].min())
    z_max = float(verts[:, 2].max())

    # calculate area/volume ratio
    ratio_area_vol = _safe_ratio(surface_area, volume)

    # calculate compactness, closer to one means more compact (sphere)
    # https://en.wikipedia.org/wiki/Sphericity#:~:text=Defined%20by%20Wadell%20in%201935,have%20sphericity%20less%20than%201.
    compactness = _safe_ratio(36.0 * np.pi * volume**2, surface_area**3) ** (1/3)

    return {
        "geom_volume":         volume,
        "geom_surface_area":   surface_area,
        "geom_projected_area": projected_area,
        "geom_centroid_x":     float(centroid[0]),
        "geom_centroid_y":     float(centroid[1]),
        "geom_centroid_z":     float(centroid[2]),
        "geom_z_min":          z_min,
        "geom_z_max":          z_max,
        "geom_z_range":        float(z_max - z_min),
        "geom_ratio_area_vol": ratio_area_vol,
        "geom_compactness":    compactness,
        "geom_layer_count":    layer_count
    }

# calculate AABB features (bounding box)
# Source: Belsky et al. (2016), Utkucu et al. (2024), Koo et al. (2019) for ratios
def extract_aabb_features(verts):
    """Returns AABB features: min/max coordinates, lengths, ratios, diagonal, and volume."""
    # if geometry is missing or invalid, return NaN for all AABB features
    if verts is None or len(verts) == 0:
        return _nan_dict(AABB_KEYS)

    # get min / max coordinates and lengths
    mn = verts.min(axis=0)
    mx = verts.max(axis=0)
    lengths = mx - mn

    # calculate ratios, diagonal, and volume
    lx, ly, lz = lengths
    diag = float(np.linalg.norm(lengths))
    vol_aabb = float(lx * ly * lz)

    return {
        "aabb_min_x":    float(mn[0]),
        "aabb_min_y":    float(mn[1]),
        "aabb_min_z":    float(mn[2]),
        "aabb_max_x":    float(mx[0]),
        "aabb_max_y":    float(mx[1]),
        "aabb_max_z":    float(mx[2]),
        "aabb_len_x":    float(lx),
        "aabb_len_y":    float(ly),
        "aabb_len_z":    float(lz),
        "aabb_ratio_z_x": _safe_ratio(lz, lx),
        "aabb_ratio_z_y": _safe_ratio(lz, ly),
        "aabb_ratio_x_y": _safe_ratio(lx, ly),
        "aabb_diagonal":  diag,
        "aabb_volume":    vol_aabb,
    }

# calculate TFBB features which are based on PCA of the vertex point cloud, closer to the actual geometry than AABB, but more expensive to compute
# Source: Jylänkt (2015) for TFBB-Formdeskriptoren, Ma et al. (2018) for axis
def extract_tfbb_features(verts):
    """Calculates TFBB features based on PCA of the vertex point cloud: extents, ratios, form descriptors, and primary axis."""
    # if geometry is missing or invalid, return NaN for all TFBB features
    if verts is None or len(verts) < 4:
        return _nan_dict(TFBB_KEYS)

    # calculate covariance matrix of centered vertices
    centered = verts - verts.mean(axis=0)
    cov = np.cov(centered.T)

    # eigenvalues/eigenvectors of the covariance matrix give the principal axes and their variances (extent in each direction)
    # lambda 1 ≥ lambda 2 ≥ lambda 3
    eigenvalues, eigenvectors = np.linalg.eigh(cov)

    # get indices for sorting eigenvalues in descending order
    idx = np.argsort(eigenvalues)[::-1]
    eigenvalues = eigenvalues[idx]

    # each column is a principal axis (eigenvector)
    eigenvectors = eigenvectors[:, idx]

    # project all vertices onto the eigenvectors to get the extents in each principal direction
    projections = centered @ eigenvectors 
    extents = projections.max(axis=0) - projections.min(axis=0)

    # take max value for numerical stability (avoid division by zero in ratios and form descriptors)
    e0, e1, e2 = extents
    lam1, lam2, lam3 = np.maximum(eigenvalues, 1e-12)

    # get the form descriptors based on the eigenvalues, normalized by the largest eigenvalue
    linearity  = _safe_ratio(lam1 - lam2, lam1)
    planarity  = _safe_ratio(lam2 - lam3, lam1)
    sphericity = _safe_ratio(lam3, lam1)

    # primary axis is the eigenvector corresponding to the largest eigenvalue (extent)
    primary_axis = eigenvectors[:, 0]

    return {
        "tfbb_extent_0":     float(e0),
        "tfbb_extent_1":     float(e1),
        "tfbb_extent_2":     float(e2),
        "tfbb_volume":       float(e0 * e1 * e2),
        "tfbb_ratio_01":     _safe_ratio(e0, e1),
        "tfbb_ratio_02":     _safe_ratio(e0, e2),
        "tfbb_ratio_12":     _safe_ratio(e1, e2),
        "tfbb_linearity":    float(linearity),
        "tfbb_planarity":    float(planarity),
        "tfbb_sphericity":   float(sphericity),
        "tfbb_primary_ax_x": float(primary_axis[0]),
        "tfbb_primary_ax_y": float(primary_axis[1]),
        "tfbb_primary_ax_z": float(primary_axis[2]),
    }

# calculate topological features
# Sources: Utkucu et al. (2024), Collins et al. (2021)
def extract_topology_features(verts, faces):
    """ Returns topological features: vertex/face/edge counts, Euler characteristic, genus, max/avg face area, vertex-edge ratio, avg vertex degree, and number of connected components."""
    # if geometry is missing or invalid, return NaN for all topological features
    if verts is None or faces is None or len(faces) == 0:
        return _nan_dict(TOPO_KEYS)

    # count vertices and faces
    V = len(verts)
    F = len(faces)
    
    # count unique edges
    edges_raw = np.concatenate([
        faces[:, [0, 1]],
        faces[:, [1, 2]],
        faces[:, [2, 0]],
    ], axis=0)

    edges_sorted = np.sort(edges_raw, axis=1)
    E = len(np.unique(edges_sorted, axis=0))   
    
    # get X, Y and Z vertices of each face
    v0 = verts[faces[:, 0]]
    v1 = verts[faces[:, 1]]
    v2 = verts[faces[:, 2]]

    # get face areas with cross product (Ma et al. 2018)
    edges_a = v1 - v0
    edges_b = v2 - v0

    # get normal vectors and their norms for area calculation
    cross_products = np.cross(edges_a, edges_b)
    cross_norms = np.linalg.norm(cross_products, axis=1)

    # calculate face areas, 0.5 because it is the are of the triangle
    face_areas = 0.5 * cross_norms

    # calculate max and average face area, vertex-edge ratio, and average vertex degree
    max_face_area = float(face_areas.max())
    avg_face_area = float(face_areas.mean())
    vertex_edge_ratio = _safe_ratio(V, E)

    # calculate number of connected components using Union-Find on faces
    n_components = _count_connected_components_fast(faces, V)

    # calculate Euler characteristic and genus, which are topological invariants that describe the shape's connectivity and number of holes
    # https://en.wikipedia.org/wiki/Euler_characteristic
    euler = V - E + F

    # χ = 2C − 2g, C is the number of connected components, g is the genus (number of holes) and χ is the Euler characteristic
    genus = (2 * n_components - euler) / 2

    return {
        "topo_vertex_count":         float(V),
        "topo_face_count":           float(F),
        "topo_unique_edge_count":    float(E),
        "topo_euler_characteristic": float(euler),
        "topo_genus":                float(genus),
        "topo_max_face_area":        max_face_area,
        "topo_avg_face_area":        avg_face_area,
        "topo_vertex_edge_ratio":    vertex_edge_ratio,
        "topo_connected_components": float(n_components),
    }

def extract_material_features(element):
    """Returns binary features for each material token found as substring in the elements material names."""
    raw_names = _get_material_names(element)
    if not raw_names:
        return {key: 0 for key in MATERIAL_KEYS}

    combined = " ".join(name.lower() for name in raw_names)
    return {f"mat_{tok}": int(tok in combined) for tok in _MATERIAL_TOKENS}


def _is_horizontal(verts):
    """True if the element's planar normal (PCA smallest eigenvector) is within _HORIZONTAL_THRESHOLD of vertical."""
    # if there are less than 4 vertices, PCA is not stable
    if len(verts) < 4:
        return False
    centered = verts - verts.mean(axis=0)
    
    # get _ and eigenvectors, the smallest eigenvector corresponds to the normal of the best fitting plane
    _, eigvecs = np.linalg.eigh(np.cov(centered.T))
    return abs(float(eigvecs[2, 0])) > _HORIZONTAL_THRESHOLD


def extract_ray_features(element, tree, ifc_file, horizontal_cache: dict):
    """Counts horizontal elements directly above and below via raycasting with a 1 m offset.
    horizontal_cache is a shared dict {GlobalId: bool} that avoids recomputing geometry per hit.
    """
    # check if the element itself is horizontal and cache the result so save computation time
    verts, _ = _get_geometry(element, _get_settings(world_coords=True))
    is_horiz = _is_horizontal(verts) if verts is not None else False
    horizontal_cache[element.GlobalId] = is_horiz

    # if the element itself is not horizontal, ray features are not meaningful
    if not is_horiz:
        return {key: float("nan") for key in RAY_KEYS}

    # get x, y and z ranges of the element to determine ray origins and directions
    cx   = float(np.mean(verts[:, 0]))
    cy   = float(np.mean(verts[:, 1]))
    zmax = float(verts[:, 2].max())
    zmin = float(verts[:, 2].min())
    guid = element.GlobalId
    offset = 1.0

    # helper function to count horizontal elements in a given direction (up or down)
    def _count(origin, direction):
        count = 0
        for hit in tree.select_ray(origin, direction):
            hit_element = ifc_file.by_id(hit.instance.id())
            hit_guid = hit_element.GlobalId
            if hit_guid == guid:
                continue
            # populate cache on first encounter, reuse on all subsequent hits
            if hit_guid not in horizontal_cache:
                hv, _ = _get_geometry(hit_element, _get_settings(world_coords=True))
                horizontal_cache[hit_guid] = _is_horizontal(hv) if hv is not None else False
            if horizontal_cache[hit_guid]:
                count += 1
        return count

    return {
        "horizontal_elements_above": float(_count((cx, cy, zmax + offset), (0.0, 0.0,  1.0))),
        "horizontal_elements_below": float(_count((cx, cy, zmin - offset), (0.0, 0.0, -1.0))),
    }


def extract_all_features(element, settings, tree=None, ifc_file=None, horizontal_cache=None):
    """Returns a combined dict of all geometric, material and ray features for a given IFC element."""
    verts, faces = _get_geometry(element, settings)

    # extract all features, if geometry is missing/invalid, geometric features will be NaN but material features can still be extracted
    aabb      = extract_aabb_features(verts)
    gen       = extract_general_features(verts, faces, element)
    tfbb      = extract_tfbb_features(verts)
    topo      = extract_topology_features(verts, faces)
    materials = extract_material_features(element)
    ray       = extract_ray_features(element, tree, ifc_file, horizontal_cache)

    # combine all features into a single dict
    features = {}
    features.update(aabb)
    features.update(gen)
    features.update(tfbb)
    features.update(topo)
    features.update(materials)
    features.update(ray)

    return features

# main iterator function to get all elements with their features
def iter_elements_with_features(ifc_file, ifc_types=None, settings=None):
    """Iterates over all elements of the IFC file and returns all geometric features extracted from the element's geometry."""
    if settings is None:
        settings = _get_settings()

    if ifc_types is None:
        elements = [e for e in ifc_file.by_type("IfcProduct") if e.is_a() not in _IGNORE_TYPES]
    else:
        elements = []
        for t in ifc_types:
            elements.extend(ifc_file.by_type(t))

    # build spatial tree once per model for raycasting
    tree_settings = ifcopenshell.geom.settings()
    tree_settings.set(tree_settings.DISABLE_OPENING_SUBTRACTIONS, True)
    tree = ifcopenshell.geom.tree(ifc_file, tree_settings)

    # shared cache with GlobalId
    horizontal_cache = {}

    for element in elements:
        features = extract_all_features(element, settings, tree, ifc_file, horizontal_cache)
        yield element, features