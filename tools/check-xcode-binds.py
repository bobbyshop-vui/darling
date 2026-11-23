#!/usr/bin/env python3
#
# Check that every non-lazy dyld bind used by Xcode resolves inside the Darling
# prefix.
#
# This is the authoritative check for the "Xcode won't launch" class of bug:
# a `_OBJC_CLASS_$_Foo` / `_kSomeConstant` reference in a client image is bound
# eagerly, so if the framework it binds against does not export it, dyld refuses
# to load the image and the process aborts with
#
#     Symbol not found: _FOO
#     Expected in: /System/Library/Frameworks/Bar.framework/Versions/A/Bar
#
# The check reads the Mach-O bind tables directly (`llvm-objdump --macho --bind`
# and `--weak-bind`) instead of guessing from undefined symbols, and resolves
# each framework's exports *including transitive re-exports* -- which is what
# dyld does.  Without the re-export step, frameworks such as Foundation (which
# re-exports CoreFoundation) and libSystem (which re-exports a dozen
# sub-libraries) produce hundreds of false positives.
#
# Usage:
#   tools/check-xcode-binds.py                       # defaults below
#   tools/check-xcode-binds.py --prefix /path/to/prefix --xcode /path/to/Xcode.app
#   tools/check-xcode-binds.py --json out.json
#
import argparse
import collections
import json
import os
import struct
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

DEFAULT_PREFIX = "/usr/local/libexec/darling"
DEFAULT_XCODE = None            # resolved by locate_xcode() below


def locate_xcode(prefix, explicit=None):
    """Find Xcode.app inside a Darling installation.

    Note that a Darling install has two roots: the system prefix
    (e.g. /usr/local/libexec/darling, holding System/Library) and the user's
    Darling root (e.g. ~/.darling, which is what / becomes inside the guest).
    Xcode lives in the latter, under Applications/.
    """
    candidates = []
    if explicit:
        candidates.append(explicit)
    candidates.append(os.path.join(prefix, "Applications", "Xcode.app"))
    root = os.environ.get("DARLING_ROOT")
    if root:
        candidates.append(os.path.join(root, "Applications", "Xcode.app"))
    candidates.append(os.path.expanduser("~/.darling/Applications/Xcode.app"))
    # When run through sudo, HOME is /root but the Darling root belongs to the
    # invoking user.
    sudo_user = os.environ.get("SUDO_USER")
    if sudo_user:
        candidates.append(f"/home/{sudo_user}/.darling/Applications/Xcode.app")
        candidates.append(f"/Users/{sudo_user}/.darling/Applications/Xcode.app")
    # Last resort: any Darling root that has an Xcode in it.
    import glob
    candidates.extend(sorted(glob.glob("/home/*/.darling/Applications/Xcode.app")))
    for c in candidates:
        if os.path.isdir(c):
            return os.path.abspath(c)
    return os.path.abspath(candidates[0])

# Directories inside the prefix that may hold framework binaries.
FRAMEWORK_ROOTS = [
    "System/Library/Frameworks",
    "System/Library/PrivateFrameworks",
    "Library/Developer/PrivateFrameworks",
]

# System libraries that are not frameworks but are bound against by name.
SYSTEM_LIBS = {
    "libSystem": "usr/lib/libSystem.B.dylib",
    "libobjc": "usr/lib/libobjc.A.dylib",
    "libc++": "usr/lib/libc++.1.dylib",
    "libc++abi": "usr/lib/libc++abi.dylib",
    "libc": "usr/lib/libSystem.B.dylib",
    "libm": "usr/lib/libSystem.B.dylib",
    "libpthread": "usr/lib/libSystem.B.dylib",
    "libdispatch": "usr/lib/libSystem.B.dylib",
}

LC_LOAD_DYLIB = 0xc
LC_ID_DYLIB = 0xd
LC_LOAD_WEAK_DYLIB = 0x80000018
LC_REEXPORT_DYLIB = 0x8000001f

MACHO_MAGICS = (b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe",
                b"\xca\xfe\xba\xbe", b"\xca\xfe\xba\xbf")


# --------------------------------------------------------------------------- #
# Mach-O helpers
# --------------------------------------------------------------------------- #

def is_macho(path):
    try:
        if os.path.islink(path) or not os.path.isfile(path):
            return False
        with open(path, "rb") as f:
            return f.read(4) in MACHO_MAGICS
    except OSError:
        return False


def fat_slices(data):
    magic = struct.unpack(">I", data[:4])[0]
    if magic not in (0xcafebabe, 0xcafebabf):
        return [(0, 0, len(data))]
    count = struct.unpack(">I", data[4:8])[0]
    out, off = [], 8
    for _ in range(count):
        if magic == 0xcafebabe:
            _, _, offset, size, _ = struct.unpack(">iiIII", data[off:off + 20])
            off += 20
        else:
            _, _, offset, size, _, _ = struct.unpack(">iiQQII", data[off:off + 32])
            off += 32
        out.append((0, offset, size))
    return out


def dylib_commands(path):
    """Return [(cmd, install_name)] for a Mach-O file (first slice)."""
    try:
        data = open(path, "rb").read()
    except OSError:
        return []
    for _, base, _size in fat_slices(data):
        magic = struct.unpack("<I", data[base:base + 4])[0]
        if magic == 0xfeedfacf:
            hdr, end = 32, "<"
        elif magic == 0xfeedface:
            hdr, end = 28, "<"
        else:
            continue
        ncmds = struct.unpack(end + "I", data[base + 16:base + 20])[0]
        off = base + hdr
        cmds = []
        for _ in range(ncmds):
            cmd, cmdsize = struct.unpack(end + "II", data[off:off + 8])
            if cmd in (LC_LOAD_DYLIB, LC_ID_DYLIB, LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB):
                nameoff = struct.unpack(end + "I", data[off + 8:off + 12])[0]
                name = data[off + nameoff:off + cmdsize].split(b"\0")[0].decode(errors="replace")
                cmds.append((cmd, name))
            off += cmdsize
        return cmds
    return []


def exported_symbols(path):
    try:
        r = subprocess.run(["llvm-nm", "-g", "--defined-only", path],
                           capture_output=True, text=True, timeout=600)
    except (OSError, subprocess.SubprocessError):
        return set()
    out = set()
    for line in r.stdout.splitlines():
        line = line.split(" (indirect for ")[0]
        parts = line.split()
        if parts:
            out.add(parts[-1])
    return out


def bind_table(path, kind):
    """Parse a bind table.  Non-lazy rows have 7 columns, lazy rows 5, so the
    symbol/dylib are taken from the tail rather than by fixed index."""
    try:
        r = subprocess.run(["llvm-objdump", "--macho", kind, path],
                           capture_output=True, text=True, timeout=900)
    except (OSError, subprocess.SubprocessError):
        return []
    out = []
    for line in r.stdout.splitlines():
        parts = line.split()
        if len(parts) < 5:
            continue
        symbol, dylib = parts[-1], parts[-2]
        if symbol.startswith("_"):
            out.append((dylib, symbol))
    return out


# --------------------------------------------------------------------------- #
# Prefix indexing
# --------------------------------------------------------------------------- #

def map_install_path(prefix, install_name):
    if not install_name.startswith("/"):
        return None
    return os.path.join(prefix, install_name.lstrip("/"))


class PrefixIndex:
    """Lazily resolves a framework/system-library name to its exported symbols,
    following LC_REEXPORT_DYLIB links transitively."""

    def __init__(self, prefix, build_dir=None):
        self.prefix = prefix
        self.build_dir = build_dir
        self._by_name = {}          # framework name -> binary path
        self._build_by_name = {}
        self._exports = {}          # realpath -> symbols
        self._closure = {}
        self._index()

    # -- locating binaries -------------------------------------------------- #
    def _index(self):
        for root in FRAMEWORK_ROOTS:
            base = os.path.join(self.prefix, root)
            if not os.path.isdir(base):
                continue
            for entry in os.listdir(base):
                if not entry.endswith(".framework"):
                    continue
                name = entry[:-len(".framework")]
                fwdir = os.path.join(base, entry)
                for candidate in (os.path.join(fwdir, name),
                                  os.path.join(fwdir, "Versions", "Current", name),
                                  os.path.join(fwdir, "Versions", "A", name),
                                  os.path.join(fwdir, "Versions", "B", name),
                                  os.path.join(fwdir, "Versions", "C", name)):
                    if os.path.isfile(candidate):
                        self._by_name.setdefault(name, os.path.realpath(candidate))
                        break
        for name, rel in SYSTEM_LIBS.items():
            p = os.path.join(self.prefix, rel)
            if os.path.isfile(p):
                self._by_name.setdefault(name, os.path.realpath(p))
            p2 = os.path.join(self.prefix, "usr/lib", name + ".dylib")
            if os.path.isfile(p2):
                self._by_name.setdefault(name, os.path.realpath(p2))

        if self.build_dir and os.path.isdir(self.build_dir):
            for root, _dirs, files in os.walk(self.build_dir):
                for fn in files:
                    if fn in self._build_by_name:
                        continue
                    p = os.path.join(root, fn)
                    if is_macho(p):
                        self._build_by_name[fn] = p

    def known(self, name):
        return name in self._by_name or name in self._build_by_name

    def _path_for(self, name):
        return self._by_name.get(name) or self._build_by_name.get(name)

    # -- exports ------------------------------------------------------------ #
    def _exports_of(self, path):
        real = os.path.realpath(path)
        if real not in self._exports:
            self._exports[real] = exported_symbols(real)
        return self._exports[real]

    def closure(self, name, _seen=None):
        """All symbols the named library exports, including re-exports."""
        if name in self._closure:
            return self._closure[name]
        seen = _seen if _seen is not None else set()
        path = self._path_for(name)
        if path is None:
            self._closure[name] = set()
            return self._closure[name]
        real = os.path.realpath(path)
        if real in seen:
            return set()
        seen.add(real)

        symbols = set(self._exports_of(real))
        for cmd, install_name in dylib_commands(real):
            if cmd != LC_REEXPORT_DYLIB:
                continue
            target = map_install_path(self.prefix, install_name)
            if target and os.path.isfile(target):
                # Re-export closure is included verbatim.
                target = os.path.realpath(target)
                if target in seen:
                    continue
                seen.add(target)
                symbols |= self._exports_of(target)
                for c2, n2 in dylib_commands(target):
                    if c2 == LC_REEXPORT_DYLIB:
                        t2 = map_install_path(self.prefix, n2)
                        if t2 and os.path.isfile(t2) and os.path.realpath(t2) not in seen:
                            seen.add(os.path.realpath(t2))
                            symbols |= self._exports_of(os.path.realpath(t2))
        # Also pick up sub-frameworks of umbrella frameworks (CoreServices,
        # Quartz, ...) which are loaded via LC_LOAD_DYLIB, not re-export.
        fwdir = os.path.dirname(real)
        nested = os.path.join(fwdir, "Frameworks")
        if os.path.isdir(nested):
            for entry in os.listdir(nested):
                if entry.endswith(".framework"):
                    sub = entry[:-len(".framework")]
                    for cand in (os.path.join(nested, entry, sub),
                                 os.path.join(nested, entry, "Versions", "A", sub)):
                        if os.path.isfile(cand):
                            symbols |= self._exports_of(cand)
                            break
        self._closure[name] = symbols
        return symbols


# --------------------------------------------------------------------------- #
# Xcode scanning
# --------------------------------------------------------------------------- #

def xcode_binaries(xcode):
    root = os.path.join(xcode, "Contents")
    out = [os.path.join(root, "MacOS", "Xcode")]
    for sub in ("Frameworks", "SharedFrameworks", "PlugIns"):
        for dirpath, _dirs, files in os.walk(os.path.join(root, sub)):
            for fn in files:
                p = os.path.join(dirpath, fn)
                if is_macho(p):
                    out.append(p)
    return [p for p in out if os.path.isfile(p)]


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--prefix", default=DEFAULT_PREFIX,
                    help=f"Darling install prefix (default: {DEFAULT_PREFIX})")
    ap.add_argument("--xcode", default=None,
                    help="Xcode.app to analyse (default: auto-detected, e.g. "
                         "<prefix>/Applications or $DARLING_ROOT/Applications or ~/.darling/Applications)")
    ap.add_argument("--build-dir", default=None,
                    help="Optional build directory; binaries there are treated as installed")
    ap.add_argument("--jobs", type=int, default=4, help="parallel objdump invocations")
    ap.add_argument("--json", default=None, help="write the report as JSON to this path")
    ap.add_argument("--quiet", action="store_true", help="only print failures")
    args = ap.parse_args()

    prefix = os.path.abspath(args.prefix)
    xcode = locate_xcode(prefix, args.xcode)

    if not os.path.isdir(xcode):
        print(f"error: Xcode not found at {xcode}", file=sys.stderr)
        return 2
    if not os.path.isdir(prefix):
        print(f"error: prefix not found at {prefix}", file=sys.stderr)
        return 2

    binaries = xcode_binaries(xcode)
    if not args.quiet:
        print(f"analysing {len(binaries)} Xcode binaries against {prefix}", file=sys.stderr)

    index = PrefixIndex(prefix, args.build_dir)

    def scan(path):
        return path, bind_table(path, "--bind"), set(bind_table(path, "--weak-bind"))

    results = []
    with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
        for path, strong, weak in pool.map(scan, binaries):
            results.append((path, strong, weak))

    missing = collections.defaultdict(lambda: collections.defaultdict(set))
    unknown = collections.defaultdict(set)

    for path, strong, weak in results:
        rel = os.path.relpath(path, xcode)
        for dylib, symbol in strong:
            if (dylib, symbol) in weak:
                continue            # weak bind: absence is tolerated by dyld
            if not index.known(dylib):
                continue            # bound against an Xcode-internal framework
            if symbol not in index.closure(dylib):
                missing[dylib][symbol].add(rel)

    total = sum(len(v) for v in missing.values())
    if not args.quiet:
        print(f"binaries: {len(binaries)}")
        print(f"non-lazy binds that the target library does not export: {total}")

    if total:
        print()
        for dylib in sorted(missing, key=lambda d: -len(missing[d])):
            print(f"### {dylib} ({len(missing[dylib])})")
            for symbol, users in sorted(missing[dylib].items()):
                extra = f" (+{len(users) - 1})" if len(users) > 1 else ""
                print(f"    {symbol}   <- {sorted(users)[0]}{extra}")
            print()

    if args.json:
        with open(args.json, "w") as f:
            json.dump({"prefix": prefix, "xcode": xcode, "binaries": len(binaries),
                       "missing": {d: {s: sorted(u) for s, u in v.items()}
                                   for d, v in missing.items()}}, f, indent=2)
        if not args.quiet:
            print(f"report written to {args.json}", file=sys.stderr)

    return 0 if total == 0 else 1


if __name__ == "__main__":
    sys.exit(main())