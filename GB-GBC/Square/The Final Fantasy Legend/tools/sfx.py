import sys, os; sys.path.insert(0, os.path.dirname(__file__))
from ffl1parse import rb, rw
NSFX = 36
TT, NT = 0x6BC7, 0x6C0F
def walk(a, noise, own, labels):
    todo = [a]
    while todo:
        a = todo.pop()
        while a not in own:
            d = rb(a)
            own[a] = noise
            if d & 0xF0 == 0xE0: a += 1; continue
            if d >= 0xF0: labels.add(rw(a + 1)); todo.append(rw(a + 1)); own[a + 1] = own[a + 2] = noise; a += 3; continue
            if d == 0: break
            n = 3 if noise else 6
            for i in range(1, n): own[a + i] = noise
            a += n
if __name__ == '__main__':
    own = {}; lab = set()
    for i in range(NSFX):
        t, n = rw(TT + 2 * i), rw(NT + 2 * i)
        print(i + 1, '%04X %04X' % (t, n))
        walk(t, 0, own, lab); walk(n, 1, own, lab)
    lo, hi = min(own), max(own)
    print('data %04X-%04X' % (lo, hi), 'gaps', ['%04X' % x for x in range(lo, hi) if x not in own][:30])
