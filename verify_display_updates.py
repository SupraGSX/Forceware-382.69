#!/usr/bin/env python3
"""Compile and verify the HDMI/DisplayPort scaling and independent Control Panel pages.

Requires Python 3, GNU binutils and GCC freestanding x86 compilation support.
Run against the exact reconstructed package and expanded Control Panel tree.
"""
import argparse
import json
from pathlib import Path
import struct
import subprocess
from rebuild import pe_read, require, digest


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--package', required=True, type=Path)
    cli.add_argument('--cpl', required=True, type=Path)
    cli.add_argument('--out', required=True, type=Path)
    a = cli.parse_args()
    out = a.out.resolve()
    require(not out.exists(), 'Output exists')
    out.mkdir(parents=True)
    root = Path(__file__).resolve().parent
    src = root/'sources'
    manifest = json.loads((root/'patches.json').read_text())
    data = {}
    for tree, path in [('package','Display.Driver/nv4_mini.sys'), ('cpl','nvcpl.dll'), ('cpl','nvDispS.dll')]:
        record = next(r for r in manifest['files'] if r['tree']==tree and r['path']==path)
        b = ((a.package if tree=='package' else a.cpl)/path).read_bytes()
        require(digest(b)==record['sha256'], 'Input hash mismatch: '+path)
        data[Path(path).name] = b

    def run(cmd):
        with (out/'compiler.log').open('a') as log:
            subprocess.run(cmd, cwd=out, stdout=log, stderr=subprocess.STDOUT, check=True)

    def symbols(path):
        return {p[2]:int(p[0],16) for line in subprocess.check_output(['nm','-n',str(path)],text=True).splitlines() if len(p:=line.split())==3}

    mini=data['nv4_mini.sys']
    (out/'original.bin').write_bytes(pe_read(mini,0x873140,820))
    run(['as','--32',str(src/'hdmi-scaling/native-cap.s'),'-o','cap.o'])
    run(['gcc','-DAUTO_MAX=59400','-m32','-Os','-ffreestanding','-fno-pie','-fno-stack-protector','-fno-asynchronous-unwind-tables','-fno-unwind-tables','-c',str(src/'hdmi-scaling/selector.c'),'-o','wrapper.o'])
    run(['ld','-m','elf_i386','--emit-relocs','-Ttext','0xd69200','--defsym=native_hdmi=0x44b8d0','--defsym=native_original=0x873140','-e','output_selector','wrapper.o','cap.o','-o','scaling.elf'])
    rel=subprocess.check_output(['readelf','-r',str(out/'scaling.elf')],text=True)
    require('R_386_32 ' not in rel, 'Unexpected absolute scaling relocation')
    run(['objcopy','-O','binary','--only-section=.text','scaling.elf','scaling.bin'])
    code=(out/'scaling.bin').read_bytes();sy=symbols(out/'scaling.elf')
    require(pe_read(mini,0xd69200,len(code))==code, 'HDMI scaling source differs')
    run(['gcc','-m32','-Os','-ffreestanding','-fno-pie','-fno-stack-protector','-fno-jump-tables','-fno-tree-switch-conversion','-fno-asynchronous-unwind-tables','-fno-unwind-tables','-c',str(src/'dp-scaling/selector.c'),'-o','dp-scaling.o'])
    run(['ld','-m','elf_i386','--emit-relocs','-Ttext','0xd69d40','--defsym=previous_selector=0xd694c6','--defsym=native_cap=0xd699ce','-e','dp_output_selector','dp-scaling.o','-o','dp-scaling.elf'])
    rel=subprocess.check_output(['readelf','-r',str(out/'dp-scaling.elf')],text=True)
    require('R_386_32 ' not in rel,'Unexpected absolute DP scaling relocation')
    run(['objcopy','-O','binary','--only-section=.text','dp-scaling.elf','dp-scaling.bin'])
    dpcode=(out/'dp-scaling.bin').read_bytes();dpsy=symbols(out/'dp-scaling.elf')
    require(len(dpcode)==1937 and pe_read(mini,0xd69d40,len(dpcode))==dpcode,'DP scaling source differs')
    for site in [0x45b208,0xc748b0]:
        require(pe_read(mini,site,5)==b'\xe8'+struct.pack('<i',dpsy['dp_output_selector']-site-5),'Timing caller mismatch')

    run(['as','--32',str(src/'control-panel/sidebar.s'),'-o','sidebar.o'])
    run(['ld','-m','elf_i386','--emit-relocs','-Ttext','0x108c3000','-e','create_overscan','sidebar.o','-o','sidebar.elf'])
    run(['objcopy','-O','binary','--only-section=.text','sidebar.elf','sidebar.bin'])
    ui=data['nvDispS.dll'];sy=symbols(out/'sidebar.elf');codeui=bytearray((out/'sidebar.bin').read_bytes());vt=sy['overscan_vtable']
    o=vt-0x108c3000-4;codeui[o:o+76]=pe_read(ui,0x1024cd88,76)
    struct.pack_into('<I',codeui,vt-0x108c3000+24,sy['page_info'])
    require(pe_read(ui,0x108c3000,len(codeui))==codeui, 'Control Panel source differs')
    for site in [0x10056bf8,0x10056c39,0x10056c77,0x10056cc8,0x10056d40,0x1005ac89]:
        require(pe_read(ui,site,5)==b'\xe8'+struct.pack('<i',sy['route_panel']-site-5), 'Page dispatch mismatch')
    require(pe_read(ui,0x102e1e8c,4)==struct.pack('<I',sy['create_overscan']), 'Factory mismatch')
    require(pe_read(ui,0x1024cda4,4)==struct.pack('<I',sy['page_info']), 'Page-info mismatch')
    pe=struct.unpack_from('<I',ui,60)[0];op=pe+24
    rr,sz=struct.unpack_from('<II',ui,op+96+5*8);rb=pe_read(ui,0x10000000+rr,sz);relocs=set();i=0
    while i<len(rb):
        page,n=struct.unpack_from('<II',rb,i);require(n>=8 and n%4==0 and i+n<=len(rb),'Malformed relocation block')
        for j in range(i+8,i+n,2):
            v=struct.unpack_from('<H',rb,j)[0]
            if v>>12:
                require(v>>12==3 and page+(v&4095) not in relocs,'Unexpected or duplicate relocation')
                relocs.add(page+(v&4095))
        i+=n
    require(len(relocs)==98877, 'Relocation count mismatch')
    for r in range(vt-0x10000000-4,vt-0x10000000+72,4):
        require(r in relocs,'Missing vtable relocation')
    cp=data['nvcpl.dll']
    require(pe_read(cp,0x1012bc63,5)==b'\xe9'+struct.pack('<i',0x1012b9c7-0x1012bc63-5),'Scaling admission mismatch')
    require(pe_read(cp,0x101390d6,1)==b'\0','TV exclusion mismatch')
    result={'hdmi_scaling_bytes':len(code),'dp_scaling_bytes':len(dpcode),'sidebar_bytes':len(codeui),'timing_callers':2,'page_dispatches':6,'control_panel_relocations':len(relocs),'source_matches':True}
    (out/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))


if __name__=='__main__':
    main()
