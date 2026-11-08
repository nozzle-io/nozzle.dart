# Connected-Info ABI Probe

The probe compiles against `deps/nozzle/include/nozzle/nozzle_c.h` and exports
native `sizeof`, modifier `offsetof`, and a header-typed fill fixture. It does
not link core, call a real getter, create a receiver, or exercise a GPU backend.
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
compiler version and the tests print the Dart ABI, both sizes, and native offset.
Missing or unloadable probes fail the tests; they are never silently skipped.

After `dart pub get`, the focused command is:

```sh
dart test test/connected_info_abi_test.dart --reporter expanded
```

CI runs the full `dart test --reporter expanded` once, including all three
independent ABI cases. These prove layout and fixture decoding only, not runtime
getter overwrite reproduction or connection-state behavior.
