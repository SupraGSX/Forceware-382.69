#!/usr/bin/env python3
"""Replay the documented Forceware 382.69 patches against exact vendor inputs.

Uses Python 3 and 7-Zip. Does not install a driver or run a vendor installer.
The manifest contains file patches; firmware is read from the supplied donors.
"""
import argparse
import array
import datetime
import importlib.util
import os
import re
import hashlib
import json
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import zlib


def digest(data):
    return hashlib.sha256(data).hexdigest()


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def child(root, name):
    p = (root / name).resolve()
    require(p.is_relative_to(root.resolve()), 'Path outside selected directory')
    return p


def check(data, expected, label):
    require(digest(data) == expected, 'Input/output hash mismatch: ' + label)
    return data


def pe_read(data, va, size):
    pe = struct.unpack_from('<I', data, 60)[0]
    op = pe + 24
    require(data[pe:pe+4] == b'PE\0\0' and struct.unpack_from('<H', data, op)[0] == 0x10b, 'Expected PE32')
    rva = va - struct.unpack_from('<I', data, op+28)[0]
    st = op + struct.unpack_from('<H', data, pe+20)[0]
    for i in range(struct.unpack_from('<H', data, pe+6)[0]):
        vs, rv, rawsize, raw = struct.unpack_from('<IIII', data, st+i*40+8)
        if rv <= rva and rva+size <= rv+max(vs, rawsize):
            delta = rva-rv
            n = min(size, max(0, rawsize-delta))
            require(raw+delta+n <= len(data) if n else True, 'Invalid raw section bounds')
            return data[raw+delta:raw+delta+n] + bytes(size-n)
    raise RuntimeError('Donor virtual-address range not mapped')


def firmware(data, spec):
    if 'descriptor_va' in spec:
        length, pointer, compressed = struct.unpack('<III', pe_read(data, spec['descriptor_va'], 12))
        require(length == spec['size'] and compressed in (0, 1), 'Unexpected firmware descriptor')
        if compressed:
            # The pinned manifest records the consumed compressed stream length.
            raw = pe_read(data, pointer, spec['compressed_size'])
            decoder = zlib.decompressobj(-15)
            result = decoder.decompress(raw, length+1)
            require(decoder.eof and not decoder.unused_data and not decoder.unconsumed_tail, 'Invalid firmware stream')
        else:
            result = pe_read(data, pointer, length)
    else:
        result = pe_read(data, spec['source_va'], spec['size'])
    require(len(result) == spec['size'], 'Firmware length mismatch')
    return check(result, spec['sha256'], spec['label'])


def checksum(data, offset):
    b = bytearray(data)
    b[offset:offset+4] = bytes(4)
    if len(b) & 1:
        b.append(0)
    words = array.array('H', b)
    if sys.byteorder != 'little':
        words.byteswap()
    value = sum(words)
    while value >> 16:
        value = (value & 65535) + (value >> 16)
    return (value + len(data)) & 0xffffffff


def run7z(executable, args, log, cwd=None):
    with log.open('w') as f:
        subprocess.run([executable, *args], cwd=cwd, stdout=f, stderr=subprocess.STDOUT, check=True)


def inventory(root):
    return {str(p.relative_to(root)): digest(p.read_bytes()) for p in sorted(root.rglob('*')) if p.is_file()}


def repack(executable, source, tree, destination, archive, log, outer=False, release_title="Forceware 382.69", build_date=None):
    epoch = int(datetime.datetime.combine(build_date, datetime.time(12), datetime.timezone.utc).timestamp())
    for item in [*tree.rglob('*'), tree]:
        os.utime(item, (epoch, epoch))
    run7z(executable, ['a', '-t7z', '-m0=lzma2', '-mx=5', '-md=32m', '-mmt=4', str(archive), '.'], log, tree)
    start = source.find(b';!@Install@!')
    end = source.find(b"7z\xbc\xaf\x27\x1c", start)
    require(start == 897536 and start < end < start+4096, 'Unexpected SFX layout')
    config = source[start:end].decode('utf-8')
    if outer:
        config = config.replace('DisplayDriver\\\\368.81\\\\WinXP\\\\International', 'Forceware 382.69')
        config = config.replace('NVIDIA Display Driver v368.81 - International Package', 'Forceware 382.69 - Custom XP 32-bit Driver')
        config = config.replace('NVIDIA Display Driver v368.81 - International', 'Forceware 382.69')
        config = config.replace('Forceware 382.69', release_title)
    b = bytearray(source[:start] + config.encode('utf-8') + archive.read_bytes())
    op = struct.unpack_from('<I', b, 60)[0]+24
    struct.pack_into('<I', b, op-16, epoch)
    struct.pack_into('<II', b, op+96+32, 0, 0)
    struct.pack_into('<I', b, op+64, checksum(b, op+64))
    destination.write_bytes(b)
    os.utime(destination, (epoch, epoch))


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--stock', required=True, type=Path, help='Stock 368.81 XP32 international EXE')
    cli.add_argument('--quadro', required=True, type=Path, help='Expanded 376.84 Win7 x86 nvlddmkm.sys')
    cli.add_argument('--geforce', required=True, type=Path, help='Expanded 378.78 Win7 x86 nvlddmkm.sys')
    cli.add_argument('--out', required=True, type=Path, help='A new output directory')
    cli.add_argument('--sevenzip', default='7z')
    args = cli.parse_args()
    here = Path(__file__).resolve().parent
    manifest = json.loads((here/'patches.json').read_text())
    build_date = datetime.datetime.strptime(manifest['build_date'], '%m/%d/%Y').date()
    release_title = manifest['release_title']
    variant = manifest.get('release_variant', '')
    require(variant in ['', 'GP107 Test 2 (Experimental)'], 'Unknown release variant')
    expected_title = 'Forceware 382.69 ('+str(build_date.month)+'-'+str(build_date.day)+'-'+str(build_date.year)+')'
    if variant:
        expected_title = 'Forceware 382.69 - '+variant
    require(release_title == expected_title, 'Release title/date mismatch')
    inf = (here/'templates/package/Display.Driver/nv4_dispi.inf').read_text(encoding='cp1252')
    match = re.search(r'^DriverVer\s*=\s*([^,]+),\s*10\.18\.13\.8269\s*$', inf, re.M)
    require(match is not None and match.group(1) == manifest['build_date'], 'Display INF date/build date mismatch')
    loader = importlib.util.spec_from_file_location('build_date', here/'sources/build-date.py')
    metadata = importlib.util.module_from_spec(loader)
    loader.loader.exec_module(metadata)
    for path in ['package/Display.Driver/DisplayDriver.nvi', 'cpl/DisplayControlPanel.nvi']:
        text = (here/'templates'/path).read_text()
        require('timestamp="'+build_date.isoformat()+'T12:00:00"' in text, 'Installer component date mismatch: '+path)
    stock = check(args.stock.read_bytes(), manifest['inputs']['stock'], 'stock installer')
    donors = {k: check(getattr(args, k).read_bytes(), manifest['inputs'][k], k+' donor') for k in ['quadro', 'geforce']}
    root = args.out.resolve()
    require(not root.exists(), 'Output directory already exists')
    require(shutil.which(args.sevenzip) is not None, '7-Zip is required')
    root.mkdir(parents=True)
    scratch = root/'work'; scratch.mkdir()
    upstream = scratch/'stock'; cpl_original = scratch/'cpl-original'
    run7z(args.sevenzip, ['x', '-y', '-o'+str(upstream), str(args.stock.resolve())], scratch/'extract-stock.log')
    run7z(args.sevenzip, ['x', '-y', '-o'+str(cpl_original), str(upstream/'Display.Driver/NvCplSetupInt.exe')], scratch/'extract-cpl.log')
    package = root/'Forceware 382.69'; cpl = scratch/'cpl'; package.mkdir(); cpl.mkdir()
    expanded = {}
    for record in manifest['files']:
        targetroot = package if record['tree'] == 'package' else cpl
        sourceroot = upstream if record['tree'] == 'package' else cpl_original
        target = child(targetroot, record['path']); target.parent.mkdir(parents=True, exist_ok=True)
        if record['kind'] == 'generated':
            continue
        source = b''
        if record.get('source'):
            src = child(sourceroot, record['source'])
            if record.get('expand'):
                if record['source'] not in expanded:
                    folder = scratch/('expand-'+str(len(expanded)))
                    run7z(args.sevenzip, ['x', '-y', '-o'+str(folder), str(src)], scratch/('expand-'+str(len(expanded))+'.log'))
                    files = [p for p in folder.rglob('*') if p.is_file()]
                    require(len(files) == 1, 'Expected one CAB member')
                    expanded[record['source']] = files[0].read_bytes()
                source = expanded[record['source']]
            else:
                source = src.read_bytes()
            check(source, record['source_sha256'], record['path']+' source')
        if record['kind'] == 'template':
            result = child(here/'templates', record['template']).read_bytes()
        elif record['kind'] == 'copy':
            result = source
        else:
            require(record['kind'] == 'patch', 'Unknown record kind')
            result = bytearray(source[:record['size']])
            result.extend(bytes(record['size']-len(result)))
            for spec in record.get('firmware', []):
                blob = firmware(donors[spec['donor']], spec)
                off = spec['target_offset']; require(off+len(blob) <= len(result), 'Firmware output bounds')
                result[off:off+len(blob)] = blob
            for edit in record['edits']:
                off = edit['offset']; before = bytes.fromhex(edit['before']); after = bytes.fromhex(edit['after'])
                require(len(before) == len(after) and result[off:off+len(before)] == before, 'Patch byte guard: '+record['path'])
                result[off:off+len(before)] = after
        check(result, record['sha256'], record['path'])
        if 'build_metadata' in record:
            metadata.verify(result, build_date, record['build_metadata'], checksum)
        target.write_bytes(result)
    expected_cpl = {r['path']: r['sha256'] for r in manifest['files'] if r['tree'] == 'cpl'}
    require(inventory(cpl) == expected_cpl, 'Control Panel payload mismatch')
    repack(args.sevenzip, (upstream/'Display.Driver/NvCplSetupInt.exe').read_bytes(), cpl,
           package/'Display.Driver/NvCplSetupInt.exe', scratch/'cpl.7z', scratch/'pack-cpl.log', build_date=build_date)
    inner_check = scratch/'cpl-check'
    run7z(args.sevenzip, ['x', '-y', '-o'+str(inner_check), str(package/'Display.Driver/NvCplSetupInt.exe')], scratch/'check-cpl.log')
    require(inventory(inner_check) == expected_cpl, 'Repacked Control Panel mismatch')
    files = inventory(package)
    (package/'SHA256SUMS.txt').write_text(''.join(h+'  '+p+'\n' for p, h in sorted(files.items())))
    expected = {r['path']: r['sha256'] for r in manifest['files'] if r['tree'] == 'package' and r['kind'] != 'generated'}
    actual = inventory(package)
    require({k: v for k, v in actual.items() if k in expected} == expected, 'Final package payload mismatch')
    require(set(actual) == {r['path'] for r in manifest['files'] if r['tree'] == 'package'}, 'Unexpected package files')
    exe = root/(release_title+'.exe')
    repack(args.sevenzip, stock, package, exe, scratch/'package.7z', scratch/'pack-outer.log', outer=True, release_title=release_title, build_date=build_date)
    outer_check = scratch/'package-check'
    run7z(args.sevenzip, ['x', '-y', '-o'+str(outer_check), str(exe)], scratch/'check-outer.log')
    require(inventory(outer_check) == actual, 'Final EXE extraction mismatch')
    report = {'build_date': manifest['build_date'], 'release_title': release_title, 'package_files': len(actual), 'exact_release_file_hash_matches': len(expected),
              'exact_control_panel_file_hash_matches': len(expected_cpl),
              'regenerated_files': ['Display.Driver/NvCplSetupInt.exe', 'SHA256SUMS.txt'],
              'exe_sha256': digest(exe.read_bytes()), 'exe_bytes': exe.stat().st_size,
              'build_metadata_files_verified': sum('build_metadata' in r for r in manifest['files']),
              'all_extraction_checks_pass': True, 'runtime_test_performed': False}
    (root/'rebuild-result.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
