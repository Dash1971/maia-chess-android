"""Archive reproducible byte ranges from the official Lichess Parquet dataset."""
import io, json, hashlib, time, random
from pathlib import Path
import requests
import pyarrow.parquet as pq
import pyarrow.compute as pc

HERE=Path(__file__).resolve().parent
REV='de4e636eddf568a9394cc01fb0b9e1da04a6babf'

class Remote(io.RawIOBase):
    def __init__(self,path,size):
        self.path=path; self.size=size; self.pos=0
        self.url=f'https://huggingface.co/datasets/Lichess/standard-chess-games/resolve/{REV}/{path}'
        self.folder=HERE/'cache'/path.replace('/','_');self.folder.mkdir(parents=True,exist_ok=True)
        self.blocks=[]
    def readable(self):return True
    def seekable(self):return True
    def tell(self):return self.pos
    def seek(self,offset,whence=0):
        self.pos=offset if whence==0 else self.pos+offset if whence==1 else self.size+offset
        return self.pos
    def read(self,n=-1):
        if n<0:n=self.size-self.pos
        n=min(n,self.size-self.pos)
        if n<=0:return b''
        start=self.pos;end=start+n-1;file=self.folder/f'{start}-{end}.bin'
        for a,z,data in self.blocks:
            if a<=start and end<=z:
                self.pos+=n;return data[start-a:end-a+1]
        if file.exists():data=file.read_bytes()
        else:
            # Serial requests, explicit range, archive bytes and response provenance.
            for retry in range(5):
                r=requests.get(self.url,headers={'Range':f'bytes={start}-{end}'},timeout=120)
                if r.status_code in (429,500,502,503,504):time.sleep(60 if r.status_code==429 else 2**retry);continue
                r.raise_for_status();break
            assert r.status_code==206,(r.status_code,r.headers)
            data=r.content;assert len(data)==n,(len(data),n)
            file.write_bytes(data)
            (file.with_suffix('.json')).write_text(json.dumps({'url':self.url,'status':r.status_code,'headers':dict(r.headers),'sha256':hashlib.sha256(data).hexdigest(),'fetched_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())},indent=2))
            time.sleep(.2)
        self.blocks.append((start,end,data))
        self.pos+=len(data);return data

def main():
    selected=[];rng=random.Random(20261002)
    prior=json.loads((HERE/'source'/'selection.json').read_text())['files'] if (HERE/'source'/'selection.json').exists() else None
    for month in (1,4,7,9):
        url=f'https://huggingface.co/api/datasets/Lichess/standard-chess-games/tree/{REV}/data/year=2025/month={month:02d}?limit=100'
        meta=HERE/'source'/f'tree-{month:02d}.json'
        if not meta.exists():meta.write_text(requests.get(url,timeout=30).text)
        files=[f for f in json.loads(meta.read_text()) if f['path'].endswith('.parquet')]
        item=next(f for f in files if f['path']==prior[len(selected)]['path']) if prior else files[rng.randrange(len(files))]
        src=Remote(item['path'],item['size']);pf=pq.ParquetFile(src)
        groups=sorted(set(random.Random(20261002+month).sample(range(pf.num_row_groups),20)) | set(prior[len(selected)]['row_groups'] if prior else []))
        info={'path':item['path'],'size':item['size'],'row_groups':groups,'total_groups':pf.num_row_groups,'schema':str(pf.schema_arrow)}
        selected.append(info);print(info,flush=True)
        for group in groups:
            out=HERE/'source'/f'games-{month:02d}-{group}.parquet'
            if out.exists():continue
            # Fetch the contiguous row-group once, then satisfy Arrow column reads locally.
            rg=pf.metadata.row_group(group)
            starts=[rg.column(c).dictionary_page_offset or rg.column(c).data_page_offset for c in range(rg.num_columns)]
            a=min(starts);z=max(starts[c]+rg.column(c).total_compressed_size for c in range(rg.num_columns))
            src.seek(a);src.read(z-a)
            cols=['Event','Site','White','Black','WhiteTitle','BlackTitle','WhiteElo','BlackElo','UTCDate','TimeControl','movetext']
            table=pf.read_row_group(group,columns=cols)
            # Broad 1400–1799 average rating allows bracketing exact model input 1600.
            w=pc.cast(table['WhiteElo'],'int32');b=pc.cast(table['BlackElo'],'int32')
            avg=pc.divide(pc.add(w,b),2)
            mask=pc.and_(pc.greater_equal(avg,1400),pc.less(avg,1800))
            mask=pc.and_(mask,pc.or_(pc.match_substring(table['Event'],'Blitz'),pc.match_substring(table['Event'],'Rapid')))
            table=table.filter(mask);pq.write_table(table,out)
            print('saved',out.name,table.num_rows,flush=True)
    (HERE/'source'/'selection.json').write_text(json.dumps({'revision':REV,'seed':20261002,'files':selected},indent=2))

if __name__=='__main__':main()
