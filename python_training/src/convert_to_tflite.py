"""
TensorFlow Lite Conversion Script for WakeOn

Converts trained Keras models to TensorFlow Lite format
with optional quantization for mobile deployment.

Quantization options:
- Full integer (int8): Smallest size, fastest on mobile NPUs
- Float16: Good balance of size and accuracy
- Dynamic range: Easy conversion, moderate size reduction
"""

import argparse
import os
import numpy as np
import tensorflow as tf
from pathlib import Path
from typing import Optional, Generator
import yaml


def load_config(config_path: str) -> dict:
    """Load training configuration."""
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)


def representative_dataset_gen(
    data_path: str,
    num_samples: int = 500
) -> Generator[list, None, None]:
    """
    Generator for representative dataset used in int8 quantization.
    
    Args:
        data_path: Path to preprocessed data
        num_samples: Number of samples to use
        
    Yields:
        List containing single sample as numpy array
    """
    # Load preprocessed features
    try:
        data = np.load(os.path.join(data_path, 'features.npy'))
    except FileNotFoundError:
        # Generate random data for testing
        print("Warning: Using random data for quantization calibration")
        data = np.random.randn(num_samples, 10).astype(np.float32)
    
    # Yield samples
    for i in range(min(num_samples, len(data))):
        sample = data[i:i+1].astype(np.float32)
        yield [sample]


def convert_to_tflite(
    model_path: str,
    output_path: str,
    quantization: str = 'none',
    representative_data_path: Optional[str] = None,
    num_calibration_samples: int = 500,
    optimize_for_size: bool = True
) -> str:
    """
    Convert Keras model to TensorFlow Lite.
    
    Args:
        model_path: Path to saved Keras model (.h5 or SavedModel)
        output_path: Path for output .tflite file
        quantization: Quantization type ('none', 'float16', 'int8', 'dynamic')
        representative_data_path: Path to data for int8 quantization
        num_calibration_samples: Number of samples for quantization calibration
        optimize_for_size: Whether to optimize for smaller model size
        
    Returns:
        Path to converted model
    """
    print(f"Loading model from {model_path}...")
    
    # Load model
    if model_path.endswith('.h5'):
        model = tf.keras.models.load_model(model_path)
    else:
        model = tf.saved_model.load(model_path)
    
    # Create converter
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Apply optimizations
    optimizations = []
    if optimize_for_size:
        optimizations.append(tf.lite.Optimize.DEFAULT)
    
    converter.optimizations = optimizations
    
    # Apply quantization
    if quantization == 'float16':
        print("Applying float16 quantization...")
        converter.target_spec.supported_types = [tf.float16]
        
    elif quantization == 'int8':
        print("Applying int8 quantization...")
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS_INT8
        ]
        converter.inference_input_type = tf.int8
        converter.inference_output_type = tf.int8
        
        # Set representative dataset
        if representative_data_path:
            converter.representative_dataset = lambda: representative_dataset_gen(
                representative_data_path,
                num_calibration_samples
            )
        else:
            # Use random data for calibration
            print("Warning: Using random data for int8 calibration")
            def random_dataset():
                for _ in range(num_calibration_samples):
                    yield [np.random.randn(1, 10).astype(np.float32)]
            converter.representative_dataset = random_dataset
            
    elif quantization == 'dynamic':
        print("Applying dynamic range quantization...")
        # Already covered by DEFAULT optimization
        pass
    
    elif quantization != 'none':
        raise ValueError(f"Unknown quantization type: {quantization}")
    
    # Convert
    print("Converting model...")
    tflite_model = converter.convert()
    
    # Save
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    # Report sizes
    original_size = os.path.getsize(model_path) if os.path.exists(model_path) else 0
    tflite_size = os.path.getsize(output_path)
    
    print(f"\nConversion complete!")
    print(f"Original model size: {original_size / 1024:.2f} KB")
    print(f"TFLite model size: {tflite_size / 1024:.2f} KB")
    if original_size > 0:
        print(f"Compression ratio: {original_size / tflite_size:.2f}x")
    
    return output_path


def verify_tflite_model(
    tflite_path: str,
    test_input: Optional[np.ndarray] = None
) -> dict:
    """
    Verify converted TFLite model works correctly.
    
    Args:
        tflite_path: Path to .tflite model
        test_input: Optional test input array
        
    Returns:
        Dictionary with model info and test results
    """
    print(f"\nVerifying {tflite_path}...")
    
    # Load interpreter
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    
    # Get model info
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    info = {
        'input_shape': input_details[0]['shape'].tolist(),
        'input_dtype': str(input_details[0]['dtype']),
        'output_shape': output_details[0]['shape'].tolist(),
        'output_dtype': str(output_details[0]['dtype']),
    }
    
    print(f"Input shape: {info['input_shape']}")
    print(f"Input dtype: {info['input_dtype']}")
    print(f"Output shape: {info['output_shape']}")
    print(f"Output dtype: {info['output_dtype']}")
    
    # Test inference
    if test_input is None:
        test_input = np.random.randn(*input_details[0]['shape']).astype(np.float32)
    
    # Handle quantized input
    if input_details[0]['dtype'] == np.int8:
        input_scale, input_zero_point = input_details[0]['quantization']
        test_input = (test_input / input_scale + input_zero_point).astype(np.int8)
    
    interpreter.set_tensor(input_details[0]['index'], test_input)
    
    import time
    start_time = time.time()
    interpreter.invoke()
    inference_time = (time.time() - start_time) * 1000
    
    output = interpreter.get_tensor(output_details[0]['index'])
    
    # Dequantize output if needed
    if output_details[0]['dtype'] == np.int8:
        output_scale, output_zero_point = output_details[0]['quantization']
        output = (output.astype(np.float32) - output_zero_point) * output_scale
    
    info['inference_time_ms'] = inference_time
    info['output_sample'] = output.tolist()
    
    print(f"Inference time: {inference_time:.2f} ms")
    print(f"Output: {output}")
    
    return info


def batch_convert(config_path: str):
    """
    Convert all models specified in config.
    """
    config = load_config(config_path)
    
    tflite_config = config.get('tflite', {})
    quantization = tflite_config.get('quantization', 'none')
    output_path = tflite_config.get('output_path', 'models/model.tflite')
    optimize = tflite_config.get('optimize_for_size', True)
    num_samples = tflite_config.get('representative_data_samples', 500)
    
    # Find Keras models
    models_dir = Path('models')
    keras_models = list(models_dir.glob('*.h5'))
    
    if not keras_models:
        print("No Keras models found in models/ directory")
        return
    
    for model_path in keras_models:
        output_name = model_path.stem + '.tflite'
        output = models_dir / output_name
        
        convert_to_tflite(
            str(model_path),
            str(output),
            quantization=quantization,
            num_calibration_samples=num_samples,
            optimize_for_size=optimize
        )
        
        verify_tflite_model(str(output))


def main():
    parser = argparse.ArgumentParser(
        description='Convert Keras model to TensorFlow Lite'
    )
    parser.add_argument(
        '--model', '-m',
        type=str,
        help='Path to Keras model (.h5 or SavedModel directory)'
    )
    parser.add_argument(
        '--output', '-o',
        type=str,
        default='model.tflite',
        help='Output path for TFLite model'
    )
    parser.add_argument(
        '--quantize', '-q',
        type=str,
        choices=['none', 'float16', 'int8', 'dynamic'],
        default='none',
        help='Quantization type'
    )
    parser.add_argument(
        '--data', '-d',
        type=str,
        help='Path to representative data for int8 quantization'
    )
    parser.add_argument(
        '--samples', '-s',
        type=int,
        default=500,
        help='Number of calibration samples for int8 quantization'
    )
    parser.add_argument(
        '--config', '-c',
        type=str,
        help='Path to config file for batch conversion'
    )
    parser.add_argument(
        '--verify', '-v',
        action='store_true',
        help='Verify converted model'
    )
    
    args = parser.parse_args()
    
    if args.config:
        batch_convert(args.config)
    elif args.model:
        tflite_path = convert_to_tflite(
            args.model,
            args.output,
            quantization=args.quantize,
            representative_data_path=args.data,
            num_calibration_samples=args.samples
        )
        
        if args.verify:
            verify_tflite_model(tflite_path)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
