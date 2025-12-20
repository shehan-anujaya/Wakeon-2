"""
Training Script for WakeOn Drowsiness Detection Model

Main entry point for model training. Handles:
- Data loading and preprocessing
- Model creation and compilation
- Training with callbacks
- Model saving and export

Usage:
    python train_model.py --config config.yaml
"""

import argparse
import os
import sys
from datetime import datetime
from pathlib import Path

import numpy as np
import yaml
import tensorflow as tf
from tensorflow import keras

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.model_architecture import (
    create_drowsiness_classifier,
    create_single_frame_classifier,
    compile_model,
    get_learning_rate_schedule,
)


def load_config(config_path: str) -> dict:
    """Load training configuration from YAML file."""
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)


def load_data(config: dict) -> tuple:
    """
    Load and prepare training data.
    
    Returns:
        Tuple of (train_data, val_data, test_data)
    """
    data_path = Path(config['data']['processed_path'])
    
    # Check if preprocessed data exists
    features_file = data_path / 'features.npy'
    labels_file = data_path / 'labels.npy'
    
    if features_file.exists() and labels_file.exists():
        print(f"Loading data from {data_path}...")
        X = np.load(features_file)
        y = np.load(labels_file)
    else:
        print("No preprocessed data found. Generating synthetic data for testing...")
        # Generate synthetic data for testing the pipeline
        num_samples = 10000
        num_features = config['model']['input_features']
        num_classes = config['model']['num_classes']
        
        X = np.random.randn(num_samples, num_features).astype(np.float32)
        y = np.random.randint(0, num_classes, size=num_samples)
        
        # Make data somewhat realistic
        # Class 0 (alert): high EAR, neutral head pose
        X[y == 0, 0] = np.random.normal(0.30, 0.03, size=(y == 0).sum())
        # Class 1 (drowsy): low EAR, slight head tilt
        X[y == 1, 0] = np.random.normal(0.22, 0.02, size=(y == 1).sum())
        # Class 2 (microsleep): very low EAR, head drop
        X[y == 2, 0] = np.random.normal(0.15, 0.02, size=(y == 2).sum())
        
        # Save for future use
        data_path.mkdir(parents=True, exist_ok=True)
        np.save(features_file, X)
        np.save(labels_file, y)
    
    # Split data
    train_split = config['data']['train_split']
    val_split = config['data']['val_split']
    
    n_samples = len(X)
    n_train = int(n_samples * train_split)
    n_val = int(n_samples * val_split)
    
    # Shuffle
    indices = np.random.permutation(n_samples)
    X, y = X[indices], y[indices]
    
    X_train, y_train = X[:n_train], y[:n_train]
    X_val, y_val = X[n_train:n_train+n_val], y[n_train:n_train+n_val]
    X_test, y_test = X[n_train+n_val:], y[n_train+n_val:]
    
    print(f"Training samples: {len(X_train)}")
    print(f"Validation samples: {len(X_val)}")
    print(f"Test samples: {len(X_test)}")
    
    return (X_train, y_train), (X_val, y_val), (X_test, y_test)


def compute_class_weights(y: np.ndarray, config: dict) -> dict:
    """Compute class weights for imbalanced data."""
    class_weights_config = config['training'].get('class_weights', {})
    
    if class_weights_config:
        weights = {
            0: class_weights_config.get('alert', 1.0),
            1: class_weights_config.get('drowsy', 2.0),
            2: class_weights_config.get('microsleep', 3.0),
        }
    else:
        # Compute from data distribution
        from sklearn.utils.class_weight import compute_class_weight
        classes = np.unique(y)
        weights_array = compute_class_weight('balanced', classes=classes, y=y)
        weights = {i: w for i, w in enumerate(weights_array)}
    
    print(f"Class weights: {weights}")
    return weights


def create_callbacks(config: dict) -> list:
    """Create training callbacks."""
    callbacks = []
    
    # Early stopping
    early_stop_config = config['training'].get('early_stopping', {})
    if early_stop_config:
        callbacks.append(keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=early_stop_config.get('patience', 10),
            min_delta=early_stop_config.get('min_delta', 0.001),
            restore_best_weights=True,
            verbose=1
        ))
    
    # Model checkpoint
    checkpoint_path = Path(config['logging'].get('checkpoint_path', 'checkpoints'))
    checkpoint_path.mkdir(parents=True, exist_ok=True)
    
    callbacks.append(keras.callbacks.ModelCheckpoint(
        filepath=str(checkpoint_path / 'model_{epoch:02d}_{val_loss:.4f}.h5'),
        monitor='val_loss',
        save_best_only=config['logging'].get('save_best_only', True),
        verbose=1
    ))
    
    # TensorBoard
    if config['logging'].get('tensorboard', True):
        log_dir = Path(config['logging'].get('log_dir', 'logs'))
        log_dir = log_dir / datetime.now().strftime("%Y%m%d-%H%M%S")
        callbacks.append(keras.callbacks.TensorBoard(
            log_dir=str(log_dir),
            histogram_freq=1,
            write_graph=True
        ))
    
    # Learning rate reduction
    callbacks.append(keras.callbacks.ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=5,
        min_lr=1e-7,
        verbose=1
    ))
    
    return callbacks


def train_model(config: dict) -> keras.Model:
    """
    Main training function.
    
    Args:
        config: Training configuration dictionary
        
    Returns:
        Trained Keras model
    """
    print("=" * 60)
    print("WakeOn Drowsiness Detection Model Training")
    print("=" * 60)
    
    # Set random seeds for reproducibility
    np.random.seed(42)
    tf.random.set_seed(42)
    
    # Load data
    (X_train, y_train), (X_val, y_val), (X_test, y_test) = load_data(config)
    
    # Compute class weights
    class_weights = compute_class_weights(y_train, config)
    
    # Create model
    model_config = config['model']
    print(f"\nCreating model: {model_config['name']}...")
    
    model = create_single_frame_classifier(
        input_features=model_config['input_features'],
        hidden_units=tuple(model_config['hidden_units']),
        dropout_rate=model_config['dropout'],
        num_classes=model_config['num_classes']
    )
    
    # Compile model
    training_config = config['training']
    model = compile_model(
        model,
        learning_rate=training_config['learning_rate']
    )
    
    print("\nModel summary:")
    model.summary()
    
    # Create callbacks
    callbacks = create_callbacks(config)
    
    # Train
    print("\n" + "=" * 60)
    print("Starting training...")
    print("=" * 60)
    
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=training_config['epochs'],
        batch_size=training_config['batch_size'],
        class_weight=class_weights,
        callbacks=callbacks,
        verbose=1
    )
    
    # Evaluate on test set
    print("\n" + "=" * 60)
    print("Evaluating on test set...")
    print("=" * 60)
    
    test_loss, test_accuracy, _ = model.evaluate(X_test, y_test, verbose=0)
    print(f"Test Loss: {test_loss:.4f}")
    print(f"Test Accuracy: {test_accuracy:.4f}")
    
    # Save final model
    models_dir = Path('models')
    models_dir.mkdir(exist_ok=True)
    
    model_path = models_dir / 'drowsiness_classifier.h5'
    model.save(model_path)
    print(f"\nModel saved to {model_path}")
    
    # Save training history
    history_path = models_dir / 'training_history.npy'
    np.save(history_path, history.history)
    print(f"Training history saved to {history_path}")
    
    return model


def main():
    parser = argparse.ArgumentParser(
        description='Train WakeOn drowsiness detection model'
    )
    parser.add_argument(
        '--config', '-c',
        type=str,
        default='config.yaml',
        help='Path to configuration file'
    )
    parser.add_argument(
        '--gpu', '-g',
        type=int,
        default=None,
        help='GPU device to use (None for CPU)'
    )
    
    args = parser.parse_args()
    
    # Configure GPU
    if args.gpu is not None:
        gpus = tf.config.list_physical_devices('GPU')
        if gpus:
            try:
                tf.config.set_visible_devices(gpus[args.gpu], 'GPU')
                tf.config.experimental.set_memory_growth(gpus[args.gpu], True)
                print(f"Using GPU: {gpus[args.gpu]}")
            except RuntimeError as e:
                print(f"GPU configuration error: {e}")
    
    # Load config
    config = load_config(args.config)
    
    # Train model
    model = train_model(config)
    
    print("\n" + "=" * 60)
    print("Training complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
