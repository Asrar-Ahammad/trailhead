import wave
import struct
import math

def generate_tone(filename, freq_start, freq_end, duration_s, sample_rate=44100, volume=0.5, waveform='square'):
    num_samples = int(duration_s * sample_rate)
    wave_file = wave.open(filename, 'w')
    wave_file.setnchannels(1) # mono
    wave_file.setsampwidth(2) # 16-bit
    wave_file.setframerate(sample_rate)

    for i in range(num_samples):
        t = float(i) / sample_rate
        # Linear frequency sweep
        freq = freq_start + (freq_end - freq_start) * (t / duration_s)
        
        # Envelope: quick attack, exponential decay
        envelope = math.exp(-3 * t / duration_s) * volume
        
        if waveform == 'square':
            val = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
        elif waveform == 'sawtooth':
            val = 2.0 * (freq * t - math.floor(0.5 + freq * t))
        else: # sine
            val = math.sin(2 * math.pi * freq * t)
            
        sample = int(val * envelope * 32767.0)
        
        # Clamp
        sample = max(-32768, min(32767, sample))
        
        wave_file.writeframesraw(struct.pack('<h', sample))
    
    wave_file.close()

# Best Efforts: Quick, bright, slightly ascending square wave (like a small success)
generate_tone('mobile/assets/sounds/tab_best_efforts.wav', freq_start=600, freq_end=800, duration_s=0.15, volume=0.3, waveform='square')

# All-Time PRs: Deeper, slightly descending or steady sawtooth wave (feels more established/historical)
generate_tone('mobile/assets/sounds/tab_all_time.wav', freq_start=400, freq_end=350, duration_s=0.2, volume=0.3, waveform='sawtooth')

# Add Manual Run FAB: Bright ascending sine wave
generate_tone('mobile/assets/sounds/fab_add_run.wav', freq_start=500, freq_end=1200, duration_s=0.2, volume=0.3, waveform='sine')

print("Generated tab_best_efforts.wav, tab_all_time.wav, and fab_add_run.wav")
