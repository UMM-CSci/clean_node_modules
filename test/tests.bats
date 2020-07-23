#!/usr/bin/env bats

load '../test/test_helper/bats-support/load'
load '../test/test_helper/bats-assert/load'
load '../test/test_helper/bats-file/load'

# For testing purposes we can check out a repository that
# has at least the following :
#   * A `node_modules` directory that is being ignored and
#     hasn't been accessed in a while (say a year)
#   * A `node_modules` directory that is being ignore and
#     has been accessed recently (say now)
#   * A `node_modules` directory that isn't being ignored
#     and hasn't been accessed in a while (say a year)
# The first of these should then be deleted and the other
# two should be left alone.

# To control all this, it probably makes sense to have a
# special test repository with all these features that we
# can check it. It won't have the old access times right
# after checkout, but we can use `touch` in `setup()` to
# set those to desired values.

