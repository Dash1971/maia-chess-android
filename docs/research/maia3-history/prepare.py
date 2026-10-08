"""Unpack recorded evidence; optionally fetch the hash-pinned model or human source."""
from pathlib import Path
import argparse,hashlib,json,tarfile,urllib.request
ROOT=Path(__file__).resolve().parent
def digest(path):
 h=hashlib.sha256()
 with path.open('rb') as f:
  for b in iter(lambda:f.read(1048576),b''):h.update(b)
 return h.hexdigest()
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--model',action='store_true');p.add_argument('--human',action='store_true');a=p.parse_args()
 expected={line.split('  ',1)[1]:line.split('  ',1)[0] for line in (ROOT/'SHA256SUMS').read_text().splitlines()}
 for sub,name in [('broad-study','records.tar.gz'),('stonewall','policies.tar.gz')]:
  path=ROOT/sub/name;assert digest(path)==expected[f'{sub}/{name}'],f'Checksum mismatch: {path}'
  with tarfile.open(path) as tar:
   for member in tar.getmembers():
    target=ROOT/sub/member.name
    assert member.isfile() and target.resolve().is_relative_to((ROOT/sub).resolve())
    if target.exists():
     assert target.read_bytes()==tar.extractfile(member).read(),f'Refusing to overwrite changed file: {target}'
    else:tar.extract(member,ROOT/sub,filter='data')
 pins=json.loads((ROOT/'source-pins.json').read_text())
 for enabled,key,rel in [(a.model,'model','assets/maia3-79m.onnx'),(a.human,'allie','broad-study/source/allie-test.jsonl')]:
  if not enabled:continue
  target=ROOT/rel;target.parent.mkdir(parents=True,exist_ok=True)
  if target.exists():assert digest(target)==pins[key]['sha256'];continue
  temp=target.with_suffix('.download');urllib.request.urlretrieve(pins[key]['url'],temp)
  assert digest(temp)==pins[key]['sha256'],f'Checksum mismatch: {key}'
  temp.rename(target)
 print('Recorded evidence unpacked; requested downloads verified.')
if __name__=='__main__':main()
