"""Apply or verify explicit display-package build identification metadata.

This labels a custom package; it does not claim the vendor code was recompiled.
Historical copyright, firmware identity, PDB identity and other component
versions are preserved. The manifest records each reversible metadata edit.
"""
import calendar
import datetime
import hashlib
import struct


def timestamp(date):
    return int(datetime.datetime.combine(date, datetime.time(12), datetime.timezone.utc).timestamp())


def apply(data, date, checksum):
    image = bytearray(data)
    pe = struct.unpack_from('<I', image, 60)[0]
    assert image[:2] == b'MZ' and image[pe:pe+4] == b'PE\0\0'
    opt = pe + 24
    assert struct.unpack_from('<H', image, opt)[0] == 0x10b
    edits = []

    def replace(offset, after):
        before = bytes(image[offset:offset+len(after)])
        if before != after:
            edits.append({'offset': offset, 'before': before.hex(), 'after': after.hex()})
            image[offset:offset+len(after)] = after

    replace(pe+8, struct.pack('<I', timestamp(date)))
    # This custom metadata invalidates the old file signature, as do code edits.
    replace(opt+96+4*8, bytes(8))
    old = b'Jul 10 2016'
    new = (calendar.month_abbr[date.month] + f' {date.day:2d} {date.year:04d}').encode('ascii')
    assert len(old) == len(new)
    for encoding in ['ascii', 'utf-16le']:
        before = old.decode().encode(encoding)
        after = new.decode().encode(encoding)
        pos = 0
        while (pos := image.find(before, pos)) != -1:
            replace(pos, after)
            pos += len(after)
    replace(opt+64, struct.pack('<I', checksum(image, opt+64)))
    return bytes(image), {'base_sha256': hashlib.sha256(data).hexdigest(), 'edits': edits}


def restore(data, spec):
    image = bytearray(data)
    for edit in reversed(spec['edits']):
        offset = edit['offset']
        before, after = bytes.fromhex(edit['before']), bytes.fromhex(edit['after'])
        assert len(before) == len(after) and image[offset:offset+len(after)] == after
        image[offset:offset+len(before)] = before
    assert hashlib.sha256(image).hexdigest() == spec['base_sha256']
    return bytes(image)


def verify(data, date, spec, checksum):
    original = restore(data, spec)
    rebuilt, expected = apply(original, date, checksum)
    assert rebuilt == data and expected == spec
    return True
