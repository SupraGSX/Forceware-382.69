#!/usr/bin/env python3
"""Compile the PMU corrections and compare their exact instruction/hook bytes."""
import argparse,json,struct,subprocess
from pathlib import Path
from rebuild import require,pe_read

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--miniport',type=Path,required=True);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
 src=Path(__file__).resolve().parent/'sources/pmu';out=a.out.resolve();require(not out.exists(),'Output exists');out.mkdir(parents=True)
 data=a.miniport.read_bytes();pe=struct.unpack_from('<I',data,60)[0];base=struct.unpack_from('<I',data,pe+24+28)[0]
 spec=json.loads((src/'hooks.json').read_text())
 def run(cmd):
  with (out/'compiler.log').open('a') as f:subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,check=True)
 for name in ['receive-owner','port-hooks']:
  run(['as','--32',str(src/(name+'.s')),'-o',str(out/(name+'.o'))])
 flags=['-m32','-march=i686','-Os','-ffreestanding','-fno-pic','-fno-pie','-fno-stack-protector','-fno-asynchronous-unwind-tables','-fno-builtin','-fno-jump-tables','-mno-sse','-mno-mmx','-msoft-float','-mpreferred-stack-boundary=2']
 run(['gcc',*flags,'-c',str(src/'port-lock.c'),'-o',str(out/'port-lock.o')])
 for name,objs,rva,n in [('receive',['receive-owner'],spec['receive_code_rva'],spec['receive_bytes']),('port',['port-hooks','port-lock'],spec['port_code_rva'],spec['port_bytes'])]:
  elf=out/(name+'.elf');raw=out/(name+'.bin')
  run(['ld','-m','elf_i386','-T',str(src/(name+'.ld')),*[str(out/(v+'.o')) for v in objs],'-o',str(elf)])
  require('There are no relocations' in subprocess.check_output(['readelf','-r',str(elf)],text=True),'Unexpected correction relocations')
  require(not subprocess.check_output(['nm','-u',str(elf)],text=True).strip(),'Unresolved correction symbol')
  run(['objcopy','-O','binary',str(elf),str(raw)])
  b=raw.read_bytes();require(len(b)==n and pe_read(data,base+int(rva,16),n)==b,'Compiled '+name+' differs')
 for group in ['receive','port']:
  for hook in spec[group]:
   new=bytes.fromhex(hook['after']);require(pe_read(data,base+int(hook['rva'],16),len(new))==new,'Correction hook differs')
 require(pe_read(data,base+int(spec['port_state_rva'],16),64)==b'FWPL133\0'+bytes(56),'Initial lock state differs')
 require(b'FWDBG132' not in data and b'FWDBG129' not in data,'Unexpected diagnostic recorder')
 result={'receive_bytes':spec['receive_bytes'],'port_bytes':spec['port_bytes'],'hooks':10,'source_matches':True,'diagnostic_recorder':False}
 (out/'verification.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))

if __name__=='__main__':main()
