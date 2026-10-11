def summary(r, songs, song_table, count):
    rows = []
    for i in range(count):
        h = r.word(song_table+2*i); lt = r.word(h+1)
        desc = []
        for ch in range(4):
            L = r.word(h+songs.hch+2*ch)
            if not L: desc.append('-'); continue
            a = L; n = 0; end = 'none'
            while a in songs.list_words:
                k, v = songs.list_words[a]
                if k == 'pat': n += 1; a += 2
                elif k == 'end': end = 'end'; break
                else: end = f'loop->{(v-L)//2}'; break
                if a in songs.lists and a != L: break
            desc.append(f'{n} {end}')
        rows.append((i+1, h, lt, r.byte(lt+3), r.byte(h), desc))
    return rows
