# clean_node_modules

A script to remove `node_modules` directories to free up disk space.

## Motivation

We find that web development eats up a _lot_ of disk space in
in our labs, and that most of that is due to large
`node_modules` directories that end up lying around long after
the course they were generated for is over. In Software Design,
for example, we might end up with 7 or 8 labs and iterations
for each student, each of which has their own large
`node_modules` directory. If a class has 20 students, that
could easily be 150 or more `node_modules` directories from
a single semester.

## Concerns and approach

We could take a really simplistic approach and just search for
everything called `node_modules` and delete it. There are a
few concerns there, however:

- Someone might have a folder called `node_modules` that
  wasn't created by `npm` and be really unhappy that it got
  deleted. This isn't super likely, to be honest, but it is
  possible.
- It's also dimly possible (but again unlikely) that someone
  _wants_ their `node_modules` directory for reasons
  unimagined by us.
- We could delete what might be considered an "active"
  `node_modules` directory, i.e., one on a project that the
  user is currently working on. That can obviously be
  reconstructed, but it's slow to redownload all those files,
  and it would certainly be quite annoying if every week or
  so all your `node_modules` directories disappeared on you.

A possible approach for dealing with the first two concerns would be
using `.gitignore` as a proxy for "it's OK to delete this".
If a user has a file or directory (like `node_modules`) in
a `.gitignore` file, then that would have to be regenerated
by anyone (including this user) who clones the project in the
future, so at some level they probably won't be too upset if
it got deleted. Happily it seems that the `git check-ignore`
may do exactly the checking we want, without us having to scan
up through the directory tree, etc.

The third concern might possibly be addressed through one or
more of the `mtime`, `ctime`, or `atime` attributes of the
`node_modules` directory. We could, for example, decide to
only delete `node_modules` directories that are at least six
months old by some measure. Six months would probably be long
enough to "protect" directories across breaks (including
summers). We could probably get away with three months,
however, and it might make sense to start with the shorter
timespan and see if anyone complains. (People will definitely
fuss if we set it too short, but no one will tell us if we
set it too long.)

It's not obvious which of `mtime`, `ctime`, or `atime` to use.
I _think_ that `atime` may be our best bet. Users often won't
_modify_ (i.e., change `mtime` or `ctime`) `node_modules` for
long periods of time, especially once a project's structure
has stabilized. I _think_ they'll "access" (`atime`) the
`node_modules` folder fairly often (e.g., whenever they build
the project), so hopefully that will be informative.

Adding a new dependency with `ng add` changes all three times.

Running `ng serve` after `ng add` changes `atime` but leaves
the other two alone. Running `ng serve` a little later without
having touched or changed any other files also updates `atime`
without changing anything else.
This supports the idea that `atime` is the
one that would be the most useful.

Unfortunately it looks like running tools like `du` can sometimes update
the `atime`, so we might have cases where things look like they've
been accessed by the user a lot more recently than we would expect.

## Usage

I'm envisioning a script that takes one or more arguments
which are the directories that should be checked for
`node_modules` directories. If no arguments are given, it _might_
be reasonable to use the current directory as the directory to
explore, but given the potentially destructive nature of the
command it might make sense to be more conservative and require
an explicit directory.

We might allow the minimum age of directories to delete to be
configurable through command line arguments; 3 months might be the default,
but we could allow the user to set different time bounds.

## Issues

The current use of `git check-ignore --quiet node_modules` in
the script leads to lots of errors like:

```bash
fatal: Not a git repository (or any parent up to mount point /)
Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).
```

## Future features

We should have a `--dry-run` option that lists

- All the `node_modules` directories that will be deleted
- All the `node_modules` directories it's skipping, with info on why

(This could be fancied up with additional flags, but just reporting
everything would do for starters.)

Maybe a flag to list `--not-ignored` and `--too-new`, and maybe a
`--summary` flag.

Maybe a `--interactive` that shows you how many directories it will delete
and ask for confirmation. Or maybe that should be the default, and we
instead have a `--force` flag (modelled after `rm`) that skips that step?

Allow people to set the time as an argument, e.g., `--min-age="now"` so they
can clean up everything at the end of a semester.
