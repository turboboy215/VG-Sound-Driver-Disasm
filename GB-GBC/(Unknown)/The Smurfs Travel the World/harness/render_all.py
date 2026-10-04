from render import run
import subprocess, os
speeds={0:0xF3,1:0xF2,2:0xF3,4:0xF4,5:0xF3,9:0xEF,10:0xF3,12:0xF3}
sfxsp={0:0xF4,1:0xE0,2:0xF1,3:0xE2,4:0xDE,5:0xE6,6:0xEB,8:0xEE,9:0xE6,11:0xE0,12:0xE0,13:0xE3,14:0xE1,15:0xEE,16:0xDD,17:0xEA}
def enc(w):
    subprocess.run(['ffmpeg','-y','-loglevel','error','-i',w,'-ac','2','-b:a','128k',w[:-4]+'.mp3']); os.remove(w)
for s in range(13):
    n,l=run(1,s,speeds.get(s,0xF3),6000,wav='audio/song%02d.wav'%s)
    extra=''
    enc('audio/song%02d.wav'%s); print('song',s,n)
for s in range(18):
    n,l=run(2,s,sfxsp.get(s,0xE0),600,until_loop=False,wav='audio/sfx%02d.wav'%s)
    enc('audio/sfx%02d.wav'%s); print('sfx',s,n)
