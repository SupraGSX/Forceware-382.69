from pathlib import Path
import subprocess,json,itertools,struct,hashlib
import argparse
p=argparse.ArgumentParser();p.add_argument('--base-mini',type=Path,required=True);p.add_argument('--out',type=Path,required=True);args=p.parse_args()
T=Path(__file__).resolve().parent;D=args.out.resolve();assert not D.exists();D.mkdir(parents=True)
e=bytearray(256);e[:8]=bytes.fromhex('00ffffffffffff00');e[18:21]=bytes([1,3,0x80]);e[126]=1;e[127]=-sum(e[:127])&255
vendor_data=bytes.fromhex('6d030c002000b83c20006001020367d85dc401788003681a00000101283c00')
e[128:132]=bytes([2,3,4+len(vendor_data),0x71]);e[132:132+len(vendor_data)]=vendor_data;e[255]=-sum(e[128:255])&255;e=bytes(e)
assert len(e)==256 and sum(e[:128])%256==sum(e[128:])%256==0

bs=[];i=132
while i<128+e[130]:n=e[i]&31;bs.append(e[i:i+n+1]);i+=n+1
vendors=[b for b in bs if b[0]>>5==3];assert [b[1:4].hex() for b in vendors]==['030c00','d85dc4','1a0000']
legacy,hf,amd=vendors;others=[b for b in bs if b not in vendors]
def ed(blocks):
 b=bytearray(e);b[128:]=bytes(128);b[128:132]=bytes([2,3,4+sum(map(len,blocks)),e[131]]);b[132:132+sum(map(len,blocks))]=b''.join(blocks);b[255]=-sum(b[128:255])&255;return bytes(b)
cases=[('synthetic-vendor-order',e,'030c00')]
for k,p in enumerate(itertools.permutations(vendors)):cases.append(('vendor-order-'+str(k),ed(others+list(p)),'030c00'))
for name,blocks,want in [('no-vendor',others,'000000'),('forum-only',others+[hf],'000000'),('amd-only',others+[amd],'1a0000'),('non-hdmi-multiple',others+[amd,bytes.fromhex('65010203aabb')],'010203'),('short-hdmi',others+[bytes.fromhex('63030c00')],'000000'),('short-unknown',others+[bytes.fromhex('620102')],'000000'),('hdmi-then-short',others+[legacy,bytes.fromhex('63030c00')],'030c00'),('hdmi-then-other',others+[legacy,bytes.fromhex('65010203aabb')],'030c00'),('refresh-hdmi',others+[legacy],'030c00'),('refresh-dvi',others,'000000'),('refresh-amd',others+[amd],'1a0000')]:cases.append((name,ed(blocks),want))
(D/'cases.h').write_text('unsigned char cases[][256]={'+','.join('{'+','.join(map(str,b))+'}' for _,b,_ in cases)+'};\n')
(D/'harness.c').write_text('''#include "cases.h"
typedef unsigned int U;extern U __attribute__((stdcall)) parser(void*,U,void*);
void wr(void*p,U n){__asm__ volatile("int $0x80"::"a"(4),"b"(1),"c"(p),"d"(n):"memory");}
void _start(void){unsigned char out[115];for(U j=0;j<115;j++)out[j]=0xa5;for(U i=0;i<sizeof(cases)/256;i++){U r=parser(cases[i],256,out+4);wr(&r,4);wr(out,115);}__asm__ volatile("int $0x80"::"a"(1),"b"(0));__builtin_unreachable();}
''')
base=args.base_mini;data=base.read_bytes()[0x864150:0x864340];assert data[0x5e]==0xe8
(D/'native.bin').write_bytes(data)
for label in ['control','candidate']:
 asm='.intel_syntax noprefix\n.code32\n.text\n.global parser\nparser:\n.incbin "'+str(D/'native.bin')+'",0,0x5e\ncall zeromem\n'
 if label=='control':asm+='.incbin "'+str(D/'native.bin')+'",0x63,0x18d\n'
 else:
  asm+='.incbin "'+str(D/'native.bin')+'",0x63,0xfd\njmp priority\n.fill 50,1,0x90\n.incbin "'+str(D/'native.bin')+'",0x197,0x59\n'
  s=(T/'hdmi-vendor-priority.s').read_text().replace('.global _start','').replace('_start:','priority:').replace('.set done, 0x87432a','.set done, parser+0x1da')
  asm+=s
 asm+='\nzeromem:\npush edi\nmov edi,[esp+8]\nmov eax,[esp+12]\nmov ecx,[esp+16]\nrep stosb\npop edi\nret\n.section .note.GNU-stack,"",@progbits\n'
 (D/(label+'.s')).write_text(asm)
 subprocess.run(['gcc','-m32','-nostdlib','-fno-pie','-no-pie','-fno-stack-protector','-O1','-Wl,-e,_start',str(D/'harness.c'),str(D/(label+'.s')),'-o',str(D/label)],check=True)
 r=subprocess.run([str(D/label)],capture_output=True,timeout=5);assert r.returncode==0 and len(r.stdout)==119*len(cases);(D/(label+'.results')).write_bytes(r.stdout)
rows=[]
for i,(name,b,want) in enumerate(cases):
 o=(D/'control.results').read_bytes()[119*i:119*(i+1)];c=(D/'candidate.results').read_bytes()[119*i:119*(i+1)]
 oui=c[8+0x45:8+0x48].hex();assert oui==want,(name,oui,want);assert c[:4]==bytes(4) and c[4:8]==c[-4:]==bytes([0xa5])*4
 # The change cannot alter audio, video, color or underscan summaries.
 assert c[8:8+0x45]==o[8:8+0x45] and c[8+0x68:115]==o[8+0x68:115]
 rows.append({'case':name,'control_oui':o[8+0x45:8+0x48].hex(),'candidate_oui':oui,'pass':True})
assert rows[0]['control_oui']=='1a0000'
(D/'results.json').write_text(json.dumps({'method':'Extracted native x86 CTA parser executed with equivalent memset; persistent summary reused across every case; guards and non-vendor fields checked. Candidate hook branches to assembled priority source.','checksums':[sum(e[:128])%256,sum(e[128:])%256],'cases':rows},indent=2)+'\n');print(json.dumps(rows,indent=2))
