import wave
import struct
import math

def generate_chat_beep(filename):
    sample_rate = 44100
    duration_s = 0.05
    freq = 800  # subtle frequency
    volume = 0.15 # lower volume so it's not jarring
    
    wave_file = wave.open(filename, 'w')
    wave_file.setnchannels(1)
    wave_file.setsampwidth(2)
    wave_file.setframerate(sample_rate)
    
    num_samples = int(duration_s * sample_rate)
    for i in range(num_samples):
        t = float(i) / sample_rate
        # Envelope: quick attack and decay
        envelope = math.exp(-15 * t / duration_s) * volume
        # Sine wave for a soft beep
        val = math.sin(2 * math.pi * freq * t)
        sample = int(val * envelope * 32767.0)
        wave_file.writeframesraw(struct.pack('<h', sample))

    wave_file.close()

generate_chat_beep('mobile/assets/sounds/chat_beep.wav')
print('done')
