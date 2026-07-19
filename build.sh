#!/bin/sh
# Compile every C-- program in this repository and fail if any target
# does not build. This mirrors what `tup` does in the main KolibriOS
# build, but standalone: it reads each Tupfile.lua and runs the c--
# compiler on the declared target(s).
#
# The compiler is not part of this repository - it lives in KolibriOS/cmm
# and is expected on PATH, exactly as the tup rules invoke it.
#
#   Usage:  ./build.sh [LANG_ENG|LANG_RUS]      (default: LANG_ENG)
#   Env:    CMM=/path/to/c--   override compiler (default: c-- from PATH)
#
# Exit status: 0 if every program compiled, 1 otherwise.

set -u

# Let /D=... /OPATH=... survive Git Bash (MSYS) path mangling; a no-op on Linux.
export MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CMM=${CMM:-c--}
LANG_DEF=${1:-LANG_ENG}
CMM_TIMEOUT=${CMM_TIMEOUT:-60}   # seconds; a real compile takes <2s, so this only fires on a hang
CMM_TRIES=${CMM_TRIES:-4}        # retries to absorb the flaky c-- crash/hang
DIST="$ROOT/dist"                # built binaries are collected here for the CI artifact
rm -rf "$DIST"
mkdir -p "$DIST"

if ! command -v "$CMM" >/dev/null 2>&1 && [ ! -x "$CMM" ]; then
	echo "c-- not found: $CMM" >&2
	echo "build it from https://git.kolibrios.org/KolibriOS/cmm and put it on PATH," >&2
	echo "or point CMM at it." >&2
	exit 2
fi

echo "compiler : $CMM"
echo "language : $LANG_DEF"
echo "root     : $ROOT"
echo

pass=0
fail=0
failed=''

# compile_one <dir> <source.c> <extra-defines>
compile_one() {
	d=$1
	src=$2
	defs=$3
	out="${src%.c}.com"
	log=$(mktemp)
	rc=0
	attempt=0
	# The c-- 0.239 build is known to be flaky in a heap-layout-dependent way:
	# on an unlucky run it can segfault (rc 139) or spin forever on a valid
	# source. So each compile is wrapped in a hard timeout and retried a few
	# times. A real compile error (non-zero rc with output produced quickly)
	# is NOT retried -- we stop and report it.
	while [ "$attempt" -lt "$CMM_TRIES" ]; do
		attempt=$((attempt + 1))
		( cd "$d" && rm -f "$out" && timeout -k 5 "$CMM_TIMEOUT" "$CMM" $defs "$src" ) >"$log" 2>&1
		rc=$?
		if [ "$rc" -eq 0 ] && [ -s "$d/$out" ]; then
			break
		fi
		# retry only on a crash / hang (compiler flakiness); stop on a real error
		case "$rc" in
			124 | 137 | 139 | 134 | 143) ;;   # timeout / SIGKILL / SIGSEGV / SIGABRT / SIGTERM
			*) break ;;
		esac
		[ "$attempt" -lt "$CMM_TRIES" ] && printf '  retry %s/%s (rc=%s, attempt %s)\n' "$d" "$src" "$rc" "$attempt"
	done

	if [ "$rc" -eq 0 ] && [ -s "$d/$out" ]; then
		pass=$((pass + 1))
		printf '  ok    %s/%s\n' "$d" "$src"
		# collect under dist/ named as KolibriOS ships it: lowercase, without
		# the extension. The program dir is mirrored so same-named outputs
		# like menu/menu.com and examples/menu.com don't clash.
		dst="$DIST/${d#./}/$(printf '%s' "${out%.com}" | tr 'A-Z' 'a-z')"
		mkdir -p "$(dirname "$dst")"
		cp "$d/$out" "$dst"
	else
		fail=$((fail + 1))
		failed="$failed $d/$src"
		printf '  FAIL  %s/%s (rc=%s)\n' "$d" "$src" "$rc"
		sed 's/^/        | /' "$log"
	fi
	rm -f "$log"
}

cd "$ROOT" || exit 2

for tf in $(find . -name Tupfile.lua | sort); do
	d=$(dirname "$tf")
	rule=$(grep -E 'tup\.(foreach_)?rule\(' "$tf" | head -1)
	[ -n "$rule" ] || continue

	defs=''
	printf '%s' "$rule" | grep -q 'C_LANG'   && defs="$defs /D=$LANG_DEF"
	printf '%s' "$rule" | grep -q 'AUTOBUILD' && defs="$defs /D=AUTOBUILD"

	# input = first quoted argument of the tup.rule / tup.foreach_rule call
	input=$(printf '%s' "$rule" | sed -E 's/.*tup\.(foreach_)?rule\("([^"]+)".*/\2/')

	echo "[$d]  defs:${defs:- none}"
	if printf '%s' "$rule" | grep -q 'foreach_rule'; then
		# build every source matching the glob (e.g. *.c)
		for f in "$d"/$input; do
			[ -f "$f" ] || continue
			compile_one "$d" "$(basename "$f")" "$defs"
		done
	else
		compile_one "$d" "$input" "$defs"
	fi
done

echo
echo "================================================================"
echo "built OK : $pass"
echo "failed   : $fail"
if [ "$fail" -ne 0 ]; then
	echo "failures :"
	for x in $failed; do echo "   - $x"; done
	exit 1
fi
echo "all C-- programs compiled."
