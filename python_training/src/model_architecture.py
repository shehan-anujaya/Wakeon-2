"""
Model Architecture for WakeOn Drowsiness Detection

Defines the neural network architectures for:
1. Drowsiness classifier (feature-based)
2. End-to-end CNN (optional, for direct frame input)

Optimized for mobile deployment via TensorFlow Lite.
"""

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, Model
from typing import Tuple, Optional


def create_drowsiness_classifier(
    input_features: int = 10,
    hidden_units: Tuple[int, ...] = (64, 32),
    lstm_units: int = 32,
    dropout_rate: float = 0.3,
    num_classes: int = 3,
    sequence_length: int = 30
) -> Model:
    """
    Create feature-based drowsiness classifier.
    
    Architecture:
    - Input: Sequence of extracted features
    - LSTM for temporal pattern recognition
    - Dense layers for classification
    - Softmax output for 3 classes
    
    Args:
        input_features: Number of input features per timestep
        hidden_units: Tuple of hidden layer sizes
        lstm_units: Number of LSTM units
        dropout_rate: Dropout rate for regularization
        num_classes: Number of output classes (alert, drowsy, microsleep)
        sequence_length: Length of input sequence
        
    Returns:
        Compiled Keras model
    """
    # Input layer
    inputs = keras.Input(shape=(sequence_length, input_features), name='feature_sequence')
    
    # LSTM for temporal features
    x = layers.LSTM(lstm_units, return_sequences=True, name='lstm_1')(inputs)
    x = layers.Dropout(dropout_rate)(x)
    x = layers.LSTM(lstm_units // 2, name='lstm_2')(x)
    x = layers.Dropout(dropout_rate)(x)
    
    # Dense layers
    for i, units in enumerate(hidden_units):
        x = layers.Dense(units, activation='relu', name=f'dense_{i}')(x)
        x = layers.BatchNormalization()(x)
        x = layers.Dropout(dropout_rate)(x)
    
    # Output layer
    outputs = layers.Dense(num_classes, activation='softmax', name='output')(x)
    
    model = Model(inputs, outputs, name='DrowsinessClassifier')
    
    return model


def create_single_frame_classifier(
    input_features: int = 10,
    hidden_units: Tuple[int, ...] = (32, 16),
    dropout_rate: float = 0.3,
    num_classes: int = 3
) -> Model:
    """
    Create single-frame classifier for real-time inference.
    
    This model takes individual frame features (no sequence)
    and is optimized for low-latency mobile deployment.
    
    Args:
        input_features: Number of input features
        hidden_units: Tuple of hidden layer sizes
        dropout_rate: Dropout rate
        num_classes: Number of output classes
        
    Returns:
        Compiled Keras model
    """
    inputs = keras.Input(shape=(input_features,), name='features')
    
    x = inputs
    
    for i, units in enumerate(hidden_units):
        x = layers.Dense(units, activation='relu', name=f'dense_{i}')(x)
        x = layers.BatchNormalization()(x)
        x = layers.Dropout(dropout_rate)(x)
    
    outputs = layers.Dense(num_classes, activation='softmax', name='output')(x)
    
    model = Model(inputs, outputs, name='SingleFrameClassifier')
    
    return model


def create_cnn_classifier(
    input_shape: Tuple[int, int, int] = (224, 224, 3),
    num_classes: int = 3,
    base_filters: int = 16
) -> Model:
    """
    Create lightweight CNN for end-to-end drowsiness detection.
    
    Optimized for mobile with:
    - Depthwise separable convolutions
    - Small number of filters
    - Global average pooling
    
    Args:
        input_shape: Input image shape (H, W, C)
        num_classes: Number of output classes
        base_filters: Base number of filters (scaled in each layer)
        
    Returns:
        Compiled Keras model
    """
    inputs = keras.Input(shape=input_shape, name='image')
    
    # Initial convolution
    x = layers.Conv2D(base_filters, 3, strides=2, padding='same', name='conv_initial')(inputs)
    x = layers.BatchNormalization()(x)
    x = layers.ReLU()(x)
    
    # Depthwise separable blocks
    filter_sizes = [base_filters * 2, base_filters * 4, base_filters * 8]
    
    for i, filters in enumerate(filter_sizes):
        x = _depthwise_separable_block(x, filters, stride=2, name=f'block_{i}')
    
    # Global pooling
    x = layers.GlobalAveragePooling2D(name='global_pool')(x)
    
    # Classification head
    x = layers.Dense(64, activation='relu', name='fc')(x)
    x = layers.Dropout(0.3)(x)
    outputs = layers.Dense(num_classes, activation='softmax', name='output')(x)
    
    model = Model(inputs, outputs, name='MobileDrowsinessNet')
    
    return model


def _depthwise_separable_block(
    x: tf.Tensor,
    filters: int,
    stride: int = 1,
    name: str = ''
) -> tf.Tensor:
    """
    Depthwise separable convolution block.
    
    Efficient alternative to regular convolution.
    """
    # Depthwise
    x = layers.DepthwiseConv2D(
        3, strides=stride, padding='same', 
        name=f'{name}_depthwise'
    )(x)
    x = layers.BatchNormalization()(x)
    x = layers.ReLU()(x)
    
    # Pointwise
    x = layers.Conv2D(filters, 1, padding='same', name=f'{name}_pointwise')(x)
    x = layers.BatchNormalization()(x)
    x = layers.ReLU()(x)
    
    return x


def compile_model(
    model: Model,
    learning_rate: float = 0.001,
    class_weights: Optional[dict] = None
) -> Model:
    """
    Compile model with appropriate optimizer and loss.
    
    Args:
        model: Keras model to compile
        learning_rate: Initial learning rate
        class_weights: Optional class weights for imbalanced data
        
    Returns:
        Compiled model
    """
    optimizer = keras.optimizers.Adam(learning_rate=learning_rate)
    
    model.compile(
        optimizer=optimizer,
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy', keras.metrics.SparseCategoricalCrossentropy(name='ce')]
    )
    
    return model


def get_learning_rate_schedule(
    initial_lr: float = 0.001,
    decay_steps: int = 1000,
    schedule_type: str = 'cosine_decay'
) -> keras.optimizers.schedules.LearningRateSchedule:
    """
    Create learning rate schedule.
    
    Args:
        initial_lr: Initial learning rate
        decay_steps: Number of steps for decay
        schedule_type: Type of schedule ('cosine_decay', 'exponential', 'step')
        
    Returns:
        Learning rate schedule
    """
    if schedule_type == 'cosine_decay':
        return keras.optimizers.schedules.CosineDecay(
            initial_lr,
            decay_steps=decay_steps
        )
    elif schedule_type == 'exponential':
        return keras.optimizers.schedules.ExponentialDecay(
            initial_lr,
            decay_steps=decay_steps,
            decay_rate=0.96
        )
    elif schedule_type == 'step':
        boundaries = [decay_steps // 3, 2 * decay_steps // 3]
        values = [initial_lr, initial_lr * 0.1, initial_lr * 0.01]
        return keras.optimizers.schedules.PiecewiseConstantDecay(
            boundaries, values
        )
    else:
        raise ValueError(f"Unknown schedule type: {schedule_type}")


class FatigueScoreCalculator:
    """
    Calculate composite fatigue score from model outputs and features.
    
    Combines:
    - Model prediction probabilities
    - EAR-based score
    - PERCLOS score
    - Head pose score
    """
    
    def __init__(
        self,
        ear_weight: float = 0.35,
        model_weight: float = 0.30,
        perclos_weight: float = 0.20,
        head_pose_weight: float = 0.15
    ):
        self.ear_weight = ear_weight
        self.model_weight = model_weight
        self.perclos_weight = perclos_weight
        self.head_pose_weight = head_pose_weight
    
    def calculate(
        self,
        model_output: Tuple[float, float, float],
        ear: float,
        perclos: float,
        head_pose_score: float
    ) -> float:
        """
        Calculate composite fatigue score.
        
        Args:
            model_output: (alert_prob, drowsy_prob, microsleep_prob)
            ear: Current EAR value
            perclos: PERCLOS value (0-1)
            head_pose_score: Normalized head deviation score (0-1)
            
        Returns:
            Fatigue score (0-1)
        """
        # EAR score (lower EAR = higher fatigue)
        ear_score = self._normalize_ear(ear)
        
        # Model score (weighted combination of drowsy and microsleep)
        model_score = model_output[1] + 1.5 * model_output[2]
        model_score = min(1.0, model_score)
        
        # Composite score
        fatigue_score = (
            self.ear_weight * ear_score +
            self.model_weight * model_score +
            self.perclos_weight * perclos +
            self.head_pose_weight * head_pose_score
        )
        
        return min(1.0, max(0.0, fatigue_score))
    
    def _normalize_ear(self, ear: float) -> float:
        """Normalize EAR to fatigue score (lower EAR = higher score)."""
        normal_ear = 0.30
        closed_ear = 0.15
        
        if ear >= normal_ear:
            return 0.0
        if ear <= closed_ear:
            return 1.0
        
        return 1.0 - (ear - closed_ear) / (normal_ear - closed_ear)


if __name__ == "__main__":
    # Test model creation
    print("Creating models...")
    
    # Sequence model
    seq_model = create_drowsiness_classifier()
    seq_model = compile_model(seq_model)
    print("\nSequence model:")
    seq_model.summary()
    
    # Single frame model
    frame_model = create_single_frame_classifier()
    frame_model = compile_model(frame_model)
    print("\nSingle frame model:")
    frame_model.summary()
    
    # CNN model
    cnn_model = create_cnn_classifier()
    cnn_model = compile_model(cnn_model)
    print("\nCNN model:")
    cnn_model.summary()
    
    print("\nAll models created successfully!")
