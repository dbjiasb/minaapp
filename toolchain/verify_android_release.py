#!/usr/bin/env python3
"""Reject release AABs with unexpected ABIs, broad media access or 4 KB ELF loads."""

import struct
import sys
import zipfile


def verify(path):
    errors = []
    count = 0
    with zipfile.ZipFile(path) as bundle:
        libraries = [n for n in bundle.namelist() if '/lib/' in n and n.endswith('.so')]
        if not libraries:
            errors.append('No native libraries found')
        for name in libraries:
            abi = name.split('/lib/', 1)[1].split('/')[0]
            if abi != 'arm64-v8a':
                errors.append(f'{name}: unexpected ABI (release supports arm64-v8a)')
            data = bundle.read(name)
            if data[:5] != b'\x7fELF\x02' or data[5] != 1:
                errors.append(f'{name}: expected little-endian 64-bit ELF')
                continue
            offset = struct.unpack_from('<Q', data, 32)[0]
            size, number = struct.unpack_from('<HH', data, 54)
            loads = 0
            for index in range(number):
                header = offset + index * size
                if struct.unpack_from('<I', data, header)[0] != 1:
                    continue
                loads += 1
                file_offset, address = struct.unpack_from('<QQ', data, header + 8)
                alignment = struct.unpack_from('<Q', data, header + 48)[0]
                if alignment < 16384 or alignment & (alignment - 1) or (address - file_offset) % 16384:
                    errors.append(f'{name}: LOAD segment {index} is not 16 KB aligned')
            if not loads:
                errors.append(f'{name}: no LOAD segments')
            count += 1
        manifests = [n for n in bundle.namelist() if n.endswith('/manifest/AndroidManifest.xml')]
        if not manifests:
            errors.append('No bundle manifests found')
        for name in manifests:
            manifest = bundle.read(name)
            # AAB protobuf XML stores attribute values as UTF-8 strings.
            for permission in ('READ_MEDIA_VIDEO', 'READ_MEDIA_IMAGES', 'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE'):
                if ('android.permission.' + permission).encode() in manifest:
                    errors.append(f'{name}: contains {permission}')
    if errors:
        raise SystemExit('Release verification FAILED:\n' + '\n'.join(errors))
    print(f'Release verification passed: {count} ARM64 libraries, all LOAD segments >=16 KB; no broad media/storage permissions.')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit(f'Usage: {sys.argv[0]} app-release.aab')
    verify(sys.argv[1])
