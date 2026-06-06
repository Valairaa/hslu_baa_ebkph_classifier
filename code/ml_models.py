from sklearn.base import BaseEstimator, TransformerMixin, ClassifierMixin, clone
from sklearn.preprocessing import LabelEncoder, PowerTransformer

from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score, confusion_matrix, matthews_corrcoef

from sklearn.multioutput import MultiOutputClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from sklearn.naive_bayes import GaussianNB
from sklearn.preprocessing import PowerTransformer
from sklearn.svm import SVC
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.ensemble import ExtraTreesClassifier

from sklearn.ensemble import GradientBoostingClassifier      # classic sklearn gradient boosting -> slower but well-established
from sklearn.ensemble import HistGradientBoostingClassifier  # sklearn model inspired by LightGBM -> fast alternative to GradientBoostingClassifier

# import global settings
from _settings import SEED

# custom transformer to cap outliers based on IQR, to be used in Pipelines.
class IQRCapper(BaseEstimator, TransformerMixin):
    """Clips feature values to [Q1 - 1.5*IQR, Q3 + 1.5*IQR] bounds fitted on training data."""

    def fit(self, X, _y = None):
        q1, q3 = X.quantile(0.25), X.quantile(0.75)
        iqr = q3 - q1
        self.lower_ = q1 - 1.5 * iqr
        self.upper_ = q3 + 1.5 * iqr
        return self

    def transform(self, X, _y=None):
        return X.clip(lower=self.lower_, upper=self.upper_, axis=1)
    
# wraps any sklearn classifier to encode string labels to integers and decode predictions back
class StringToIntWrapper(BaseEstimator, ClassifierMixin):
    def __init__(self, estimator):
        self.estimator = estimator

    def fit(self, X, y):
        self.le_ = LabelEncoder().fit(y)
        self.estimator.fit(X, self.le_.transform(y))
        self.classes_ = self.le_.classes_
        return self

    def predict(self, X):
        return self.le_.inverse_transform(self.estimator.predict(X))

    def predict_proba(self, X):
        return self.estimator.predict_proba(X)

# ml models class to create pre-configured sklearn Pipelines for different model types.
# all models can handle negative values and for the naive_bayes algorithm is the "GaussianNB" sufficient to handle it
class ML_Models:
    """Creates pre-configured sklearn Pipelines for different model types."""
    
    @staticmethod
    def naive_bayes():
        # deskewing data is necessary here. NB is robust against outliers and scale, but not skewed data. No scaling needed.
        return Pipeline([
            ("deskew", PowerTransformer(method="yeo-johnson", standardize=False)),
            ("model", MultiOutputClassifier(GaussianNB())),
        ])

    @staticmethod
    def logistic_regression(C = 1.0, max_iter = 1000):
        # cap outliers, deskew, standardize and scale (by standardize=True) the data
        return Pipeline([
            ("capper", IQRCapper()),
            ("deskew", PowerTransformer(method="yeo-johnson", standardize=True)),
            ("model", MultiOutputClassifier(LogisticRegression(C=C, max_iter=max_iter))),
        ])

    @staticmethod
    def knn(n_neighbors = 5):
        # cap outliers, deskew, standardize and scale (by standardize=True) the data
        return Pipeline([
            ("capper", IQRCapper()),
            ("deskew", PowerTransformer(method="yeo-johnson", standardize=True)),
            ("model", MultiOutputClassifier(KNeighborsClassifier(n_neighbors=n_neighbors))),
        ])

    @staticmethod
    def svm(C = 1.0, gamma = "scale"):
        # cap outliers, deskew, standardize and scale (by standardize=True) the data
        return Pipeline([
            ("capper", IQRCapper()),
            ("deskew", PowerTransformer(method="yeo-johnson", standardize=True)),
            ("model", MultiOutputClassifier(SVC(kernel="rbf", C=C, gamma=gamma))),
        ])

    @staticmethod
    def decision_tree(max_depth = None, random_state=SEED):
        # invariant to scale, skew, and outliers, no data preprocessing needed. Does not support multi-output natively.
        return Pipeline([
            ("model", MultiOutputClassifier(DecisionTreeClassifier(max_depth=max_depth, random_state=random_state))),
        ])

    @staticmethod
    def random_forest(n_estimators = 100, random_state=SEED, **kwargs):
        # invariant to scale, skew, and outliers, no data preprocessing needed.
        return Pipeline([
            ("model", RandomForestClassifier(n_estimators=n_estimators, random_state=random_state, class_weight="balanced", **kwargs)),
        ])

    @staticmethod
    def extra_trees(n_estimators = 100, random_state=SEED):
        # invariant to scale, skew, and outliers, no data preprocessing needed.
        return Pipeline([
            ("model", ExtraTreesClassifier(n_estimators=n_estimators, random_state=random_state)),
        ])

    @staticmethod
    def hist_gradient_boosting(max_iter = 100, random_state=SEED):
        # invariant to scale, skew, and outliers, no data preprocessing needed. Does not support multi-output natively.
        return Pipeline([
            ("model", MultiOutputClassifier(HistGradientBoostingClassifier(max_iter=max_iter, random_state=random_state))),
        ])

    @staticmethod
    def gradient_boosting(n_estimators = 100, random_state=SEED):
        # invariant to scale, skew, and outliers, no data preprocessing needed. Does not support multi-output natively.
        return Pipeline([
            ("model", MultiOutputClassifier(GradientBoostingClassifier(n_estimators=n_estimators, random_state=random_state))),
        ])

    @staticmethod
    def lightgbm(n_estimators = 100, random_state=SEED):
        # only load lightgbm when this function is called
        from lightgbm import LGBMClassifier  # type: ignore

        # invariant to scale, skew and outliers.
        # supports multi-output natively via MultiOutputClassifier.
        return Pipeline([
            ("model", MultiOutputClassifier(LGBMClassifier(n_estimators=n_estimators, random_state=random_state, verbose=-1))),
        ])

    @staticmethod
    def xgboost(n_estimators = 100, random_state=SEED, **kwargs):
        # only load xgboost when this function is called
        from xgboost import XGBClassifier  # type: ignore

        # invariant to scale, skew, and outliers. Encoding from string labels to integers necessary.
        return Pipeline([
            ("model", MultiOutputClassifier(
                StringToIntWrapper(XGBClassifier(n_estimators=n_estimators, random_state=random_state, eval_metric="mlogloss", **kwargs))
            )),
        ])

# add a registry for easier access to model pipelines by name
model_registry = {
    "naive_bayes": ML_Models.naive_bayes,
    "logistic_regression": ML_Models.logistic_regression,
    "knn": ML_Models.knn,
    "svm": ML_Models.svm,
    "decision_tree": ML_Models.decision_tree,
    "random_forest": ML_Models.random_forest,
    "extra_trees": ML_Models.extra_trees,
    "hist_gradient_boosting": ML_Models.hist_gradient_boosting,
    "gradient_boosting": ML_Models.gradient_boosting,
    "lightgbm": ML_Models.lightgbm,
    "xgboost": ML_Models.xgboost,
}