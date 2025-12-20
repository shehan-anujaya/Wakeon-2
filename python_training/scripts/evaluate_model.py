"""
Model Evaluation Script for WakeOn

Comprehensive evaluation metrics and visualization:
- Confusion matrix
- Classification report
- ROC curves
- Precision-Recall curves
- Per-class metrics
"""

import argparse
import sys
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    roc_curve,
    auc,
    precision_recall_curve,
    average_precision_score,
)
import tensorflow as tf
from tensorflow import keras


# Class names
CLASS_NAMES = ['Alert', 'Drowsy', 'Microsleep']


def load_model(model_path: str) -> keras.Model:
    """Load trained model from path."""
    print(f"Loading model from {model_path}...")
    return keras.models.load_model(model_path)


def load_test_data(data_path: str) -> tuple:
    """Load test data."""
    data_dir = Path(data_path)
    
    X_test = np.load(data_dir / 'X_test.npy')
    y_test = np.load(data_dir / 'y_test.npy')
    
    print(f"Test samples: {len(X_test)}")
    return X_test, y_test


def plot_confusion_matrix(y_true: np.ndarray, y_pred: np.ndarray, 
                         output_path: str = None) -> None:
    """Plot and optionally save confusion matrix."""
    cm = confusion_matrix(y_true, y_pred)
    cm_normalized = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]
    
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    
    # Raw counts
    im1 = axes[0].imshow(cm, interpolation='nearest', cmap=plt.cm.Blues)
    axes[0].set_title('Confusion Matrix (Counts)')
    fig.colorbar(im1, ax=axes[0])
    
    # Add text annotations
    thresh = cm.max() / 2.
    for i in range(len(CLASS_NAMES)):
        for j in range(len(CLASS_NAMES)):
            axes[0].text(j, i, format(cm[i, j], 'd'),
                        ha="center", va="center",
                        color="white" if cm[i, j] > thresh else "black")
    
    # Normalized
    im2 = axes[1].imshow(cm_normalized, interpolation='nearest', cmap=plt.cm.Blues)
    axes[1].set_title('Confusion Matrix (Normalized)')
    fig.colorbar(im2, ax=axes[1])
    
    # Add text annotations
    for i in range(len(CLASS_NAMES)):
        for j in range(len(CLASS_NAMES)):
            axes[1].text(j, i, format(cm_normalized[i, j], '.2f'),
                        ha="center", va="center",
                        color="white" if cm_normalized[i, j] > 0.5 else "black")
    
    for ax in axes:
        ax.set_xlabel('Predicted')
        ax.set_ylabel('True')
        ax.set_xticks(range(len(CLASS_NAMES)))
        ax.set_yticks(range(len(CLASS_NAMES)))
        ax.set_xticklabels(CLASS_NAMES)
        ax.set_yticklabels(CLASS_NAMES)
    
    plt.tight_layout()
    
    if output_path:
        plt.savefig(output_path, dpi=150, bbox_inches='tight')
        print(f"Confusion matrix saved to {output_path}")
    
    plt.show()


def plot_roc_curves(y_true: np.ndarray, y_proba: np.ndarray, 
                    output_path: str = None) -> dict:
    """Plot ROC curves for each class."""
    n_classes = y_proba.shape[1]
    
    # Binarize labels
    y_true_bin = keras.utils.to_categorical(y_true, num_classes=n_classes)
    
    # Compute ROC curve and AUC for each class
    fpr = {}
    tpr = {}
    roc_auc = {}
    
    plt.figure(figsize=(10, 8))
    
    colors = ['#2ecc71', '#f1c40f', '#e74c3c']
    
    for i in range(n_classes):
        fpr[i], tpr[i], _ = roc_curve(y_true_bin[:, i], y_proba[:, i])
        roc_auc[i] = auc(fpr[i], tpr[i])
        
        plt.plot(fpr[i], tpr[i], color=colors[i], lw=2,
                label=f'{CLASS_NAMES[i]} (AUC = {roc_auc[i]:.3f})')
    
    # Compute micro-average ROC curve
    fpr["micro"], tpr["micro"], _ = roc_curve(y_true_bin.ravel(), y_proba.ravel())
    roc_auc["micro"] = auc(fpr["micro"], tpr["micro"])
    
    plt.plot(fpr["micro"], tpr["micro"], color='navy', lw=2, linestyle='--',
            label=f'Micro-average (AUC = {roc_auc["micro"]:.3f})')
    
    plt.plot([0, 1], [0, 1], 'k--', lw=1, alpha=0.5)
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('ROC Curves - Drowsiness Detection')
    plt.legend(loc="lower right")
    plt.grid(True, alpha=0.3)
    
    if output_path:
        plt.savefig(output_path, dpi=150, bbox_inches='tight')
        print(f"ROC curves saved to {output_path}")
    
    plt.show()
    
    return roc_auc


def plot_precision_recall_curves(y_true: np.ndarray, y_proba: np.ndarray,
                                  output_path: str = None) -> dict:
    """Plot Precision-Recall curves for each class."""
    n_classes = y_proba.shape[1]
    
    # Binarize labels
    y_true_bin = keras.utils.to_categorical(y_true, num_classes=n_classes)
    
    plt.figure(figsize=(10, 8))
    
    colors = ['#2ecc71', '#f1c40f', '#e74c3c']
    ap_scores = {}
    
    for i in range(n_classes):
        precision, recall, _ = precision_recall_curve(y_true_bin[:, i], y_proba[:, i])
        ap_scores[i] = average_precision_score(y_true_bin[:, i], y_proba[:, i])
        
        plt.plot(recall, precision, color=colors[i], lw=2,
                label=f'{CLASS_NAMES[i]} (AP = {ap_scores[i]:.3f})')
    
    plt.xlabel('Recall')
    plt.ylabel('Precision')
    plt.title('Precision-Recall Curves - Drowsiness Detection')
    plt.legend(loc="lower left")
    plt.grid(True, alpha=0.3)
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    
    if output_path:
        plt.savefig(output_path, dpi=150, bbox_inches='tight')
        print(f"Precision-Recall curves saved to {output_path}")
    
    plt.show()
    
    return ap_scores


def evaluate_model(model: keras.Model, X_test: np.ndarray, y_test: np.ndarray,
                   output_dir: str = 'evaluation_results') -> dict:
    """
    Comprehensive model evaluation.
    
    Returns:
        Dictionary containing all evaluation metrics
    """
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    print("\n" + "=" * 60)
    print("Model Evaluation Results")
    print("=" * 60)
    
    # Get predictions
    y_proba = model.predict(X_test, verbose=0)
    y_pred = np.argmax(y_proba, axis=1)
    
    # Basic metrics
    test_loss, test_accuracy, _ = model.evaluate(X_test, y_test, verbose=0)
    print(f"\nTest Loss: {test_loss:.4f}")
    print(f"Test Accuracy: {test_accuracy:.4f}")
    
    # Classification report
    print("\n" + "-" * 40)
    print("Classification Report")
    print("-" * 40)
    report = classification_report(y_test, y_pred, target_names=CLASS_NAMES)
    print(report)
    
    # Save report to file
    with open(output_path / 'classification_report.txt', 'w') as f:
        f.write(f"Test Loss: {test_loss:.4f}\n")
        f.write(f"Test Accuracy: {test_accuracy:.4f}\n\n")
        f.write(report)
    
    # Plot confusion matrix
    print("\n" + "-" * 40)
    print("Generating confusion matrix...")
    print("-" * 40)
    plot_confusion_matrix(y_test, y_pred, 
                         output_path=str(output_path / 'confusion_matrix.png'))
    
    # Plot ROC curves
    print("\n" + "-" * 40)
    print("Generating ROC curves...")
    print("-" * 40)
    roc_auc = plot_roc_curves(y_test, y_proba,
                              output_path=str(output_path / 'roc_curves.png'))
    
    # Plot Precision-Recall curves
    print("\n" + "-" * 40)
    print("Generating Precision-Recall curves...")
    print("-" * 40)
    ap_scores = plot_precision_recall_curves(y_test, y_proba,
                                              output_path=str(output_path / 'pr_curves.png'))
    
    # Safety-critical metrics
    print("\n" + "-" * 40)
    print("Safety-Critical Metrics")
    print("-" * 40)
    
    # False Negative Rate for critical classes
    cm = confusion_matrix(y_test, y_pred)
    
    # Microsleep detection rate (most critical)
    microsleep_idx = 2
    microsleep_detected = cm[microsleep_idx, microsleep_idx]
    microsleep_total = cm[microsleep_idx].sum()
    microsleep_recall = microsleep_detected / microsleep_total if microsleep_total > 0 else 0
    microsleep_fnr = 1 - microsleep_recall
    
    # Drowsy detection rate
    drowsy_idx = 1
    drowsy_detected = cm[drowsy_idx, drowsy_idx]
    drowsy_total = cm[drowsy_idx].sum()
    drowsy_recall = drowsy_detected / drowsy_total if drowsy_total > 0 else 0
    drowsy_fnr = 1 - drowsy_recall
    
    # False alarm rate (Alert classified as Drowsy/Microsleep)
    alert_idx = 0
    false_alarms = cm[alert_idx, 1] + cm[alert_idx, 2]
    alert_total = cm[alert_idx].sum()
    false_alarm_rate = false_alarms / alert_total if alert_total > 0 else 0
    
    print(f"Microsleep Detection Rate: {microsleep_recall:.2%}")
    print(f"Microsleep Miss Rate: {microsleep_fnr:.2%}")
    print(f"Drowsy Detection Rate: {drowsy_recall:.2%}")
    print(f"Drowsy Miss Rate: {drowsy_fnr:.2%}")
    print(f"False Alarm Rate: {false_alarm_rate:.2%}")
    
    # Compile results
    results = {
        'test_loss': float(test_loss),
        'test_accuracy': float(test_accuracy),
        'roc_auc': {CLASS_NAMES[i]: float(v) for i, v in roc_auc.items() if isinstance(i, int)},
        'average_precision': {CLASS_NAMES[i]: float(v) for i, v in ap_scores.items()},
        'safety_metrics': {
            'microsleep_detection_rate': float(microsleep_recall),
            'microsleep_miss_rate': float(microsleep_fnr),
            'drowsy_detection_rate': float(drowsy_recall),
            'drowsy_miss_rate': float(drowsy_fnr),
            'false_alarm_rate': float(false_alarm_rate),
        }
    }
    
    # Save results
    import json
    with open(output_path / 'evaluation_metrics.json', 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\nResults saved to {output_path}/")
    
    return results


def main():
    parser = argparse.ArgumentParser(description='Evaluate WakeOn model')
    parser.add_argument('--model', '-m', type=str, required=True,
                       help='Path to trained model (.h5)')
    parser.add_argument('--data', '-d', type=str, default='data/processed',
                       help='Path to test data directory')
    parser.add_argument('--output', '-o', type=str, default='evaluation_results',
                       help='Output directory for results')
    
    args = parser.parse_args()
    
    # Load model
    model = load_model(args.model)
    
    # Check for test data
    data_path = Path(args.data)
    test_features = data_path / 'X_test.npy'
    test_labels = data_path / 'y_test.npy'
    
    if test_features.exists() and test_labels.exists():
        X_test, y_test = load_test_data(args.data)
    else:
        print("Test data not found. Generating synthetic data...")
        # Generate synthetic test data matching model input
        input_shape = model.input_shape[1]
        num_classes = model.output_shape[1]
        
        X_test = np.random.randn(1000, input_shape).astype(np.float32)
        y_test = np.random.randint(0, num_classes, size=1000)
    
    # Evaluate
    results = evaluate_model(model, X_test, y_test, args.output)
    
    print("\n" + "=" * 60)
    print("Evaluation complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
