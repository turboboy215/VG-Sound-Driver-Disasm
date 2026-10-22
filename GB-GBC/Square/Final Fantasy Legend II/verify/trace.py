import sys, os; sys.path.insert(0, os.path.dirname(__file__))
from sm83 import decode
def load(rom, bank):
    r = open(rom, 'rb').read(); base = bank * 0x4000
    return r, base
def trace(r, base, entries, stop=0x8000):
    code = {}; todo = list(entries)
    off = lambda a: a - 0x4000 + base
    while todo:
        pc = todo.pop()
        while pc not in code and 0x4000 <= pc < stop:
            l, m, t, k = decode(r, off(pc), pc)
            code[pc] = (l, m, t, k)
            if k in ('jmp', 'cjmp', 'call') and t is not None and t >= 0x4000: todo.append(t)
            if k in ('jmp', 'ret', 'jphl', 'bad'): break
            pc += l
    return code
