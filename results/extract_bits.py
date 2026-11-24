import os
import sys

def extract_bits(log_file_path, output_file_path, whiten=True):
    if not os.path.exists(log_file_path):
        print(f"Error: {log_file_path} does not exist.")
        return

    print(f"Reading {log_file_path}...")
    with open(log_file_path, 'rb') as f:
        # Read the first line which may be a PuTTY header if logged via PuTTY
        first_line = f.readline()
        if b"PuTTY" in first_line or b"=" in first_line:
            print("Skipped PuTTY Header:", first_line.decode('utf-8', errors='ignore').strip())
            data = f.read()
        else:
            # If no header, keep the first line as data
            data = first_line + f.read()

    print(f"Loaded {len(data)} bytes of raw data.")
    
    # 2-Byte differential whitening eliminates physical silicon DC bias
    if whiten and len(data) >= 2:
        print("Applying 2-byte differential whitening (B[2k] ^ B[2k+1]) to eliminate physical silicon DC bias...")
        data = bytes([data[2*i] ^ data[2*i+1] for i in range(len(data)//2)])
        print(f"Whitened data size: {len(data)} bytes.")

    print("Converting to bits...")
    bit_strings = [f"{b:08b}" for b in data]
    all_bits = "".join(bit_strings)
    
    ones_count = all_bits.count('1')
    total = len(all_bits)
    print(f"Total bits extracted: {total} ({total/1e6:.3f} million bits)")
    if total > 0:
        print(f"Ones: {ones_count:,} | Zeros: {total - ones_count:,} | Ratio: {ones_count/total:.6f}")
    
    with open(output_file_path, 'w', encoding='utf-8') as f_out:
        f_out.write(all_bits)
        
    print(f"Saved bitstream successfully to: {output_file_path}")

if __name__ == "__main__":
    cwd = os.path.dirname(os.path.abspath(__file__))
    log_path = os.path.join(cwd, "putty.txt")
    output_path = os.path.join(cwd, "extracted_bits.txt")
    
    # Pass --raw if you wish to extract raw without differential whitening
    use_whiten = True if "--raw" not in sys.argv else False
    extract_bits(log_path, output_path, whiten=use_whiten)

