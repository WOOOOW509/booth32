import random

def to_hex32(val):
    return f"{val & 0xFFFFFFFF:08x}"

def to_hex64(val):
    return f"{val & 0xFFFFFFFFFFFFFFFF:016x}"

def generate_vectors(filename="tb/test_vectors.hex", num_random=2000):
    INT32_MIN = -(1 << 31)
    INT32_MAX = (1 << 31) - 1

    # Kasus sudut (corner cases) wajib
    cases = [
        (0, 0),
        (0, INT32_MAX),
        (0, INT32_MIN),
        (1, 1),
        (-1, -1),
        (1, -1),
        (-1, 1),
        (INT32_MAX, 1),
        (INT32_MAX, -1),
        (INT32_MIN, 1),
        (INT32_MIN, -1),
        (INT32_MAX, INT32_MAX),
        (INT32_MIN, INT32_MIN),
        (INT32_MAX, INT32_MIN),
        (INT32_MIN, INT32_MAX),
        (12345678, -87654321),
    ]

    # Tambahkan vektor acak dengan seed tetap agar deterministik
    random.seed(42)
    for _ in range(num_random):
        a = random.randint(INT32_MIN, INT32_MAX)
        b = random.randint(INT32_MIN, INT32_MAX)
        cases.append((a, b))

    with open(filename, "w") as f:
        for a, b in cases:
            prod = a * b
            # Format: multiplicand_32bit multiplier_32bit expected_product_64bit
            f.write(f"{to_hex32(a)}{to_hex32(b)}{to_hex64(prod)}\n")

    print(f"Berhasil membuat {len(cases)} vektor uji di {filename}")

if __name__ == "__main__":
    generate_vectors()
