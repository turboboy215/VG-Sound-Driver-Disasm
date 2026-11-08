import sys
d=open(sys.argv[1] if len(sys.argv)>1 and sys.argv[1].endswith('.gbc') else 'rom.gbc','rb').read()
SZ={1:None,2:0,3:0,4:0,5:2}
def parse(bank,addr,ch4len=1,maxev=100000,verbose=False):
    o=bank*0x4000+addr-0x4000
    ev=[];last=-1
    while True:
        t=d[o]<<8|d[o+1]; c=d[o+2]; ty=c>>4; n=c&15
        if ty==1:
            ln=3 if n<2 else 2 if n==2 else ch4len
        elif ty in (2,3,4): ln=0
        elif ty==5: ln=2
        else:
            ev.append((o,t,c,b'')); break
        ev.append((o,t,c,d[o+3:o+3+ln])); o+=3+ln
        if len(ev)>maxev: break
    return ev
if __name__=='__main__':
    bank=int(sys.argv[2],16); a=int(sys.argv[3],16); cl=int(sys.argv[4]) if len(sys.argv)>4 else 1
    ev=parse(bank,a,cl)
    from collections import Counter
    print(len(ev),'end at %X'%(ev[-1][0]%0x4000+0x4000), 'last t',ev[-1][1], 'endcmd %02X'%ev[-1][2])
    print(Counter(e[2] for e in ev))
    nonmono=sum(1 for i in range(1,len(ev)) if ev[i][1]<ev[i-1][1])
    print('nonmonotonic',nonmono)
    for e in ev[:int(sys.argv[5]) if len(sys.argv)>5 else 30]: print('%X t=%5d %02X %s'%(e[0]%0x4000+0x4000,e[1],e[2],e[3].hex(' ')))
