"""
Data Preprocessing Module for WakeOn

Handles:
- Video/image data loading
- Feature extraction from frames
- Dataset creation and augmentation
- Train/val/test splitting
- Data saving/loading utilities
"""

import os
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor, as_completed

import cv2
import numpy as np
from tqdm import tqdm

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.feature_extraction import FeatureExtractor


@dataclass
class DataSample:
    """Single data sample with features and label."""
    features: np.ndarray
    label: int
    source_file: str
    frame_number: int


class VideoDataLoader:
    """Load and process video files for drowsiness detection."""
    
    def __init__(self, feature_extractor: FeatureExtractor):
        self.feature_extractor = feature_extractor
    
    def process_video(self, video_path: str, label: int,
                      sample_rate: int = 3) -> List[DataSample]:
        """
        Process a video file and extract features from frames.
        
        Args:
            video_path: Path to video file
            label: Class label (0=alert, 1=drowsy, 2=microsleep)
            sample_rate: Process every Nth frame
            
        Returns:
            List of DataSample objects
        """
        samples = []
        cap = cv2.VideoCapture(video_path)
        
        if not cap.isOpened():
            print(f"Warning: Could not open video {video_path}")
            return samples
        
        frame_count = 0
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            if frame_count % sample_rate == 0:
                # Convert BGR to RGB
                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                
                # Extract features
                result = self.feature_extractor.extract(rgb_frame)
                
                if result is not None:
                    samples.append(DataSample(
                        features=np.array(result.to_feature_vector()),
                        label=label,
                        source_file=video_path,
                        frame_number=frame_count
                    ))
            
            frame_count += 1
        
        cap.release()
        return samples
    
    def process_image(self, image_path: str, label: int) -> Optional[DataSample]:
        """Process a single image file."""
        image = cv2.imread(image_path)
        
        if image is None:
            print(f"Warning: Could not load image {image_path}")
            return None
        
        # Convert BGR to RGB
        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # Extract features
        result = self.feature_extractor.extract(rgb_image)
        
        if result is not None:
            return DataSample(
                features=np.array(result.to_feature_vector()),
                label=label,
                source_file=image_path,
                frame_number=0
            )
        
        return None


class DatasetBuilder:
    """Build and manage training datasets."""
    
    # Label mapping
    LABEL_MAP = {
        'alert': 0,
        'awake': 0,
        'normal': 0,
        'drowsy': 1,
        'fatigued': 1,
        'tired': 1,
        'microsleep': 2,
        'asleep': 2,
        'sleeping': 2,
        'closed': 2,
    }
    
    def __init__(self, data_dir: str, output_dir: str):
        self.data_dir = Path(data_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        self.feature_extractor = FeatureExtractor()
        self.video_loader = VideoDataLoader(self.feature_extractor)
        
        self.samples: List[DataSample] = []
    
    def load_from_directory_structure(self, video_extensions: List[str] = None,
                                       image_extensions: List[str] = None) -> None:
        """
        Load data from directory structure where folders are class names.
        
        Expected structure:
            data_dir/
                alert/
                    video1.mp4
                    img1.jpg
                drowsy/
                    video2.mp4
                    img2.jpg
                microsleep/
                    video3.mp4
                    img3.jpg
        """
        if video_extensions is None:
            video_extensions = ['.mp4', '.avi', '.mov', '.mkv']
        if image_extensions is None:
            image_extensions = ['.jpg', '.jpeg', '.png', '.bmp']
        
        print(f"Loading data from {self.data_dir}...")
        
        for class_dir in self.data_dir.iterdir():
            if not class_dir.is_dir():
                continue
            
            class_name = class_dir.name.lower()
            if class_name not in self.LABEL_MAP:
                print(f"Warning: Unknown class '{class_name}', skipping")
                continue
            
            label = self.LABEL_MAP[class_name]
            print(f"\nProcessing class: {class_name} (label={label})")
            
            files = list(class_dir.iterdir())
            
            for file_path in tqdm(files, desc=f"Processing {class_name}"):
                suffix = file_path.suffix.lower()
                
                if suffix in video_extensions:
                    samples = self.video_loader.process_video(
                        str(file_path), label
                    )
                    self.samples.extend(samples)
                
                elif suffix in image_extensions:
                    sample = self.video_loader.process_image(
                        str(file_path), label
                    )
                    if sample:
                        self.samples.append(sample)
        
        print(f"\nTotal samples loaded: {len(self.samples)}")
    
    def load_from_csv(self, csv_path: str, base_dir: str = None) -> None:
        """
        Load data from CSV file with paths and labels.
        
        CSV format:
            path,label
            path/to/image.jpg,alert
            path/to/video.mp4,drowsy
        """
        import csv
        
        base_dir = Path(base_dir) if base_dir else self.data_dir
        
        with open(csv_path, 'r') as f:
            reader = csv.DictReader(f)
            
            for row in tqdm(list(reader), desc="Processing files"):
                file_path = base_dir / row['path']
                label_name = row['label'].lower()
                
                if label_name not in self.LABEL_MAP:
                    continue
                
                label = self.LABEL_MAP[label_name]
                
                if file_path.suffix.lower() in ['.mp4', '.avi', '.mov']:
                    samples = self.video_loader.process_video(str(file_path), label)
                    self.samples.extend(samples)
                else:
                    sample = self.video_loader.process_image(str(file_path), label)
                    if sample:
                        self.samples.append(sample)
    
    def augment_data(self, augmentation_factor: int = 2) -> None:
        """
        Augment dataset with noise and variations.
        
        Simple augmentations for tabular/feature data:
        - Add Gaussian noise
        - Scale features slightly
        """
        print(f"\nAugmenting data (factor={augmentation_factor})...")
        
        original_samples = self.samples.copy()
        
        for sample in tqdm(original_samples):
            for _ in range(augmentation_factor - 1):
                # Add Gaussian noise
                noise = np.random.normal(0, 0.02, size=sample.features.shape)
                augmented_features = sample.features + noise
                
                # Random scaling
                scale = np.random.uniform(0.98, 1.02)
                augmented_features *= scale
                
                self.samples.append(DataSample(
                    features=augmented_features.astype(np.float32),
                    label=sample.label,
                    source_file=sample.source_file + "_aug",
                    frame_number=sample.frame_number
                ))
        
        print(f"Samples after augmentation: {len(self.samples)}")
    
    def balance_classes(self, strategy: str = 'oversample') -> None:
        """Balance class distribution."""
        print("\nBalancing classes...")
        
        # Group by label
        by_label: Dict[int, List[DataSample]] = {}
        for sample in self.samples:
            if sample.label not in by_label:
                by_label[sample.label] = []
            by_label[sample.label].append(sample)
        
        class_counts = {k: len(v) for k, v in by_label.items()}
        print(f"Class distribution: {class_counts}")
        
        if strategy == 'oversample':
            max_count = max(class_counts.values())
            
            balanced_samples = []
            for label, samples in by_label.items():
                # Add all original samples
                balanced_samples.extend(samples)
                
                # Oversample if needed
                while len([s for s in balanced_samples if s.label == label]) < max_count:
                    sample = samples[np.random.randint(len(samples))]
                    balanced_samples.append(sample)
            
            self.samples = balanced_samples
        
        elif strategy == 'undersample':
            min_count = min(class_counts.values())
            
            balanced_samples = []
            for label, samples in by_label.items():
                indices = np.random.choice(len(samples), min_count, replace=False)
                balanced_samples.extend([samples[i] for i in indices])
            
            self.samples = balanced_samples
        
        # Recount
        class_counts = {}
        for s in self.samples:
            class_counts[s.label] = class_counts.get(s.label, 0) + 1
        print(f"Balanced distribution: {class_counts}")
    
    def split_and_save(self, train_ratio: float = 0.7, 
                       val_ratio: float = 0.15) -> Tuple[np.ndarray, ...]:
        """
        Split data and save to disk.
        
        Returns:
            Tuple of (X_train, y_train, X_val, y_val, X_test, y_test)
        """
        print("\nSplitting and saving data...")
        
        # Shuffle
        np.random.shuffle(self.samples)
        
        # Extract features and labels
        X = np.array([s.features for s in self.samples], dtype=np.float32)
        y = np.array([s.label for s in self.samples], dtype=np.int32)
        
        # Split
        n = len(X)
        n_train = int(n * train_ratio)
        n_val = int(n * val_ratio)
        
        X_train, y_train = X[:n_train], y[:n_train]
        X_val, y_val = X[n_train:n_train+n_val], y[n_train:n_train+n_val]
        X_test, y_test = X[n_train+n_val:], y[n_train+n_val:]
        
        print(f"Train: {len(X_train)}, Val: {len(X_val)}, Test: {len(X_test)}")
        
        # Save
        np.save(self.output_dir / 'X_train.npy', X_train)
        np.save(self.output_dir / 'y_train.npy', y_train)
        np.save(self.output_dir / 'X_val.npy', X_val)
        np.save(self.output_dir / 'y_val.npy', y_val)
        np.save(self.output_dir / 'X_test.npy', X_test)
        np.save(self.output_dir / 'y_test.npy', y_test)
        
        # Also save combined for convenience
        np.save(self.output_dir / 'features.npy', X)
        np.save(self.output_dir / 'labels.npy', y)
        
        print(f"Data saved to {self.output_dir}/")
        
        return X_train, y_train, X_val, y_val, X_test, y_test
    
    def get_stats(self) -> Dict:
        """Get dataset statistics."""
        if not self.samples:
            return {}
        
        X = np.array([s.features for s in self.samples])
        y = np.array([s.label for s in self.samples])
        
        class_counts = {}
        for label in np.unique(y):
            class_name = [k for k, v in self.LABEL_MAP.items() if v == label][0]
            class_counts[class_name] = int((y == label).sum())
        
        return {
            'total_samples': len(self.samples),
            'feature_dim': X.shape[1] if len(X.shape) > 1 else 1,
            'class_distribution': class_counts,
            'feature_stats': {
                'mean': X.mean(axis=0).tolist(),
                'std': X.std(axis=0).tolist(),
                'min': X.min(axis=0).tolist(),
                'max': X.max(axis=0).tolist(),
            }
        }


def main():
    """Main preprocessing pipeline."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Preprocess training data')
    parser.add_argument('--input', '-i', type=str, required=True,
                       help='Input data directory')
    parser.add_argument('--output', '-o', type=str, default='data/processed',
                       help='Output directory')
    parser.add_argument('--augment', '-a', type=int, default=1,
                       help='Augmentation factor (1=no augmentation)')
    parser.add_argument('--balance', '-b', action='store_true',
                       help='Balance class distribution')
    
    args = parser.parse_args()
    
    # Build dataset
    builder = DatasetBuilder(args.input, args.output)
    builder.load_from_directory_structure()
    
    if args.augment > 1:
        builder.augment_data(args.augment)
    
    if args.balance:
        builder.balance_classes()
    
    # Print stats
    stats = builder.get_stats()
    print("\nDataset Statistics:")
    print(f"  Total samples: {stats['total_samples']}")
    print(f"  Feature dimension: {stats['feature_dim']}")
    print(f"  Class distribution: {stats['class_distribution']}")
    
    # Split and save
    builder.split_and_save()
    
    print("\nPreprocessing complete!")


if __name__ == "__main__":
    main()
