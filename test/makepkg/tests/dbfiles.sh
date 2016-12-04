#!/bin/bash

source "$(dirname "$0")"/../test_functions.sh || exit 1

script="$(locate_bin "${1:-}")"

TMPDIR="$(mktemp -d --tmpdir "${0##*/}.XXXXXX")"
trap "rm -rf '${TMPDIR}'" EXIT TERM

tap_note "check that required metadata files are created"
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
		PKGBUILD
	MAKEPKG_CONF="/dev/null" PKGEXT=".pkg.tar" $script
) |& tap_filter
[[ $? -eq 0 ]] || tap_xbail "test setup failed"

pkgfile="$TMPDIR/foo-1-1-any.pkg.tar"

tap_plan 10
for f in .BUILDINFO .PKGINFO .MTREE; do
	tap_ar_is_file "$pkgfile" "$f" "pkg contains %s" "$f"
	tap_ar_is_owner "$pkgfile" "$f" "0" "%s owner is root" "$f"
	tap_ar_is_group "$pkgfile" "$f" "0" "%s group is root" "$f"
done
tap_is_int "$(bsdtar -tf "$pkgfile" | wc -l)" 3 "pkg only contains known metainfo files"
