import hashlib

MOD_Q = 8380417

def sample_in_ball(rho: bytes, tau: int = 39):
    # Step 1: c = [0] * 256
    c = [0] * 256
    
    # Step 2-4: SHAKE256(rho)
    # We squeeze 8 bytes for signs, plus enough bytes for rejection sampling (e.g. 512 bytes total)
    ctx = hashlib.shake_256(rho)
    stream = ctx.digest(512)
    
    sign_bytes = stream[:8]
    byte_stream = list(stream[8:])
    
    # h bits: 64 bits from 8 bytes, little endian per byte
    h = []
    for byte in sign_bytes:
        for bit_idx in range(8):
            h.append((byte >> bit_idx) & 1)
            
    stream_idx = 0
    h_idx = 0
    for i in range(256 - tau, 256):
        # Step 6-9: Rejection sampling
        while True:
            if stream_idx >= len(byte_stream):
                raise RuntimeError("Byte stream exhausted")
            j = byte_stream[stream_idx]
            stream_idx += 1
            if j <= i:
                break
        
        # Step 10-11: Fisher-Yates update
        sign_bit = h[h_idx]
        h_idx += 1
        sign_val = MOD_Q - 1 if sign_bit == 1 else 1  # -1 or +1 in Z_q
        
        c[i] = c[j]
        c[j] = sign_val
        
    return c

if __name__ == "__main__":
    # Test with a known seed
    seed = b"\x00" * 32
    poly44 = sample_in_ball(seed, tau=39)
    non_zeros = [(idx, val) for idx, val in enumerate(poly44) if val != 0]
    print(f"ML-DSA-44 (tau=39) non-zero count: {len(non_zeros)}")
    print(f"Sample non-zero coeffs: {non_zeros[:5]}")
    
    poly65 = sample_in_ball(seed, tau=49)
    print(f"ML-DSA-65 (tau=49) non-zero count: {len([x for x in poly65 if x != 0])}")
    
    poly87 = sample_in_ball(seed, tau=60)
    print(f"ML-DSA-87 (tau=60) non-zero count: {len([x for x in poly87 if x != 0])}")
