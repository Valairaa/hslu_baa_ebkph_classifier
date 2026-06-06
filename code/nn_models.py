from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import f1_score, accuracy_score, precision_score, recall_score, matthews_corrcoef
import numpy as np

try:
    import torch  # type: ignore
    import torch.nn as nn  # type: ignore
    from torch.utils.data import DataLoader, TensorDataset  # type: ignore
    _TORCH_AVAILABLE = True
except ImportError:
    _TORCH_AVAILABLE = False

# plain NN architecture with a four layer backbone and separate classification heads for each label
class PlainNN(nn.Module):
    """Shared backbone with four layers and one classification head per label."""

    def __init__(self, n_inputs, n_hidden, label_num_classes, dropout=0.3):
        if not _TORCH_AVAILABLE:
            raise ImportError("PyTorch is required for PlainNN.")
        super().__init__()
        self.backbone = nn.Sequential(
            nn.Linear(n_inputs, n_hidden // 2),
            nn.ReLU(),
            nn.Linear(n_hidden // 2, n_hidden),
            nn.ReLU(),
            nn.Linear(n_hidden, n_hidden // 2),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(n_hidden // 2, n_hidden // 4),
            nn.ReLU(),
        )
        self.heads = nn.ModuleList([
            nn.Linear(n_hidden // 4, n_classes) for n_classes in label_num_classes
        ])

    def forward(self, x):
        features = self.backbone(x)
        return [head(features) for head in self.heads]


class NNClassifier:
    """Wraps a PlainNN with fit/predict interface for use in ModelTrainer."""

    def __init__(self, nn_model, label_cols):
        self.nn_model = nn_model
        self.label_cols = label_cols
        self._label_encoders = []

    def _compute_per_label_metrics(self, X, y):
        y_pred = self.predict(X)
        return {
            col: {
                "accuracy": round(accuracy_score(y[col], y_pred[:, i]), 4),
                "precision": round(precision_score(y[col], y_pred[:, i], average="weighted", zero_division=0), 4),
                "recall": round(recall_score(y[col], y_pred[:, i], average="weighted", zero_division=0), 4),
                "mcc": round(matthews_corrcoef(y[col], y_pred[:, i]), 4),
                "f1_weighted": round(f1_score(y[col], y_pred[:, i], average="weighted", zero_division=0), 4),
                "f1_macro": round(f1_score(y[col], y_pred[:, i], average="macro", zero_division=0), 4),
            }
            for i, col in enumerate(self.label_cols)
        }

    def fit(self, X_train, y_train, epochs=50, batch_size=64, lr=1e-3, device=None, X_val=None, y_val=None, on_epoch_end=None):
        # determine device to use for training
        if device is None:
            if torch.cuda.is_available():
                device = "cuda"
            elif torch.backends.mps.is_available():
                device = "mps"
            else:
                device = "cpu"
        self._device = torch.device(device)

        # encode string labels to integers for each label column
        self._label_encoders = [LabelEncoder() for _ in self.label_cols]
        y_enc = np.column_stack([
            le.fit_transform(y_train[col]) for le, col in zip(self._label_encoders, self.label_cols)
        ])

        # convert data to PyTorch tensors and create DataLoader for training
        X_arr = X_train.values if hasattr(X_train, "values") else np.asarray(X_train)
        X_t = torch.tensor(X_arr, dtype=torch.float32)
        y_t = torch.tensor(y_enc, dtype=torch.long)

        loader = DataLoader(TensorDataset(X_t, y_t), batch_size=batch_size, shuffle=True)
        self.nn_model = self.nn_model.to(self._device)

        # set up optimizer and loss function
        optimizer = torch.optim.AdamW(self.nn_model.parameters(), lr=lr)
        criterion = nn.CrossEntropyLoss()

        # training loop with validation and optional callback after each epoch
        pad = len(str(epochs))
        for epoch in range(1, epochs + 1):
            self.nn_model.train()
            epoch_loss = 0.0
            for X_b, y_b in loader:
                X_b, y_b = X_b.to(self._device), y_b.to(self._device)

                optimizer.zero_grad()

                logits = self.nn_model(X_b)
                loss = sum(criterion(logits[i], y_b[:, i]) for i in range(len(self.label_cols)))

                loss.backward()
                optimizer.step()

                epoch_loss += loss.item()

            avg_loss = epoch_loss / len(loader)

            if X_val is not None and y_val is not None:
                val_metrics = self._compute_per_label_metrics(X_val, y_val)

                f1_macros = [val_metrics[col]["f1_macro"] for col in self.label_cols]
                label_str = "  ".join(f"{col}={v:.4f}" for col, v in zip(self.label_cols, f1_macros))
                print(f"Epoch {epoch:{pad}d}/{epochs}, loss={avg_loss:.4f}, val f1_macro: {label_str}, mean={np.mean(f1_macros):.4f}")
                
                if on_epoch_end is not None:
                    train_metrics = self._compute_per_label_metrics(X_train, y_train)
                    on_epoch_end(epoch, avg_loss, train_metrics, val_metrics)

        return self

    def predict(self, X):
        # convert input to tensor and move to same device as model
        X_arr = X.values if hasattr(X, "values") else np.asarray(X)
        X_t = torch.tensor(X_arr, dtype=torch.float32).to(self._device)

        # predict logits for each label and decode back to original string labels
        self.nn_model.eval()
        with torch.no_grad():
            logits = self.nn_model(X_t)

        # get precictions for each label
        predictions = []
        for le, label_logits in zip(self._label_encoders, logits):
            # take argmax to get predicted class indices
            predicted_indices = label_logits.argmax(dim=1).cpu().numpy()

            # inverse transform to get original string labels and append to predictions list
            predicted_labels = le.inverse_transform(predicted_indices)
            predictions.append(predicted_labels)

        return np.column_stack(predictions)

    def predict_proba(self, X):
        """Return predicted probabilities for each class and label as list of arrays."""
        X_arr = X.values if hasattr(X, "values") else np.asarray(X)
        X_t = torch.tensor(X_arr, dtype=torch.float32).to(self._device)

        self.nn_model.eval()
        with torch.no_grad():
            logits = self.nn_model(X_t)

        return [torch.softmax(lg, dim=1).cpu().numpy() for lg in logits]
