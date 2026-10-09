#!/usr/bin/env python3
"""Compile independent stubs and compare with the rebuilt driver instruction bytes.

Requires GNU as/ld/objcopy and GCC with -m32 freestanding compilation support.
This verifies instruction bytes, not a new hardware test.
"""
import argparse
import importlib.util
import datetime
import json
from pathlib import Path
import struct
import sys
import subprocess
from rebuild import require, pe_read, digest


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--package', required=True, type=Path)
    cli.add_argument('--cpl', required=True, type=Path, help='Expanded rebuilt Control Panel tree')
    cli.add_argument('--out', required=True, type=Path, help='A new scratch directory')
    args = cli.parse_args()
    out = args.out.resolve(); require(not out.exists(), 'Output exists'); out.mkdir(parents=True)
    src = Path(__file__).resolve().parent/'sources'
    records = []
    def run(cmd):
        with (out/'compiler.log').open('a') as f:
            subprocess.run(cmd, stdout=f, stderr=subprocess.STDOUT, check=True)
    def compare(name, blob, module, va):
        data = module.read_bytes()
        require(pe_read(data, va, len(blob)) == blob, 'Compiled source differs: '+name)
        records.append({'source':name,'bytes':len(blob),'sha256':digest(blob),'preferred_va':hex(va)})
    cases = [
        ('dp-startup/disp-startup.s','nv4_disp.dll',0x356b00,[], 'prepare_query'),
        ('display-root.s','nv4_disp.dll',0x29fdc5,[], '_start'),
        ('sec2-bootdesc.S','nv4_mini.sys',0xd06920,['--defsym','original_copy=0x470d10'],'sec2_bootdesc_copy'),
        ('dp-api-rate.s','nv4_disp.dll',0x356600,[], '_start'),
        ('dp-full-training.s','nv4_mini.sys',0x89b86a,[], '_start'),
        ('dp-extended-caps.s','nv4_mini.sys',0xd06a00,[], '_start'),
        ('dp-depth-select.s','nv4_disp.dll',0x356680,[], '_start'),
        ('dp-capacity-depth.s','nv4_mini.sys',0xd06ae0,[], '_start'),
        ('hdmi-vendor-summary.s','nv4_mini.sys',0x8742b0,[], '_start'),
        ('hdmi-vendor-priority.s','nv4_mini.sys',0xd69100,[], '_start'),
        ('topology-predicate.s','nvWsS.dll',0x10257fe7,[], '_start'),
    ]
    for name, module, va, extra, entry in cases:
        obj=out/(name+'.o'); target=out/(name+'.bin'); obj.parent.mkdir(parents=True,exist_ok=True)
        run(['as','--32',str(src/name),'-o',str(obj)])
        run(['ld','-m','elf_i386','--oformat=binary','-Ttext',hex(va),*extra,'-e',entry,'-o',str(target),str(obj)])
        path=args.cpl/module if module=='nvWsS.dll' else args.package/'Display.Driver'/module
        compare(name,target.read_bytes(),path,va)
    flags=['-m32','-Os','-fno-pie','-fno-pic','-ffreestanding','-fno-stack-protector','-fno-asynchronous-unwind-tables','-mno-sse','-mno-mmx','-mpreferred-stack-boundary=2']
    for stem, cfile, asmfile, linker, module, va in [
        ('hdmi-policy','hdmi-policy.c','hdmi-hooks.s','hdmi-policy.ld','nv4_mini.sys',0xd06d60),
        ('hdmi-protocol',None,'hdmi-protocol.s','hdmi-protocol.ld','nv4_disp.dll',0x356700),
        ('hdmi-initial','hdmi-initial-caps.c','hdmi-initial-caps-hook.s','hdmi-initial-caps.ld','nv4_mini.sys',0xd06b20),
    ]:
        obj=out/(stem+'-asm.o');elf=out/(stem+'.elf');binary=out/(stem+'.bin')
        run(['as','--32',str(src/asmfile),'-o',str(obj)])
        objects=[str(obj)]
        if cfile:
            cobj=out/(stem+'-c.o')
            run(['gcc',*flags,'-DHDMI_MAX=594000U','-c',str(src/cfile),'-o',str(cobj)])
            objects.append(str(cobj))
        run(['ld','-m','elf_i386','-T',str(src/linker),*objects,'-o',str(elf)])
        run(['objcopy','-O','binary','-j','.text',str(elf),str(binary)])
        compare(stem,binary.read_bytes(),args.package/'Display.Driver'/module,va)
    # The 10-3-26 update adds a matched trained-link policy and HDMI recovery.
    for stem, asmfile, cfile, va, module, extra, data in [
        ('dp-startup-mini', 'dp-startup/mini-startup.s', 'dp-startup/query-policy.c', 0xd68f00, 'nv4_mini.sys', ['-fno-jump-tables','-fno-tree-switch-conversion'], False),
        ('dp-trained-mini', 'dp-trained/mini-hooks.s', 'dp-trained/dp-policy.c', 0xd073a0, 'nv4_mini.sys', ['-fno-jump-tables','-fno-tree-switch-conversion'], False),
        ('dp-trained-disp', 'dp-trained/disp-hooks.s', 'dp-trained/dp-policy.c', 0x356780, 'nv4_disp.dll', ['-fno-jump-tables','-fno-tree-switch-conversion'], False),
        ('hdmi-recovery-mini', 'hdmi-recovery/scdc-mini.s', 'hdmi-recovery/scdc-recovery.c', 0xd075c0, 'nv4_mini.sys', ['-DFAULT=0'], True),
        ('hdmi-recovery-disp', 'hdmi-recovery/scdc-disp.s', None, 0x356a00, 'nv4_disp.dll', [], True),
    ]:
        obj=out/(stem+'.o'); elf=out/(stem+'.elf'); binary=out/(stem+'.bin')
        run(['as','--32',str(src/asmfile),'-o',str(obj)])
        objects=[str(obj)]
        if cfile:
            cobj=out/(stem+'-c.o')
            run(['gcc',*flags,*extra,'-c',str(src/cfile),'-o',str(cobj)])
            objects.append(str(cobj))
        linker=out/(stem+'.ld')
        linker.write_text('SECTIONS { . = '+hex(va)+'; .text : { *(.text*) '+('*(.data*)' if data else '')+' } /DISCARD/ : { *(.note*) *(.comment*) *(.eh_frame*) } }\ndelay_native = 0x478650; best_pair = 0xd073d4;')
        run(['ld','-m','elf_i386','-T',str(linker),*objects,'-o',str(elf)])
        require('There are no relocations' in subprocess.check_output(['readelf','-r',str(elf)],text=True), 'Unexpected inserted relocations')
        run(['objcopy','-O','binary','-j','.text',str(elf),str(binary)])
        compare(stem,binary.read_bytes(),args.package/'Display.Driver'/module,va)
    gpdir=out/'gp107'; gpdir.mkdir()
    manifest=json.loads((src.parent/'patches.json').read_text())
    mini=args.package/'Display.Driver/nv4_mini.sys'; data=mini.read_bytes()
    spec=next(r for r in manifest['files'] if r['path']=='Display.Driver/nv4_mini.sys')
    require(digest(data)==spec['sha256'], 'GP107 miniport hash mismatch')
    for item in spec['firmware']:
        if item['label'].startswith('GP107 '):
            blob=data[item['target_offset']:item['target_offset']+item['size']]
            require(digest(blob)==item['sha256'], 'GP107 resource mismatch')
            (gpdir/(item['label'][6:]+'.bin')).write_bytes(blob)
    with (out/'compiler.log').open('a') as log:
        subprocess.run(['as','--32',str(src/'gp107/gp107.s'),'-o','gp107.o'],cwd=gpdir,stdout=log,stderr=subprocess.STDOUT,check=True)
        subprocess.run(['ld','-m','elf_i386','-T',str(src/'gp107/gp107.ld'),'gp107.o','-o','gp107.elf'],cwd=gpdir,stdout=log,stderr=subprocess.STDOUT,check=True)
        subprocess.run(['objcopy','-O','binary','-j','.text','gp107.elf','gp107.bin'],cwd=gpdir,stdout=log,stderr=subprocess.STDOUT,check=True)
    require('There are no relocations' in subprocess.check_output(['readelf','-r',str(gpdir/'gp107.elf')],text=True), 'Unexpected GP107 relocations')
    compare('gp107', (gpdir/'gp107.bin').read_bytes(), mini, 0xd07c40)
    for stem, va in [('graphics-boot',0xd6a4e0),('chip-limits',0xd6a9a0),('dp-gp107',0xd6aa20)]:
        with (out/'compiler.log').open('a') as log:
            for cmd in [
                ['as','--32',str(src/'gp107'/(stem+'.s')),'-o',stem+'.o'],
                ['ld','-m','elf_i386','-T',str(src/'gp107'/(stem+'.ld')),stem+'.o','-o',stem+'.elf'],
                ['objcopy','-O','binary','-j','.text',stem+'.elf',stem+'.bin']]:
                subprocess.run(cmd,cwd=gpdir,stdout=log,stderr=subprocess.STDOUT,check=True)
        require('There are no relocations' in subprocess.check_output(['readelf','-r',str(gpdir/(stem+'.elf'))],text=True),'Unexpected GP107 correction relocations')
        compare('gp107/'+stem,(gpdir/(stem+'.bin')).read_bytes(),mini,va)
    require(pe_read(data,0x448906,11)==b'\xe9'+struct.pack('<i',0xd6aa20-0x44890b)+b'\x90'*6,'GP107 DP hook mismatch')
    # Check every corrected name record, both pointers and their HIGHLOW entries.
    pe=struct.unpack_from('<I',data,60)[0];opt=pe+24;base=struct.unpack_from('<I',data,opt+28)[0]
    rv,sz=struct.unpack_from('<II',data,opt+96+5*8);raw=pe_read(data,base+rv,sz);pos=0;relocs=set()
    while pos<len(raw):
        page,n=struct.unpack_from('<II',raw,pos);require(n>=8 and pos+n<=len(raw),'Relocation bounds')
        for j in range(pos+8,pos+n,2):
            v=struct.unpack_from('<H',raw,j)[0]
            if v>>12==3:relocs.add(page+(v&4095))
        pos+=n
    table=struct.unpack('<I',pe_read(data,0x557a93,4))[0]
    require(struct.unpack('<I',pe_read(data,0x557aaf,4))[0]==650*12,'Name table length')
    for row in json.loads((src/'gpu-name-corrections.json').read_text()):
        va=table+row['index']*12;dev,sub,short,long=struct.unpack('<HHII',pe_read(data,va,12))
        require(dev==int(row['device'],16) and sub==0,'Name correction scope')
        for slot,ptr,key in [(4,short,'short'),(8,long,'long')]:
            expected=row[key].encode('ascii')+b'\0'
            require(pe_read(data,ptr,len(expected))==expected and va+slot-base in relocs,'Name correction pointer or relocation')
    loader = importlib.util.spec_from_file_location('build_date', src/'build-date.py')
    metadata = importlib.util.module_from_spec(loader); loader.loader.exec_module(metadata)
    icd_record = next(r for r in manifest['files'] if r['path']=='Display.Driver/nvoglnt.dll')
    icd = (args.package/'Display.Driver/nvoglnt.dll').read_bytes()
    require(digest(icd)==icd_record['sha256'], 'Dated ICD hash mismatch')
    from rebuild import checksum
    metadata.verify(icd, datetime.datetime.strptime(manifest['build_date'], '%m/%d/%Y').date(), icd_record['build_metadata'], checksum)
    normalized = out/'opengl-before-build-date.dll'
    normalized.write_bytes(metadata.restore(icd, icd_record['build_metadata']))
    opengl = subprocess.check_output([sys.executable, str(src/'opengl-display-class.py'), '--verify', str(normalized)], text=True)
    (out/'opengl-verification.json').write_text(opengl)
    # Minimal native link-check retraining fix: receiver lane register may reset.
    wake = out/'dp-wake-lane-restore.o'
    subprocess.run(['as','--32',str(src/'dp-wake-lane-restore.s'),'-o',str(wake)],check=True)
    wakebin = out/'dp-wake-lane-restore.bin'
    subprocess.run(['objcopy','-O','binary','-j','.text',str(wake),str(wakebin)],check=True)
    compare('dp-wake-lane-restore', wakebin.read_bytes(), args.package/'Display.Driver/nv4_disp.dll', 0x19e23)
    with (out/'display-updates.log').open('w') as log:
        subprocess.run([sys.executable,str(src.parent/'verify_display_updates.py'),'--package',str(args.package.resolve()),'--cpl',str(args.cpl.resolve()),'--out',str(out/'display-updates')],stdout=log,stderr=subprocess.STDOUT,check=True)
    (out/'verification.json').write_text(json.dumps(records,indent=2)+'\n')
    print(json.dumps({'compiled_blocks_matching_release':len(records),'blocks':records},indent=2))


if __name__=='__main__':
    main()
