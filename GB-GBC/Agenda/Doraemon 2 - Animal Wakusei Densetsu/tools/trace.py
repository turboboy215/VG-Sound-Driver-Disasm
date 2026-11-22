import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sm83 import dis
def trace(rom, bank, entries, stop_jphl_tables=None):
    off=bank*0x4000-0x4000 if bank else 0
    code={}  # addr->(text,len,target,kind)
    todo=list(entries)
    while todo:
        pc=todo.pop()
        while pc not in code:
            if not (0x4000<=pc<0x8000): break
            t,l,tg,k=dis(rom,pc+off,-off)
            code[pc]=(t,l,tg,k)
            if k in ('call','jpc','jrc') and tg is not None and 0x4000<=tg<0x8000: todo.append(tg)
            if k in ('jp','jr'):
                if 0x4000<=tg<0x8000: todo.append(tg)
                break
            if k in ('ret','jphl','bad'): break
            pc+=l
    return code
