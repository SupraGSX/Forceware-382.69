#!/usr/bin/env python3
"""Extend the RM name table for the desktop GPU records retained by this build."""
from pathlib import Path
import struct,hashlib,json,collections,argparse
class PE:
 def __init__(self,p):
  self.p=Path(p);self.b=self.p.read_bytes();b=self.b
  if b[:2]!=b'MZ': raise ValueError('not MZ')
  pe=self.u32(0x3c)
  if b[pe:pe+4]!=b'PE\0\0': raise ValueError('not PE')
  self.machine=self.u16(pe+4);n=self.u16(pe+6);opt=pe+24;self.magic=self.u16(opt);self.ptr=8 if self.magic==0x20b else 4
  self.base=struct.unpack_from('<Q' if self.ptr==8 else '<I',b,opt+(24 if self.ptr==8 else 28))[0]
  self.entry=self.u32(opt+16);self.sections=[]
  for i in range(n):
   o=opt+self.u16(pe+20)+40*i
   self.sections.append(dict(name=b[o:o+8].rstrip(b'\0').decode(errors='replace'),vsize=self.u32(o+8),rva=self.u32(o+12),size=self.u32(o+16),offset=self.u32(o+20),flags=self.u32(o+36)))
  self.dirs=[struct.unpack_from('<II',b,opt+(112 if self.ptr==8 else 96)+i*8) for i in range(16)]
 def u16(self,o):return struct.unpack_from('<H',self.b,o)[0]
 def u32(self,o):return struct.unpack_from('<I',self.b,o)[0]
 def off(self,r):
  for s in self.sections:
   if s['rva']<=r<s['rva']+max(s['vsize'],s['size']):return s['offset']+r-s['rva']
  return r
 def rva(self,o):
  for s in self.sections:
   if s['offset']<=o<s['offset']+s['size']:return s['rva']+o-s['offset']
  return o
 def sec(self,o):return next((s['name'] for s in self.sections if s['offset']<=o<s['offset']+s['size']),None)
 def cstr(self,o):return self.b[o:self.b.find(b'\0',o)].decode('ascii',errors='replace')
 def pos(self,o):return dict(offset=hex(o),rva=hex(self.rva(o)),va=hex(self.base+self.rva(o)),section=self.sec(o))

args=argparse.ArgumentParser(description=__doc__)
args.add_argument('source',type=Path,help='Unmodified 10-4-2026 release nv4_mini.sys')
args.add_argument('destination',type=Path,help='New output directory')
args.add_argument('--gpu-list',type=Path,default=Path(__file__).with_name('compute-gpus.json'))
args=args.parse_args();src=args.source;p=PE(src);b=bytearray(p.b)
sha=lambda x:hashlib.sha256(x).hexdigest()
assert sha(b)=='46536fa6eaa9aad6f88a7f0eaa38e9eb472e93efe1928cc7b01870f4cbd8e647'
pe=p.u32(0x3c);opt=pe+24;sh=opt+p.u16(pe+20);last=p.sections[-1];assert last['name']=='.reloc' and last['offset']+last['size']==len(b) and last['rva']==last['offset']
assert p.u32(opt+32)==32 and p.u32(opt+36)==32
# This package already retains this final section as nonpageable, nondiscardable memory.
assert last['flags']&0x08000000 and not last['flags']&0x02000000
old_table=0xb92de8;old_count=640;old_off=p.off(old_table-p.base);table=bytes(b[old_off:old_off+old_count*12])
gpus=json.loads(args.gpu_list.read_text())
existing={struct.unpack_from('<H',table,i*12)[0] for i in range(old_count)}
added=[]
for g in gpus:
 if int(g['device'],16) in existing:continue
 assert 'subsystem' not in g, 'Do not generalize a subsystem-only alias'
 short=g['name'].removeprefix('NVIDIA ');long='NVIDIA '+short
 assert len(short.encode('ascii'))<64 and len(long.encode('ascii'))<64
 added.append({'device':g['device'],'die':g['die'],'short_name':short,'long_name':long})
assert {g['device'] for g in added}=={'1B02','1B06','1B83','1C04','1C06','1C31','1C83','1CB1','1CB2','1CB3'}
assert len(added)==10
new_count=old_count+len(added)
rr,rs=p.dirs[5];original_reloc=bytes(b[p.off(rr):p.off(rr)+rs]);relocs=set();i=0
while i<len(original_reloc):
 page,sz=struct.unpack_from('<II',original_reloc,i);assert sz>=8 and i+sz<=len(original_reloc)
 for v in struct.unpack_from('<%dH'%((sz-8)//2),original_reloc,i+8):
  assert v>>12 in (0,3)
  if v>>12==3:relocs.add(page+(v&4095))
 i+=sz
assert i==len(original_reloc)
new_off=len(b);new_va=p.base+new_off;name_off=new_off+new_count*12
records=bytearray(table);names=bytearray()
for g in added:
 short=g['short_name'].encode('ascii')+b'\0';long=g['long_name'].encode('ascii')+b'\0'
 start=p.base+name_off+len(names)
 records+=struct.pack('<HHII',int(g['device'],16),0,start,start+len(short))
 names+=short+long
b+=records+names
b+=bytes((-len(b))%4)
changes=[]
for old,sites in [(old_table,[0x557a4a,0x557a93,0x557b03]),(old_table+2,[0x557a9c,0x557b0c]),(old_table+4,[0x557ad3]),(old_table+8,[0x557b43])]:
 for va in sites:
  rva=va-p.base;o=p.off(rva);assert struct.unpack_from('<I',b,o)[0]==old and rva in relocs
  new=new_va+old-old_table;struct.pack_into('<I',b,o,new);changes.append({'va':hex(va),'before':hex(old),'after':hex(new)})
for va in [0x557a54,0x557aaf,0x557b1f]:
 o=p.off(va-p.base);assert struct.unpack_from('<I',b,o)[0]==old_count*12;struct.pack_into('<I',b,o,new_count*12);changes.append({'va':hex(va),'before':old_count*12,'after':new_count*12})
new_relocs=[]
for i in range(new_count):
 for delta in (4,8):
  if i<old_count:assert old_table-p.base+i*12+delta in relocs
  new_relocs.append(new_off+i*12+delta)
groups=collections.defaultdict(list)
for r in new_relocs:groups[r&~4095].append(0x3000|(r&4095))
extra=bytearray()
for page,words in sorted(groups.items()):
 if len(words)%2:words.append(0)
 extra+=struct.pack('<II',page,8+len(words)*2)+struct.pack('<%dH'%len(words),*words)
new_reloc_off=len(b);b+=original_reloc+extra
struct.pack_into('<II',b,opt+96+5*8,new_reloc_off,len(original_reloc)+len(extra))
new_vsize=len(b)-last['offset'];b+=bytes((-len(b))%32);new_size=len(b)-last['offset']
ls=sh+40*(len(p.sections)-1);struct.pack_into('<I',b,ls+8,new_vsize);struct.pack_into('<I',b,ls+16,new_size);struct.pack_into('<I',b,opt+56,len(b));struct.pack_into('<I',b,opt+8,p.u32(opt+8)+new_size-last['size']);struct.pack_into('<I',b,opt+64,0)
# PE checksum over final file, including appended relocation data.
checksum=0
for pos in range(0,len(b),2):
 checksum+=b[pos]+((b[pos+1] if pos+1<len(b) else 0)<<8);checksum=(checksum&65535)+(checksum>>16)
checksum=(checksum&65535)+(checksum>>16);checksum=(checksum&65535)+len(b);struct.pack_into('<I',b,opt+64,checksum)
out=args.destination;out.mkdir(parents=True,exist_ok=True);dst=out/'nv4_mini.sys';assert dst.resolve()!=src.resolve();dst.write_bytes(b)
q=PE(dst);assert q.b[new_off:new_off+len(table)]==table and q.dirs[5][1]==len(original_reloc)+len(extra)
# Simulate nonpreferred-base loading and verify every copied pointer keeps its meaning.
bias=0xb685c000-p.base
for i in range(old_count):
 for d in (4,8):assert struct.unpack_from('<I',q.b,new_off+i*12+d)[0]+bias==struct.unpack_from('<I',table,i*12+d)[0]+bias
manifest={'source_sha256':sha(p.b),'candidate_sha256':sha(b),'added_records':added,'old_records':old_count,'new_records':new_count,'preserved_legacy_records_byte_exact':True,'new_table_va':hex(new_va),'new_relocation_count':len(new_relocs),'changes':changes,'scope':'Internal GPU name correction, including GP107 records; display INF eligibility is separate.'}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print(json.dumps(manifest,indent=2))
