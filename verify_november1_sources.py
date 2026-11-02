#!/usr/bin/env python3
"""Compile the November 1 runtime adapters and compare their exact installed bytes."""
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
    a=ap.parse_args();root=Path(__file__).resolve().parent/'sources/november1'
    if a.out.exists():raise ValueError('Output directory already exists')
    a.out.mkdir(parents=True)
    manifest=json.loads((root/'stock-manifest.json').read_text());results=[]
    for row in json.loads((root/'blocks.json').read_text()):
        target='Display.Driver/nv4_mini.sys'
        b=(a.package/target).read_bytes()
        if hashlib.sha256(b).hexdigest()!=manifest['final_package'][target]:raise ValueError('Target hash differs')
        name=row['name'];elf=a.out/(name+'.elf');blob=a.out/(name+'.bin');ld=a.out/(name+'.ld')
        ld.write_text(''.join(k+' = '+hex(v)+';\n'for k,v in row['symbols'].items())+'SECTIONS { . = '+hex(row['va'])+'; .text : { *(.text*) *(.rodata*) } /DISCARD/ : { *(.note*) *(.comment*) *(.eh_frame*) } }\n')
        objects=[]
        for index,source in enumerate(row['sources']):
            obj=a.out/(name+'-'+str(index)+'.o');objects.append(str(obj))
            cmd=['gcc',*row['cflags'],'-c',str(root/source),'-o',str(obj)]if source.endswith('.c')else ['as','--32',str(root/source),'-o',str(obj)]
            subprocess.run(cmd,check=True)
        subprocess.run(['ld','-m','elf_i386','-T',str(ld),*objects,'-o',str(elf)],check=True)
        subprocess.run(['objcopy','-O','binary','-j','.text',str(elf),str(blob)],check=True)
        if subprocess.check_output(['nm','-u',str(elf)]).strip():raise ValueError('Unresolved symbols')
        data=blob.read_bytes();o=offset(b,row['va'])
        if len(data)!=row['size']or data!=b[o:o+len(data)]:raise ValueError('Compiled block differs: '+name)
        results.append(dict(sources=row['sources'],bytes=len(data),matches=True))
    print(json.dumps(results,indent=2))

if __name__=='__main__':main()
