# Audio Alert Files

This directory contains audio files for drowsiness alerts.

## Required Audio Files

### 1. alert_warning.mp3
- **Purpose**: Medium-level drowsiness warning
- **Duration**: 1-2 seconds
- **Style**: Attention-grabbing but not alarming
- **Example**: Double beep, chime

### 2. alert_critical.mp3  
- **Purpose**: Critical alert for microsleep detection
- **Duration**: 2-3 seconds, may loop
- **Style**: Urgent, impossible to ignore
- **Example**: Alarm siren, loud buzzer

### 3. alert_gentle.mp3 (Optional)
- **Purpose**: Subtle reminder for mild drowsiness
- **Duration**: 0.5-1 second
- **Style**: Soft notification sound

## Audio Specifications

| Property | Recommendation |
|----------|----------------|
| Format | MP3 or WAV |
| Sample Rate | 44.1kHz |
| Bit Rate | 128kbps+ |
| Channels | Stereo or Mono |
| Volume | Normalized to -3dB |

## Notes

- Audio should be clearly audible over road/engine noise
- Consider varying frequencies to prevent habituation
- Critical alerts should have high-frequency components for attention
- Test in actual driving conditions
