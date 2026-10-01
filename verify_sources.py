#!/usr/bin/env python3
"""Compile independent stubs and compare with the rebuilt driver instruction bytes.

Requires GNU as/ld/objcopy and GCC with -m32 freestanding compilation support.
This verifies instruction bytes, not a new hardware test.
"""
import argparse
import json
from pathlib import Path
import struct
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
        ('display-root.s','nv4_disp.dll',0x29fdc5,[], '_start'),
        ('sec2-bootdesc.S','nv4_mini.sys',0xd06920,['--defsym','original_copy=0x470d10'],'sec2_bootdesc_copy'),
        ('dp-api-rate.s','nv4_disp.dll',0x356600,[], '_start'),
        ('dp-full-training.s','nv4_mini.sys',0x89b86a,[], '_start'),
        ('dp-extended-caps.s','nv4_mini.sys',0xd06a00,[], '_start'),
        ('dp-depth-select.s','nv4_disp.dll',0x356680,[], '_start'),
        ('dp-capacity-depth.s','nv4_mini.sys',0xd06ae0,[], '_start'),
        ('hdmi-vendor-summary.s','nv4_mini.sys',0x8742b0,[], '_start'),
        ('topology-predicate.s','nvWsS.dll',0x10257fe7,[], '_start'),
    ]
    for name, module, va, extra, entry in cases:
        obj=out/(name+'.o'); target=out/(name+'.bin')
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
    (out/'verification.json').write_text(json.dumps(records,indent=2)+'\n')
    print(json.dumps({'compiled_blocks_matching_release':len(records),'blocks':records},indent=2))


if __name__=='__main__':
    main()
