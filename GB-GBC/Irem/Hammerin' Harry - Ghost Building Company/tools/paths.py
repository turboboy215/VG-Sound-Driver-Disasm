# Paths shared by the Irem tools: the ROMs sit in the folder above tools/
import os
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROMS={'kn':os.path.join(ROOT,'Kid Niki (J).gb'),
      'hh':os.path.join(ROOT,"Hammerin' Harry - Ghost Building Company (U).gb")}
def tool(*p): return os.path.join(ROOT,'tools',*p)
def verify(*p): return os.path.join(ROOT,'verify',*p)
