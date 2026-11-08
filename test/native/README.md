# Metadata ABI Probe

The probe compiles against `deps/nozzle/include/nozzle/nozzle_c.h` and exports
both snapshot sizes, every snapshot field's offset and width (including inline
array capacities), and header-typed synthetic snapshot fills. It does not link
core, call a real getter, create a receiver, or exercise a GPU backend.
The Dart tests allocate aligned storage large enough for both layouts plus a
guard; they never let the native fixture overwrite an undersized allocation.

Initialize the pinned core submodule before building. From the repository root,
create `.build` if necessary, then compile the fixture with the same commands
used by CI. `make` alone builds core, not this probe.

macOS:

```sh
mkdir -p .build
c++ -x c -std=c11 -dynamiclib -fPIC -Ideps/nozzle/include \
  test/native/info_abi_probe.c -o .build/nozzle_info_abi.dylib
```

Linux:

```sh
mkdir -p .build
c++ -x c -std=c11 -shared -fPIC -Ideps/nozzle/include \
  test/native/info_abi_probe.c -o .build/nozzle_info_abi.so
```

Windows (Git Bash, using the same GNU-compatible `c++` as the existing Makefile):

```sh
mkdir -p .build
c++ -x c -std=c11 -shared -Ideps/nozzle/include \
  test/native/info_abi_probe.c -o .build/nozzle_info_abi.dll
```

The compiler target must match the Dart process architecture. CI records the
compiler version and the tests print the Dart ABI and native snapshot sizes.
Missing or unloadable probes fail the tests; they are never silently skipped.

After `dart pub get`, the focused command is:

```sh
dart test test/info_snapshot_conversion_test.dart --reporter expanded
```

CI runs the full `dart test --reporter expanded` once, including snapshot
size/capacity/offset checks, strict bounded UTF-8 decoding, and owned conversion
after native storage is overwritten and freed.
Snapshot tests also allocate the maximum of native and Dart sizes, plus a guard,
before any native fill. There is no copied numeric struct-size oracle.

The obsolete borrowed connected-info struct, its three ABI tests, and its probe
exports were removed together. Snapshot layout and conversion coverage remains;
Discovery's separate `NativeNozzleSenderInfo` and enumeration/free path are unchanged.

The synthetic fills use fractional FPS and integer values above 32 bits but
below the signed 64-bit limit. They check all existing public metadata fields,
not real stream statistics or Dart's full unsigned 64-bit behavior. These probe
tests are not runtime getter or GPU evidence. The separate macOS-only
`test/info_snapshot_test.dart` exercises real public getters, sender closure and
owned values against the locally built core; it requires no fixture fill and
does not bypass the real backend. Other platforms exclude that file rather than
claiming receiver-lifecycle coverage.
