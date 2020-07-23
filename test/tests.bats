#!/usr/bin/env bats

load '../test/test_helper/bats-support/load'
load '../test/test_helper/bats-assert/load'
load '../test/test_helper/bats-file/load'

PAST_ACCESS_TIME="4 months ago"

#######################################
# Run `npm install` in the specified
# directory.
# Arguments:
#   Directory to run `npm install` in.
# Returns:
#   0 if the install was successful, non-zero on error.
#######################################
function npm_install() {
    # The `(...)` returns us back to our current
    # directory when the `npm install` is done,
    # avoiding the need for a `pushd/popd` pair.
    # The `&> /dev/null` swallows _all_ output,
    # whether to `stdout` or `stderr`; otherwise
    # `npm install` generated a *lot* of distracting
    # chatter.
    (cd "$1" && exec npm install &> /dev/null)
}

#######################################
# Set the access time for the specified file or
# directory to the value in PAST_ACCESS_TIME.
# Arguments:
#   File or directory to set the access time for.
# Returns:
#   0 if action was successful, non-zero on error.
#######################################
function roll_back_acces_time() {
    touch -a --date="$PAST_ACCESS_TIME" "$1"
}

# For testing purposes we check out a special test repository that
# has at least the following :
#   * A `node_modules` directory that is being ignored and
#     hasn't been accessed in a while (say a year). This is
#     called `old_ignored_node_modules`.
#   * A `node_modules` directory that is being ignored and
#     has been accessed recently (say now). This is
#     called `new_ignored_node_modules`.
#   * A `node_modules` directory that isn't being ignored
#     and hasn't been accessed in a while (say a year). This is
#     called `old_not_ignored_node_modules`.
# The first of these should then be deleted and the other
# two should be left alone.

# When we clone this repo it won't have the desired access times
# for the "old" `node_modules` directories, so we'll have to use
# `touch` in `setup()` to set those to desired values.

# There are several commands here that generate a lot of "chatter"
# on the output (`pushd`, `popd`, `git clone`) so various things
# are done to quiet them down or (if quiet wasn't possible) swallow
# the output.
function setup() {
    TEST_TEMP_DIR="$(temp_make)"
    echo "# Temp directory: $TEST_TEMP_DIR" >&3
    BATSLIB_FILE_PATH_REM="#${TEST_TEMP_DIR}"
    BATSLIB_FILE_PATH_ADD='<temp>'
    BATSLIB_TEMP_PRESERVE_ON_FAILURE=1

    pushd "$TEST_TEMP_DIR" &> /dev/null || exit 1 
    git clone --quiet https://github.com/UMM-CSci/clean-node-modules-test-repo.git
    cd clean-node-modules-test-repo || exit 1
    npm_install 'old_ignored_node_modules'
    npm_install 'old_not_ignored_node_modules'
    npm_install 'new_ignored_node_modules'
    roll_back_acces_time 'old_ignored_node_modules/node_modules'
    roll_back_acces_time 'old_not_ignored_node_modules/node_modules'
    popd &> /dev/null || exit 1
}

function teardown() {
    temp_del "$TEST_TEMP_DIR"
}

# In a perfect world we'd write these as three separate tests. The
# cost of `setup()` (with the `git clone` and `npm install`) is 
# high, though, so I'm doing all of these in one test to speed things
# up and reduce resource load on GitHub and NPM servers.
@test "should delete the old, ignored 'node_modules', leaving the others alone" {
    assert_file_executable 'clean_node_modules'
    ./clean_node_modules "$TEST_TEMP_DIR"
    assert_dir_exist "$TEST_TEMP_DIR/clean-node-modules-test-repo/new_ignored_node_modules/node_modules"
    assert_dir_exist "$TEST_TEMP_DIR/clean-node-modules-test-repo/old_not_ignored_node_modules/node_modules"
    assert_dir_not_exist "$TEST_TEMP_DIR/clean-node-modules-test-repo/old_ignored_node_modules/node_modules"
}