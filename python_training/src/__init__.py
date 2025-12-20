"""
WakeOn Python Training Pipeline

Package for training drowsiness detection models.
"""

from .feature_extraction import (
    FeatureExtractor,
    FacialFeatures,
    EyeAspectRatioCalculator,
    HeadPoseEstimator,
    BlinkDetector,
    TemporalFeatureExtractor,
)

from .model_architecture import (
    create_drowsiness_classifier,
    create_single_frame_classifier,
    create_cnn_classifier,
    compile_model,
    get_learning_rate_schedule,
    FatigueScoreCalculator,
)

__version__ = '1.0.0'
__all__ = [
    'FeatureExtractor',
    'FacialFeatures',
    'EyeAspectRatioCalculator',
    'HeadPoseEstimator',
    'BlinkDetector',
    'TemporalFeatureExtractor',
    'create_drowsiness_classifier',
    'create_single_frame_classifier',
    'create_cnn_classifier',
    'compile_model',
    'get_learning_rate_schedule',
    'FatigueScoreCalculator',
]
