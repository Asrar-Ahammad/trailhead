import wave
import struct
import math

def generate_mic_beep(filename):
    sample_rate = 44100
    wave_file = wave.open(filename, 'w')
    wave_file.setnchannels(1)
    wave_file.setsampwidth(2)
    wave_file.setframerate(sample_rate)
    
    # beep 1: 1500Hz for 0.05s
    for i in range(int(0.05 * sample_rate)):
        val = math.sin(2 * math.pi * 1500 * (i/sample_rate))
        sample = int(val * 0.3 * 32767)
        wave_file.writeframesraw(struct.pack('<h', sample))
    
    # gap: 0.02s
    for i in range(int(0.02 * sample_rate)):
        wave_file.writeframesraw(struct.pack('<h', 0))
        
    # beep 2: 2000Hz for 0.05s
    for i in range(int(0.05 * sample_rate)):
        val = math.sin(2 * math.pi * 2000 * (i/sample_rate))
        sample = int(val * 0.3 * 32767)
        wave_file.writeframesraw(struct.pack('<h', sample))

    wave_file.close()

generate_mic_beep('mobile/assets/sounds/mic_start.wav')
print('done')
