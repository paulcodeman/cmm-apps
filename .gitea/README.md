# Continuous integration

## `Build C-- programs` (`workflows/build.yaml`)

Runs on every push to `main` and on every pull request. It compiles
every C-- program in the repository and fails if any target stops
building, so a change that breaks compilation is caught before merge.

The compiler is not committed here. The job clones [KolibriOS/cmm], builds
it with `Makefile.lin32` and puts the result on `PATH` together with its
`c--.ini`, which is where the compiler looks for it. Building the tip of
the compiler on every run is deliberate: a compiler change that breaks a
program is caught here, before it is bumped into the OS tree.

The heavy lifting is in [`build.sh`](../build.sh):

* it walks every `Tupfile.lua` and reads the declared c-- rule, so the
  set of built programs stays in sync with the real `tup` build — add a
  program with a `Tupfile.lua` and CI picks it up automatically;
* `tup.foreach_rule("*.c", …)` directories (`examples/`, `misc/`) build
  every source file, single-`tup.rule` directories build their one target;
* `/D=AUTOBUILD` and the `/D=LANG_*` define are applied exactly as the
  `Tupfile.lua` requests;
* a target is considered built only if c-- exits 0 **and** produced a
  non-empty `.com`; a crash or hang (the known heap-layout-dependent c--
  flakiness) is caught by a per-compile timeout and retried up to 4 times
  before being reported as a failure.

Language variants `LANG_ENG` and `LANG_RUS` build in parallel.

The compiled `.com` files are collected under `dist/` and published as a
per-language artifact (`cmm-programs-LANG_ENG` / `cmm-programs-LANG_RUS`),
downloadable from the run's **Summary** page for 14 days.

### Running it locally

```sh
# c-- on PATH:
./build.sh LANG_ENG

# or point CMM at a compiler built from KolibriOS/cmm:
CMM=/path/to/c--.exe sh build.sh LANG_ENG
```

### Runner

The job uses the `kolibri-toolchain` runner, the same self-hosted runner
label as the main [kolibrios] build. It needs a working `g++` and `make`
to build the compiler, and must be able to run the resulting 32-bit i386
binary (any x86-64 Linux with IA32 support).

[kolibrios]: https://git.kolibrios.org/KolibriOS/kolibrios
[KolibriOS/cmm]: https://git.kolibrios.org/KolibriOS/cmm
