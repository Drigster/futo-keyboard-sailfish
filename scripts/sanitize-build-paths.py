#!/usr/bin/env python3
"""Remove host build roots from packaged binaries without changing ELF offsets."""

import pathlib
import re
import sys


BUILD_ROOTS = (
    re.compile(rb"/mnt/[a-zA-Z]/[Uu]sers/[^/\x00\s]+/[^\x00\s]*?futo-keyboard-sailfish"),
    re.compile(rb"[a-zA-Z]:[\\/][Uu]sers[\\/][^\x00\s]*?futo-keyboard-sailfish"),
    re.compile(rb"/home/[^/\x00\s]+/[^\x00\s]*?futo-keyboard-sailfish"),
    re.compile(rb"/+home/build/futo"),
)
HOST_PATHS = (
    re.compile(rb"/mnt/[a-zA-Z]/[Uu]sers/"),
    re.compile(rb"[a-zA-Z]:[\\/][Uu]sers[\\/]"),
    re.compile(rb"/+home/build/"),
    re.compile(rb"/home/[^/\x00\s]+/(?:Documents|projects|work)/"),
)


def sanitize(path):
    data = bytearray(path.read_bytes())
    replacements = 0
    for pattern in BUILD_ROOTS:
        matches = list(pattern.finditer(data))
        for match in reversed(matches):
            replacement = b"source" + b"_" * (len(match.group()) - len(b"source"))
            data[match.start():match.end()] = replacement
            replacements += 1

    for pattern in HOST_PATHS:
        if pattern.search(data):
            raise ValueError(f"host build path remains in {path.name}")

    if replacements:
        path.write_bytes(data)
    print(f"{path.name}: {replacements} build paths removed")


def main():
    try:
        for name in sys.argv[1:]:
            sanitize(pathlib.Path(name))
    except (OSError, ValueError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
