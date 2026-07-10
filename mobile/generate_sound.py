import wave
import struct
import math
import sys

def generate_retro_sound(filename, start_freq, end_freq, duration_sec):
    sample_rate = 44100
    num_samples = int(sample_rate * duration_sec)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            # slide frequency
            freq = start_freq + ((end_freq - start_freq) * (i / num_samples))
            
            # square wave
            value = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
            
            # simple envelope
            envelope = 1.0 - (i / num_samples)
            amplitude = 8000
            
            sample = int(value * amplitude * envelope)
            wav_file.writeframesraw(struct.pack('<h', sample))

if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == "switch_run":
        generate_retro_sound('assets/sounds/switch_run.wav', 400, 800, 0.15)
    elif cmd == "switch_walk":
        generate_retro_sound('assets/sounds/switch_walk.wav', 800, 400, 0.15)
    elif cmd == "pace_up":
        generate_retro_sound('assets/sounds/pace_up.wav', 800, 1000, 0.08)
    elif cmd == "pace_down":
        generate_retro_sound('assets/sounds/pace_down.wav', 400, 300, 0.08)
    elif cmd == "nav_home":
        generate_retro_sound('assets/sounds/nav_home.wav', 300, 350, 0.1)
    elif cmd == "nav_record":
        generate_retro_sound('assets/sounds/nav_record.wav', 500, 600, 0.1)
    elif cmd == "nav_you":
        generate_retro_sound('assets/sounds/nav_you.wav', 700, 750, 0.1)
    elif cmd == "run_discard":
        # Sad downward sweep (like losing a life)
        generate_retro_sound('assets/sounds/run_discard.wav', 300, 150, 0.4)
