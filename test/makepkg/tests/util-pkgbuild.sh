#!/bin/bash

source "$(dirname "$0")"/../test_functions.sh || exit 1

tap_note "testing libmakepkg/util/pkgbuild.sh"

source_libmakepkg_file 'util/pkgbuild.sh'

test_foo() {
	myarray=(foo bar)
	myarray+=(baz)
	#myarray+=(this should be ignored)
	myscalar=baz
	myscalar=quux
	#myscalar=ignored
}

declare -a oarray
declare oscalar

tap_plan 9

tap_eval 'have_function test_foo' 'detected existing function test_foo'
tap_eval '! have_function test_bar' 'detected missing function test_bar'

tap_eval 'extract_function_variable test_foo myarray 1 oarray' 'extract array variable'
tap_is_int "${#oarray[@]}" 3 'extracted array length'
tap_is_str "${oarray[0]}" 'foo' 'extracted array contents'
tap_is_str "${oarray[1]}" 'bar' 'extracted array contents'
tap_is_str "${oarray[2]}" 'baz' 'extracted array contents'

tap_eval 'extract_function_variable test_foo myscalar 0 oscalar' 'extract scalar variable'
tap_is_str "$oscalar" 'quux' 'extracted scalar value'

tap_finish
