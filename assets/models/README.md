# Drowsiness Detection TFLite Models

This directory contains the TensorFlow Lite models for drowsiness detection.

## Expected Models

### 1. drowsiness_classifier.tflite
- **Purpose**: Main drowsiness classification model
- **Input**: Facial features vector (EAR, head pose, blink rate, etc.)
- **Output**: 3-class probabilities [alert, drowsy, microsleep]
- **Size**: ~500KB - 2MB

### 2. face_detector.tflite (Optional)
- **Purpose**: Face detection and landmark extraction
- **Input**: RGB image (typically 224x224 or 128x128)
- **Output**: Face bounding box and 468 landmarks
- **Note**: Can use MediaPipe's built-in model instead

## Model Specifications

| Property | Value |
|----------|-------|
| Input Type | Float32 |
| Input Shape | [1, num_features] |
| Output Shape | [1, 3] |
| Quantization | Dynamic Range / Float16 |
| Target Latency | <100ms |

## Generating Models

1. Train the model using Python training pipeline:
   ```bash
   cd python_training
   python scripts/train_model.py --config config.yaml
   ```

2. Convert to TFLite:
   ```bash
   python src/convert_to_tflite.py \
       --input models/drowsiness_classifier.h5 \
       --output ../assets/models/drowsiness_classifier.tflite \
       --quantize float16
   ```

## Placeholder

Until a real model is trained, the app will use default heuristics for
drowsiness detection based on EAR thresholds.
