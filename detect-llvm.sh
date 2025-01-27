#!/usr/bin/env bash
# Requires: LLVM 7.0 installed in some known location.
# Usage: ./detect-llvm.sh, or sourced.

set -e

# XXX: Currently we stick to LLVM 7.

test_llvm7_prefix()
{
	for pfx in "/usr/lib/llvm-7" "/opt/llvm70" "/opt/llvm70" \
		"/usr/local" "/usr"; do
		if [[ -x "$pfx/bin/llvm-config" ]]; then
			if [[ $("$pfx/bin/llvm-config" --version) =~ 7\..+ ]]; then
				LLVM_PREFIX="$("$pfx/bin/llvm-config" --prefix)"
				LLVM_BINDIR="$("$pfx/bin/llvm-config" --bindir)"
				return
			fi
		fi
	done
}

test_llvm7_prefix
echo 'Found LLVM 7 prefix:' "$LLVM_PREFIX"
echo 'LLVM version:' "$("$LLVM_BINDIR/llvm-config" --version)"

CXXFLAGS_EXTRA="$("$LLVM_BINDIR/llvm-config" --cxxflags | sed s/-DNDEBUG//g) \
-fexceptions -frtti -Wp,-U_FORTIFY_SOURCE -U_FORTIFY_SOURCE -Wno-date-time"
if echo "$CXX" | grep -q clang; then
	echo 'Found $CXX: '"$CXX"', unsupported compiler options are removed.'
	CXXFLAGS_EXTRA="$(echo "$CXXFLAGS_EXTRA" \
| sed -E 's/-Wno-(class-memaccess|maybe-uninitialized)//g')"
fi
# NOTE: Loading local symbol in LLVM IR requires '--export-dynamic'.
LIBS_EXTRA="$("$LLVM_BINDIR/llvm-config" --ldflags) \
$("$LLVM_BINDIR/llvm-config" --libs) -lffi -Wl,--export-dynamic"

