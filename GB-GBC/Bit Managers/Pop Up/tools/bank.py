"""Banked ROM view: bytes object of $8000 = bank 0 + bank n (CPU addresses $0000-$7FFF)."""
def view(path, bank):
    r = open(path, 'rb').read()
    return r[:0x4000] + r[bank * 0x4000:(bank + 1) * 0x4000]
