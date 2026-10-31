#!/usr/bin/env python3
"""Compile the three October 31 adapters and compare their exact installed bytes."""
import argparse,hashlib,json,struct,subprocess
from pathlib import Path

def offset(b,va):
    pe=struct.unpack_from('<I',b,60)[0];op=pe+24
    rva=va-struct.unpack_from('<I',b,op+28)[0]
    count=struct.unpack_from('<H',b,pe+6)[0]
    table=op+struct.unpack_from('<H',b,pe+20)[0]
    for i in range(count):
        vs,rv,sz,raw=struct.unpack_from('<4I',b,table+40*i+8)
        if rv<=rva<rv+sz:return raw+rva-rv
    raise ValueError('Address is not backed by file data')

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--package',type=Path,required=True)
    ap.add_argument('--out',type=Path,required=True)
    a=ap.parse_args();root=Path(__file__).resolve().parent/'sources/october31'
    if a.out.exists():raise ValueError('Output directory already exists')
    a.out.mkdir(parents=True)
    manifest=json.loads((root/'stock-manifest.json').read_text());results=[]
    for row in json.loads((root/'blocks.json').read_text()):
        b=(a.package/row['target']).read_bytes()
        if hashlib.sha256(b).hexdigest()!=manifest['final_package'][row['target']]:raise ValueError('Target hash differs')
        name=Path(row['source']).stem;obj=a.out/(name+'.o');elf=a.out/(name+'.elf');blob=a.out/(name+'.bin');ld=a.out/(name+'.ld')
        ld.write_text(''.join(k+' = '+hex(v)+';\n'for k,v in row['symbols'].items())+'SECTIONS { . = '+hex(row['va'])+'; .text : { *(.text*) } /DISCARD/ : { *(.note*) *(.comment*) *(.eh_frame*) } }\n')
        for cmd in [['as','--32',str(root/row['source']),'-o',str(obj)],['ld','-m','elf_i386','-T',str(ld),str(obj),'-o',str(elf)],['objcopy','-O','binary','-j','.text',str(elf),str(blob)]]:
            subprocess.run(cmd,check=True)
        if subprocess.check_output(['nm','-u',str(elf)]).strip():raise ValueError('Unresolved symbols')
        data=blob.read_bytes();o=offset(b,row['va'])
        if len(data)!=row['size']or data!=b[o:o+len(data)]:raise ValueError('Compiled block differs: '+name)
        results.append(dict(source=row['source'],bytes=len(data),matches=True))
    print(json.dumps(results,indent=2))

if __name__=='__main__':main()
