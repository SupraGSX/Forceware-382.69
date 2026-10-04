#!/usr/bin/env python3
"""Add the GP102 display root to the preceding Forceware 382.69 XP OpenGL ICD.

Requires exact input bytes. The complete stock-to-final reconstruction remains
in ../rebuild.py and ../patches.json. No NVIDIA binary is embedded in this file.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from rebuild import checksum, require

BEFORE = '65e28965f76c74ec83fb946a98d70a7ce1461eff2686537a4257793ebf4d6924'
AFTER = 'b521916052e15c6f6dfc83d574d47374afac6405244855b4ad7ad8944516e9e4'
OLD = [0x9770, 0x9570, 0x9470, 0x9270, 0x9170, 0x9070,
       0x8570, 0x8370, 0x8870, 0x8270, 0x5070]
TABLE_OFFSET = 0xf5f7a0
TABLE_VA = 0x6a45f7a0
SITES = [0x996249, 0x9963cb]

def digest(b):
    return hashlib.sha256(b).hexdigest()

def apply(original):
    require(digest(original) == BEFORE, 'Unexpected preceding Forceware ICD')
    image = bytearray(original)
    require(struct.unpack_from('<11I', image, 0xffa27c) == tuple(OLD), 'Original class list')
    require(image[TABLE_OFFSET:TABLE_OFFSET+48] == bytes(48), 'Table padding occupied')
    image[TABLE_OFFSET:TABLE_OFFSET+48] = struct.pack('<12I', *([0x9870]+OLD))
    for offset in SITES:
        require(image[offset:offset+7] == bytes.fromhex('6a0b687ca24f6a'), 'Lookup preimage')
        image[offset:offset+7] = b'\x6a\x0c\x68'+struct.pack('<I', TABLE_VA)
    require(struct.unpack_from('<I', image, 0x238)[0] == 0x39579c, 'Section size preimage')
    struct.pack_into('<I', image, 0x238, 0x3957d0)
    # Existing HIGHLOW relocations must cover both relocated table pointers.
    pe = struct.unpack_from('<I', image, 60)[0]
    op = pe+24
    require(op+64 == 0x168, 'Unexpected PE layout')
    rva, size = struct.unpack_from('<II', image, op+96+5*8)
    count, optsize = struct.unpack_from('<H', image, pe+6)[0], struct.unpack_from('<H', image, pe+20)[0]
    start = None
    for i in range(count):
        section = op+optsize+i*40
        _, rv, rawsize, raw = struct.unpack_from('<IIII', image, section+8)
        if rv <= rva and rva+size <= rv+rawsize:
            start = raw+rva-rv
    require(start is not None, 'Relocations not mapped')
    end = start+size
    relocs = set()
    while start < end:
        page, block = struct.unpack_from('<II', image, start)
        require(block >= 8 and start+block <= end, 'Invalid relocation block')
        for at in range(start+8, start+block, 2):
            v = struct.unpack_from('<H', image, at)[0]
            if v >> 12 == 3:
                relocs.add(page+(v & 0xfff))
        start += block
    require(all(o+3 in relocs for o in SITES), 'Missing table-pointer relocations')
    struct.pack_into('<I', image, op+64, checksum(image, op+64))
    require(digest(image) == AFTER, 'Unexpected output')
    return bytes(image)

def verify(final):
    require(digest(final) == AFTER, 'Unexpected patched ICD')
    original = bytearray(final)
    original[TABLE_OFFSET:TABLE_OFFSET+48] = bytes(48)
    for offset in SITES:
        original[offset:offset+7] = bytes.fromhex('6a0b687ca24f6a')
    struct.pack_into('<I', original, 0x238, 0x39579c)
    struct.pack_into('<I', original, 0x168, checksum(original, 0x168))
    require(apply(original) == final, 'Independent reconstruction differs')
    return {'sha256': AFTER, 'original_classes_preserved': 11,
            'new_class': '0x9870', 'creation_and_teardown': True,
            'existing_relocations_verified': True, 'independent_recipe_matches': True}

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--input', type=Path)
    p.add_argument('--output', type=Path)
    p.add_argument('--verify', type=Path)
    a = p.parse_args()
    if a.verify:
        require(not a.input and not a.output, 'Choose verification or patching')
        print(json.dumps(verify(a.verify.read_bytes()), indent=2))
    else:
        require(a.input is not None and a.output is not None, 'Specify --input and --output')
        require(not a.output.exists(), 'Output already exists')
        a.output.write_bytes(apply(a.input.read_bytes()))
        print(json.dumps(verify(a.output.read_bytes()), indent=2))

if __name__ == '__main__':
    main()
