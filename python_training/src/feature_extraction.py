"""
Feature Extraction Module for WakeOn Drowsiness Detection

This module handles extraction of facial features from video frames:
- Eye Aspect Ratio (EAR) calculation
- Head pose estimation (yaw, pitch, roll)
- Blink detection and analysis
- Temporal feature computation

Based on: "Real-Time Eye Blink Detection using Facial Landmarks"
"""

import numpy as np
import cv2
import mediapipe as mp
from dataclasses import dataclass
from typing import List, Tuple, Optional
from collections import deque


@dataclass
class FacialFeatures:
    """Container for extracted facial features from a single frame."""
    left_ear: float
    right_ear: float
    average_ear: float
    yaw: float
    pitch: float
    roll: float
    face_detected: bool
    confidence: float
    timestamp: float
    
    def to_array(self) -> np.ndarray:
        """Convert to numpy array for model input."""
        return np.array([
            self.average_ear,
            self.yaw / 90.0,  # Normalize to [-1, 1]
            self.pitch / 90.0,
            self.roll / 90.0,
            1.0 if self.average_ear < 0.21 else 0.0,  # Eyes closed indicator
        ])


class EyeAspectRatioCalculator:
    """
    Calculate Eye Aspect Ratio (EAR) from facial landmarks.
    
    EAR = (||p2-p6|| + ||p3-p5||) / (2 * ||p1-p4||)
    
    Where p1-p6 are the 6 key eye landmark points.
    """
    
    # MediaPipe Face Mesh eye landmark indices
    LEFT_EYE_INDICES = [362, 385, 387, 263, 373, 380]
    RIGHT_EYE_INDICES = [33, 160, 158, 133, 153, 144]
    
    @staticmethod
    def euclidean_distance(p1: Tuple[float, float], p2: Tuple[float, float]) -> float:
        """Calculate Euclidean distance between two 2D points."""
        return np.sqrt((p2[0] - p1[0])**2 + (p2[1] - p1[1])**2)
    
    @classmethod
    def calculate_ear(cls, eye_landmarks: List[Tuple[float, float]]) -> float:
        """
        Calculate Eye Aspect Ratio for a single eye.
        
        Args:
            eye_landmarks: List of 6 (x, y) tuples for eye landmarks
            
        Returns:
            EAR value (typically 0.2-0.4 for open eyes)
        """
        if len(eye_landmarks) != 6:
            raise ValueError(f"Expected 6 landmarks, got {len(eye_landmarks)}")
        
        # Vertical distances (p2-p6 and p3-p5)
        v1 = cls.euclidean_distance(eye_landmarks[1], eye_landmarks[5])
        v2 = cls.euclidean_distance(eye_landmarks[2], eye_landmarks[4])
        
        # Horizontal distance (p1-p4)
        h = cls.euclidean_distance(eye_landmarks[0], eye_landmarks[3])
        
        # Avoid division by zero
        if h < 1e-6:
            return 0.0
        
        # EAR formula
        ear = (v1 + v2) / (2.0 * h)
        return ear
    
    @classmethod
    def extract_eye_landmarks(
        cls, 
        face_landmarks: List[Tuple[float, float, float]],
        eye_indices: List[int]
    ) -> List[Tuple[float, float]]:
        """Extract specific eye landmarks from full face mesh."""
        return [(face_landmarks[i][0], face_landmarks[i][1]) for i in eye_indices]


class HeadPoseEstimator:
    """
    Estimate head pose (yaw, pitch, roll) from facial landmarks.
    
    Uses the solvePnP approach with known 3D facial model points.
    """
    
    # 3D model points (generic face model)
    MODEL_POINTS = np.array([
        (0.0, 0.0, 0.0),             # Nose tip
        (0.0, -330.0, -65.0),        # Chin
        (-225.0, 170.0, -135.0),     # Left eye corner
        (225.0, 170.0, -135.0),      # Right eye corner
        (-150.0, -150.0, -125.0),    # Left mouth corner
        (150.0, -150.0, -125.0)      # Right mouth corner
    ], dtype=np.float64)
    
    # MediaPipe landmark indices for head pose
    POSE_LANDMARK_INDICES = [1, 152, 33, 263, 61, 291]
    
    def __init__(self, frame_width: int, frame_height: int):
        """Initialize with camera parameters."""
        # Camera matrix (assuming no lens distortion)
        focal_length = frame_width
        center = (frame_width / 2, frame_height / 2)
        
        self.camera_matrix = np.array([
            [focal_length, 0, center[0]],
            [0, focal_length, center[1]],
            [0, 0, 1]
        ], dtype=np.float64)
        
        self.dist_coeffs = np.zeros((4, 1), dtype=np.float64)
    
    def estimate(
        self, 
        face_landmarks: List[Tuple[float, float, float]],
        frame_width: int,
        frame_height: int
    ) -> Tuple[float, float, float]:
        """
        Estimate head pose angles.
        
        Returns:
            (yaw, pitch, roll) in degrees
        """
        # Extract 2D image points
        image_points = np.array([
            (face_landmarks[i][0] * frame_width, 
             face_landmarks[i][1] * frame_height)
            for i in self.POSE_LANDMARK_INDICES
        ], dtype=np.float64)
        
        # Solve PnP
        success, rotation_vec, translation_vec = cv2.solvePnP(
            self.MODEL_POINTS,
            image_points,
            self.camera_matrix,
            self.dist_coeffs,
            flags=cv2.SOLVEPNP_ITERATIVE
        )
        
        if not success:
            return (0.0, 0.0, 0.0)
        
        # Convert rotation vector to rotation matrix
        rotation_mat, _ = cv2.Rodrigues(rotation_vec)
        
        # Get Euler angles
        proj_matrix = np.hstack((rotation_mat, translation_vec))
        _, _, _, _, _, _, euler_angles = cv2.decomposeProjectionMatrix(proj_matrix)
        
        yaw = euler_angles[1][0]
        pitch = euler_angles[0][0]
        roll = euler_angles[2][0]
        
        return (yaw, pitch, roll)


class BlinkDetector:
    """
    Detect blinks from EAR time series.
    
    A blink is characterized by:
    1. EAR drops below threshold
    2. EAR stays low for 1-10 frames (100-400ms at 30fps)
    3. EAR returns above threshold
    """
    
    def __init__(
        self,
        threshold: float = 0.21,
        min_frames: int = 2,
        max_frames: int = 12
    ):
        self.threshold = threshold
        self.min_frames = min_frames
        self.max_frames = max_frames
        
        self._below_threshold = False
        self._frame_count = 0
        self._blink_start_time = 0
        
    def update(self, ear: float, timestamp: float) -> Optional[dict]:
        """
        Update blink detector with new EAR value.
        
        Returns:
            Blink event dict if blink completed, None otherwise
        """
        if ear < self.threshold:
            if not self._below_threshold:
                # Blink start
                self._below_threshold = True
                self._frame_count = 1
                self._blink_start_time = timestamp
            else:
                self._frame_count += 1
        else:
            if self._below_threshold:
                # Blink end - check if valid
                self._below_threshold = False
                
                if self.min_frames <= self._frame_count <= self.max_frames:
                    blink_event = {
                        'start_time': self._blink_start_time,
                        'end_time': timestamp,
                        'duration_frames': self._frame_count,
                        'is_complete': True
                    }
                    self._frame_count = 0
                    return blink_event
                
                self._frame_count = 0
        
        return None


class TemporalFeatureExtractor:
    """
    Extract temporal features from sequences of frame features.
    
    Features include:
    - EAR derivatives (rate of change)
    - Moving averages
    - PERCLOS (percentage of time eyes closed)
    - Blink rate
    """
    
    def __init__(self, window_size: int = 30, fps: int = 30):
        self.window_size = window_size
        self.fps = fps
        self.ear_history = deque(maxlen=window_size)
        self.blink_times = deque(maxlen=100)  # Last 100 blinks
        
    def update(self, features: FacialFeatures) -> dict:
        """
        Update with new frame and compute temporal features.
        
        Returns:
            Dictionary of temporal features
        """
        self.ear_history.append(features.average_ear)
        
        if len(self.ear_history) < 3:
            return self._default_features()
        
        ear_array = np.array(self.ear_history)
        
        # Compute features
        return {
            'ear_mean': np.mean(ear_array),
            'ear_std': np.std(ear_array),
            'ear_derivative': self._compute_derivative(ear_array),
            'perclos': self._compute_perclos(ear_array),
            'blink_rate': self._compute_blink_rate(),
        }
    
    def _compute_derivative(self, arr: np.ndarray) -> float:
        """Compute first derivative (rate of change)."""
        if len(arr) < 2:
            return 0.0
        return float(np.gradient(arr)[-1])
    
    def _compute_perclos(self, ear_array: np.ndarray, threshold: float = 0.21) -> float:
        """
        Compute PERCLOS - percentage of time eyes are closed.
        
        Standard measure: percentage of time eyes are >80% closed
        over a 1-minute window.
        """
        closed_count = np.sum(ear_array < threshold)
        return closed_count / len(ear_array)
    
    def _compute_blink_rate(self) -> float:
        """Compute blinks per minute."""
        if not self.blink_times:
            return 17.0  # Return normal blink rate as default
        
        current_time = self.blink_times[-1]
        one_minute_ago = current_time - 60.0
        
        recent_blinks = [t for t in self.blink_times if t > one_minute_ago]
        return float(len(recent_blinks))
    
    def add_blink(self, timestamp: float):
        """Record a blink event."""
        self.blink_times.append(timestamp)
    
    def _default_features(self) -> dict:
        """Return default features when not enough history."""
        return {
            'ear_mean': 0.30,
            'ear_std': 0.0,
            'ear_derivative': 0.0,
            'perclos': 0.0,
            'blink_rate': 17.0,
        }


class FeatureExtractor:
    """
    Main feature extraction pipeline.
    
    Combines all feature extractors into a single interface.
    """
    
    def __init__(self, frame_width: int = 640, frame_height: int = 480):
        self.frame_width = frame_width
        self.frame_height = frame_height
        
        # Initialize MediaPipe Face Mesh
        self.mp_face_mesh = mp.solutions.face_mesh
        self.face_mesh = self.mp_face_mesh.FaceMesh(
            max_num_faces=1,
            refine_landmarks=True,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.5
        )
        
        # Initialize sub-extractors
        self.ear_calculator = EyeAspectRatioCalculator()
        self.head_pose_estimator = HeadPoseEstimator(frame_width, frame_height)
        self.blink_detector = BlinkDetector()
        self.temporal_extractor = TemporalFeatureExtractor()
        
    def extract(self, frame: np.ndarray, timestamp: float) -> FacialFeatures:
        """
        Extract all features from a video frame.
        
        Args:
            frame: BGR image as numpy array
            timestamp: Frame timestamp in seconds
            
        Returns:
            FacialFeatures dataclass with all extracted features
        """
        # Convert to RGB for MediaPipe
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Process with MediaPipe
        results = self.face_mesh.process(rgb_frame)
        
        if not results.multi_face_landmarks:
            return FacialFeatures(
                left_ear=0.0,
                right_ear=0.0,
                average_ear=0.0,
                yaw=0.0,
                pitch=0.0,
                roll=0.0,
                face_detected=False,
                confidence=0.0,
                timestamp=timestamp
            )
        
        # Get landmarks
        landmarks = results.multi_face_landmarks[0].landmark
        face_landmarks = [(lm.x, lm.y, lm.z) for lm in landmarks]
        
        # Extract eye landmarks and compute EAR
        left_eye = self.ear_calculator.extract_eye_landmarks(
            face_landmarks, 
            self.ear_calculator.LEFT_EYE_INDICES
        )
        right_eye = self.ear_calculator.extract_eye_landmarks(
            face_landmarks,
            self.ear_calculator.RIGHT_EYE_INDICES
        )
        
        left_ear = self.ear_calculator.calculate_ear(left_eye)
        right_ear = self.ear_calculator.calculate_ear(right_eye)
        average_ear = (left_ear + right_ear) / 2.0
        
        # Estimate head pose
        yaw, pitch, roll = self.head_pose_estimator.estimate(
            face_landmarks,
            self.frame_width,
            self.frame_height
        )
        
        # Create features object
        features = FacialFeatures(
            left_ear=left_ear,
            right_ear=right_ear,
            average_ear=average_ear,
            yaw=yaw,
            pitch=pitch,
            roll=roll,
            face_detected=True,
            confidence=0.9,  # MediaPipe doesn't provide face confidence directly
            timestamp=timestamp
        )
        
        # Update blink detector
        blink_event = self.blink_detector.update(average_ear, timestamp)
        if blink_event:
            self.temporal_extractor.add_blink(timestamp)
        
        # Update temporal features
        temporal = self.temporal_extractor.update(features)
        
        return features
    
    def get_model_input(self, features: FacialFeatures) -> np.ndarray:
        """
        Convert features to model input format.
        
        Returns:
            Numpy array of shape (num_features,)
        """
        base_features = features.to_array()
        temporal = self.temporal_extractor.update(features)
        
        # Combine all features
        return np.concatenate([
            base_features,
            np.array([
                temporal['ear_mean'],
                temporal['ear_std'],
                temporal['ear_derivative'],
                temporal['perclos'],
                temporal['blink_rate'] / 30.0,  # Normalize
            ])
        ])
    
    def close(self):
        """Release resources."""
        self.face_mesh.close()


if __name__ == "__main__":
    # Test feature extraction
    import time
    
    extractor = FeatureExtractor()
    
    # Test with webcam
    cap = cv2.VideoCapture(0)
    
    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            timestamp = time.time()
            features = extractor.extract(frame, timestamp)
            
            # Display
            if features.face_detected:
                text = f"EAR: {features.average_ear:.3f} | Y:{features.yaw:.1f} P:{features.pitch:.1f} R:{features.roll:.1f}"
                cv2.putText(frame, text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
            else:
                cv2.putText(frame, "No face detected", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
            
            cv2.imshow("Feature Extraction Test", frame)
            
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
    
    finally:
        cap.release()
        cv2.destroyAllWindows()
        extractor.close()
