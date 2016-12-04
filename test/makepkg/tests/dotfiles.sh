#!/bin/bash

source "$(dirname "$0")"/../test_functions.sh || exit 1

script="$(locate_bin "${1:-}")"

TMPDIR="$(mktemp -d --tmpdir "${0##*/}.XXXXXX")"
[[ ${KEEPFILES:-0} == 0 ]] || trap "rm -rf '${TMPDIR}'" EXIT TERM

tap_note "test that dotfiles don't make it into the package root"
tap_note "testing '%s'" "$script"
tap_note "using test dir '%s'" "$TMPDIR"

output="$(
	set -e
	cd "$TMPDIR"
	cat >PKGBUILD <<-'PKGBUILD'
		pkgname=foo
		pkgver=1
		pkgrel=1
		arch=(any)
		package() {
			touch "$pkgdir"/.dotfile
		}
		PKGBUILD
	MAKEPKG_CONF="/dev/null" PKGEXT=".pkg.tar" $script 2>&1
)"
ret=$?

tap_plan 3
tap_eval "[[ '$ret' -ne 0 ]]"  "makepkg exited non-zero"
tap_eval "[[ ! -f '$TMPDIR/foo-1-1-any.pkg.tar' ]]" "no package was built"
tap_eval "[[ '$output' = *'Dotfile found in package root'* ]]" "error message references dotfile"
