#!/usr/bin/env python3
"""Compile the October 12 display-audio routines and verify all inserted hooks.

Requires GCC (-m32 freestanding) and GNU binutils. Does not install a driver.
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
    cli.add_argument('--out', required=True, type=Path)
    args = cli.parse_args()
    out = args.out.resolve()
    require(not out.exists(), 'Output exists')
    out.mkdir(parents=True)
    source = Path(__file__).resolve().parent / 'sources/display-audio'
    hooks = json.loads((source / 'hooks.json').read_text())
    flags = ['-m32', '-Os', '-fno-pie', '-fno-pic', '-ffreestanding',
             '-fno-stack-protector', '-fno-asynchronous-unwind-tables',
             '-fno-jump-tables', '-fno-tree-switch-conversion', '-mno-sse',
             '-mno-mmx', '-mpreferred-stack-boundary=2', '-Wall', '-Wextra']
    result = []

    def run(cmd):
        with (out / 'compiler.log').open('a') as log:
            subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, check=True)

    def compare(module, va, code):
        require(pe_read(module, va, len(code)) == code, 'Source or hook mismatch at ' + hex(va))

    mini = (args.package / 'Display.Driver/nv4_mini.sys').read_bytes()
    obj = out / 'legacy-edid-length.o'
    elf = out / 'legacy-edid-length.elf'
    binary = out / 'legacy-edid-length.bin'
    run(['as', '--32', str(source / 'legacy-edid-length.s'), '-o', str(obj)])
    run(['ld', '-m', 'elf_i386', '--emit-relocs', '-Ttext=0xdc8000',
         '--defsym=native_copy=0x4649c0', str(obj), '-o', str(elf)])
    run(['objcopy', '-O', 'binary', '-j', '.text', str(elf), str(binary)])
    compare(mini, 0xdc8000, binary.read_bytes())
    compare(mini, 0x592d50, b'\xe8' + struct.pack('<i', 0xdc8000 - 0x592d55))
    require('R_386_32 ' not in subprocess.check_output(['readelf', '-r', str(elf)], text=True), 'Absolute relocation')
    result.append({'source': 'legacy-edid-length.s', 'sha256': digest(binary.read_bytes())})
    for kind, module_name, names in [
        ('mini', 'nv4_mini.sys', ['hdmi-hooks.s', 'audio-mini.s', 'edid-blocks.c', 'audio-mini.c', 'hdmi-policy.c']),
        ('disp', 'nv4_disp.dll', ['audio-disp.s', 'audio-disp.c'])
    ]:
        module = (args.package / 'Display.Driver' / module_name).read_bytes()
        spec = hooks[module_name]
        objects = []
        for name in names:
            obj = out / (name + '.o')
            objects.append(str(obj))
            if name.endswith('.s'):
                run(['as', '--32', str(source / name), '-o', str(obj)])
            else:
                run(['gcc', *flags, '-DHDMI_MAX=594000U', '-c', str(source / name), '-o', str(obj)])
        linker = out / (kind + '.ld')
        linker.write_text((source / (kind + '.ld')).read_text().replace('STUB', spec['stub_va']))
        elf = out / (kind + '.elf')
        run(['ld', '-m', 'elf_i386', '--emit-relocs', '-T', str(linker), *objects, '-o', str(elf)])
        relocs = subprocess.check_output(['readelf', '-r', str(elf)], text=True)
        require('R_386_32 ' not in relocs and 'R_386_GOT' not in relocs, 'Unexpected absolute/GOT relocation')
        binary = out / (kind + '.bin')
        run(['objcopy', '-O', 'binary', '-j', '.text', str(elf), str(binary)])
        code = binary.read_bytes()
        require(len(code) == spec['stub_size'], 'Compiled block size')
        compare(module, int(spec['stub_va'], 16), code)
        for edit in spec['edits']:
            compare(module, int(edit['va'], 16), bytes.fromhex(edit['after']))
        result.append({'source': kind, 'bytes': len(code), 'sha256': digest(code), 'hooks': len(spec['edits'])})
    (out / 'verification.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'source_and_hooks_match': True, 'blocks': result}, indent=2))


if __name__ == '__main__':
    main()
