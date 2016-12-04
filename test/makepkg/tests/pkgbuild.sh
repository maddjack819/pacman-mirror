#!/bin/bash

source "$(dirname "$0")"/../test_functions.sh || exit 1

script="$(locate_bin "${1:-}")"

TMPDIR="$(mktemp -d --tmpdir "${0##*/}.XXXXXX")"
trap "rm -rf '${TMPDIR}'" EXIT TERM

tap_note "basic package building test"
tap_note "testing '%s'" "$script"
tap_note "using test dir '%s'" "$TMPDIR"

(
	set -e
	cd "$TMPDIR"
	cat >PKGBUILD <<-'PKGBUILD'
		pkgname=foo
		pkgver=1
		pkgrel=1
		arch=(any)
		package() {
			touch "$pkgdir/!first"
			touch "$pkgdir/target"
			ln -s target "$pkgdir/link"
			mkdir "$pkgdir/dir"
			touch "$pkgdir/dir/.dotfile"
		}
		PKGBUILD
	MAKEPKG_CONF="/dev/null" PKGEXT=".pkg.tar" $script
) |& tap_filter
[[ $? -eq 0 ]] || tap_xbail "test setup failed"

pkgfile="$TMPDIR/foo-1-1-any.pkg.tar"

tap_plan 10
tap_ar_is_file "$pkgfile" "!first" "pkg contains !first"
tap_ar_is_file "$pkgfile" "target" "pkg contains target"
tap_ar_is_file "$pkgfile" "dir/.dotfile" "pkg contains dir/.dotfile"
tap_ar_is_link "$pkgfile" "link" "target" "pkg contains link to target"
tap_ar_is_owner "$pkgfile" "target" "0" "target owner is root"
tap_ar_is_group "$pkgfile" "target" "0" "target group is root"

tap_eval "! bsdtar -tf '$pkgfile' | grep -qE '^\\.?\\.?/'" \
	"package paths are relative without leading dot dirs"
tap_eval "bsdtar -tf '$pkgfile' | grep -v '^\\.' | LANG=C sort -Cu" \
	"package files are sorted"
tap_eval "bsdtar -tf '$pkgfile' | LANG=C sort | LANG=C sort -Cu" \
	"package files are unique"
tap_eval "bsdtar -tf '$pkgfile' | head -n1 | grep -q '^\\.'" \
	"db files are placed at the beginning of the package"

tap_finish
