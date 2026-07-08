import math
import wave
import struct
import os

SAMPLE_RATE = 44100

def generate_tone(frequency, duration_ms, volume=0.3, wave_type='square'):
    num_samples = int(SAMPLE_RATE * (duration_ms / 1000.0))
    samples = []
    
    for i in range(num_samples):
        t = float(i) / SAMPLE_RATE
        
        # Envelope: fast attack, slight decay to avoid clipping clicks
        env = 1.0
        if i < 100: env = i / 100.0
        if i > num_samples - 400: env = (num_samples - i) / 400.0
        
        # Generator
        val = 0.0
        if wave_type == 'square':
            val = 1.0 if math.sin(2.0 * math.pi * frequency * t) > 0 else -1.0
        elif wave_type == 'sawtooth':
            val = 2.0 * (t * frequency - math.floor(t * frequency + 0.5))
        elif wave_type == 'triangle':
            val = 2.0 * abs(2.0 * (t * frequency - math.floor(t * frequency + 0.5))) - 1.0
        elif wave_type == 'noise':
            import random
            val = random.uniform(-1, 1)
            
        sample = int(val * volume * env * 32767.0)
        samples.append(sample)
        
    return samples

def save_wav(filename, samples):
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        for s in samples:
            f.writeframesraw(struct.pack('<h', s))

def generate_blip():
    return generate_tone(880, 50, wave_type='square', volume=0.15)

def generate_tap():
    return generate_tone(440, 40, wave_type='triangle', volume=0.2) + generate_tone(330, 40, wave_type='triangle', volume=0.15)

def generate_start():
    # Arpeggio up
    s = []
    s.extend(generate_tone(440, 100, wave_type='square', volume=0.2))
    s.extend(generate_tone(554, 100, wave_type='square', volume=0.2))
    s.extend(generate_tone(659, 100, wave_type='square', volume=0.2))
    s.extend(generate_tone(880, 200, wave_type='square', volume=0.2))
    return s

def generate_pause():
    s = []
    s.extend(generate_tone(659, 80, wave_type='triangle', volume=0.2))
    s.extend(generate_tone(440, 80, wave_type='triangle', volume=0.2))
    return s

def generate_finish():
    # Happy jingle
    s = []
    s.extend(generate_tone(523, 150, wave_type='square', volume=0.2))
    s.extend(generate_tone(659, 150, wave_type='square', volume=0.2))
    s.extend(generate_tone(783, 150, wave_type='square', volume=0.2))
    s.extend(generate_tone(1046, 400, wave_type='square', volume=0.25))
    return s

def generate_error():
    s = []
    s.extend(generate_tone(300, 150, wave_type='sawtooth', volume=0.2))
    s.extend(generate_tone(200, 250, wave_type='sawtooth', volume=0.2))
    return s

def generate_pr_new():
    # Arcade high score
    s = []
    for f in [523, 659, 783, 1046, 1318, 1046, 1567]:
        s.extend(generate_tone(f, 80, wave_type='square', volume=0.2))
    s.extend(generate_tone(2093, 400, wave_type='square', volume=0.25))
    return s

def generate_streak():
    s = []
    s.extend(generate_tone(440, 100, wave_type='triangle', volume=0.2))
    s.extend(generate_tone(554, 100, wave_type='triangle', volume=0.2))
    s.extend(generate_tone(659, 300, wave_type='triangle', volume=0.25))
    return s

out_dir = '/Users/shaikmohammadasrarahammad/Downloads/MyProjects/trailhead/mobile/assets/sounds'
save_wav(os.path.join(out_dir, 'nav_blip.wav'), generate_blip())
save_wav(os.path.join(out_dir, 'button_tap.wav'), generate_tap())
save_wav(os.path.join(out_dir, 'run_start.wav'), generate_start())
save_wav(os.path.join(out_dir, 'pause_resume.wav'), generate_pause())
save_wav(os.path.join(out_dir, 'run_finish.wav'), generate_finish())
save_wav(os.path.join(out_dir, 'error.wav'), generate_error())
save_wav(os.path.join(out_dir, 'pr_new.wav'), generate_pr_new())
save_wav(os.path.join(out_dir, 'streak_fanfare.wav'), generate_streak())

print("Sounds generated!")
