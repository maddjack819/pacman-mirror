# basic setup to run before every test
# tap_init
tap_init() {
	set +e
	set -u
	set -o pipefail
}

# wrapper around tap_bail that immediately causes the test to exit non-zero
# tap_xbail $reason...
tap_xbail() {
	tap_bail "$@"
	exit 1;
}

# read from stdin and reprint as diagnostic messages if VERBOSE is set and
# non-zero, otherwise, discard
# $command |& tap_filter
tap_filter() {
	local v=${VERBOSE:-0}
	if (( $v )); then
		while IFS= read line; do
			tap_diag "$line"
		done
	else
		while IFS= read line; do
			:
		done
	fi
}

# locate the script that should be tested
locate_bin() {
	local scriptdir="${PMTEST_SCRIPT_DIR:-"$(dirname "$0")/../../../scripts"}"
	local script="$(realpath "${1:-"$scriptdir/makepkg-wrapper"}")"
	if ! type -p "$script" &>/dev/null; then
		tap_xbail "makepkg executable (%s) could not be located" "${script}"
		exit 1
	fi
	printf "%s" "$script"
}

# locate an source libmakepkg files
source_libmakepkg_file() {
	local file=$1; shift 1
	local scriptdir="${PMTEST_SCRIPT_DIR:-"$(dirname "$0")/../../../scripts"}"
	local libdir="${PMTEST_LIBMAKEPKG_DIR:-"$scriptdir/libmakepkg"}"
	source "$(realpath "$libdir/$file")"
}

# eval a piece of code and test the return value
# tap_eval $code $test_name...
tap_eval() {
	local t=$1; shift 1
	eval "$t"
	tap_ok $? "$@"
}

# extract ls-style information about a file:
# mode nhardlinks user group size month date time/year filename
_ar_stat() {
	local ar=$1 path=$2; shift 2
	bsdtar --fast-read -tvf "$ar" "$@" "$path"  2>/dev/null
}

# same as _ar_stat but with numeric owner ids
_ar_nstat() {
	local ar=$1 path=$2; shift 2
	_ar_stat "$ar" "$path" --numeric-owner "$@"
}

# check the owner of a given file, owner may be a numeric id or user name
# tap_ar_is_owner $path_to_archive $file $expected_owner $test_name...
tap_ar_is_owner() {
	local ar=$1 path=$2 expect=$3; shift 3
	local statfun="_ar_stat" owner unused
	[[ $expect =~ ^[0-9]+$ ]] && statfun="_ar_nstat"
	if ! read -r unused unused owner unused < <($statfun "$ar" "$path"); then
		tap_ok 1 "$@"
		tap_diag "         got: invalid path"
		tap_diag "    expected: '%s'" "$expect"
	elif [[ $owner != $expect ]]; then
		tap_ok 1 "$@"
		tap_diag "         got: '%s'" "$owner"
		tap_diag "    expected: '%s'" "$expect"
	else
		tap_ok 0 "$@"
	fi
}

# check the group of a given file, group may be a numeric id or user name
# tap_ar_is_group $path_to_archive $file $expected_group $test_name...
tap_ar_is_group() {
	local ar=$1 path=$2 expect=$3; shift 3
	local statfun="_ar_stat" group unused
	[[ $expect =~ ^[0-9]+$ ]] && statfun="_ar_nstat"
	if ! read -r unused unused unused group unused < <($statfun "$ar" "$path"); then
		tap_ok 1 "$@"
		tap_diag "         got: invalid path"
		tap_diag "    expected: '%s'" "$expect"
	elif [[ $group != $expect ]]; then
		tap_ok 1 "$@"
		tap_diag "         got: '%s'" "$group"
		tap_diag "    expected: '%s'" "$expect"
	else
		tap_ok 0 "$@"
	fi
}

# check if a path within an archive refers to a file
# tap_ar_is_file $path_to_archive $file $test_name...
tap_ar_is_file() {
	local ar=$1 path=$2; shift 2
	local stat="$(_ar_stat "$ar" "$path")"
	if [[ ${stat:0:1} != '-' ]]; then
		tap_ok 1 "$@"
		tap_diag "         got: not a file"
		tap_diag "    expected: '%s'" "$path"
	else
		tap_ok 0 "$@"
	fi
}

# check if a path within an archive refers to a symbolic link
# tap_ar_is_link $path_to_archive $file $expected_destination $test_name...
tap_ar_is_link() {
	local ar=$1 path=$2 dest=$3; shift 3
	local stat="$(_ar_stat "$ar" "$path")"
	if [[ ${stat:0:1} != 'l' ]]; then
		tap_ok 1 "$@"
		tap_diag "         got: not a link"
		tap_diag "    expected: '%s'" "$dest"
	elif [[ ${stat##*$path -> } != $dest ]]; then
		tap_ok 1 "$@"
		tap_diag "         got: '%s'" "${stat##*$path -> }"
		tap_diag "    expected: '%s'" "$dest"
	else
		tap_ok 0 "$@"
	fi
}

source "$(dirname "$0")"/../../tap.sh || exit 1
tap_init
