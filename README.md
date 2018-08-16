# git-strict-commit-hook

Git commit hook to help you write better commit messages by validating
them against a set of common rules and offering you to correct them
before approving your commit.


## Enforced Rules

 1. Prefix the subject line with ticket ID(s).
 2. Start the subject line with a word.
 3. Do no write single worded commits.
 4. Limit the subject line to `${RULE_4_LIMIT}` characters. (default: 72)
 5. Separate subject from body with a blank line.
 6. Capitalize the subject line.
 7. Do not end the subject line with a period.
 8. Use the imperative mood in the subject line.
 9. Wrap the body at `${RULE_9_LIMIT}` characters. (default: 72)
 10. ~~Document the "why?" and the "how?"~~


## Installation

### Single repository

At the root of the repository, run:

```sh
curl https://cdn.rawgit.com/laurent-malvert/git-strict-commit/v0.7.0/hook.sh \
    > .git/hooks/commit-msga \
        && chmod +x .git/hooks/commit-msg
```

### Globally

To use the hook globally, you can use `git-init`'s template directory:

```sh
mkdir -p ~/.git-template/hooks
git config --global init.templatedir '~/.git-template'
curl https://cdn.rawgit.com/laurent-malvert/git-good-commit/v0.7.0/hook.sh \
    > ~/.git-template/hooks/commit-msg \
        && chmod +x ~/.git-template/hooks/commit-msg
```

The hook will now be present after any `git init` or `git clone`. You
can [safely re-run `git
init`](http://stackoverflow.com/a/5149861/885540) on any existing
repositories to add the hook there.

---

_If you're security conscious, you may be reasonably suspicious of
[curling executable
files](https://www.seancassidy.me/dont-pipe-to-your-shell.html). You
should be. Downloading this script and verify it for yourself._


## Usage

```sh
# Create a small change and stage it:
echo "apple" > ./bar.txt
git add fruits.txt

# Should warn you that:
#  - the subjet line does not start with a ticket ID,
#  - the subject line is not capitalised.
#
# An interactive prompt is then offered to let you decide
# what to do about that.
git commit -m 'add fruits.txt'
```

### Actions

```
a - abort - Abort and exit (without committing).
c - continue - Commit anyway (with a potentially invalid message).
e - edit - Edit commit message and re-validate.
? - Print help.
```

## Configuration

### Disabling Rules

While strongly discouraged, each rule can be disabled in your
`.git/config` or `~/.gitconfig` with:

```
    hooks.strictcommit.rule<RULE_ID> = false
```

E.g., to disable rule 1 enforcing the use of ticket IDs, run:

```sh
git config hooks.strictcommit.rule1 false
```

This will add the following to your current project's `.git/config`:

```
[hooks "strictcommit"]
	rule1 = false
```

### Overrides

Some of the rules expose additional options to override their default
values, namely:

```
    hooks.strictcommit.ticketformat # default: '\([A-Z]\{1,\}-[0-9]\{1,\}\(,\([A-Z]\{1,\}-[0-9]\{1,\}\)\)\{0,\}\).*'


    hooks.strictcommit.rule4.limit  # default: 72
    hooks.strictcommit.rule9.limit  # default: 72
```

### Colors

The default colour setting is `auto`, but the hook will use `git`'s
`color.ui` config setting if defined. You override the colour setting
for the hook with:

```
git config --global hooks.strictcommit.color "never"
```

Supported values are `always`, `auto`, `never` and `false`.


## Dependencies

 * A POSIX shell (this runs with `!/bin/sh`)
 * `sed`
 * `expr`


## Credits

### Origins

`git-strict-commit-hook` takes its roots mostly in:

 * [the seven rules of a great git commit message](http://chris.beams.io/posts/git-commit/),
 * [git-good-commit](https://github.com/tommarshall/git-good-commit).

However, it deviates from the rules set by these earlier efforts in a
number of ways:

 * The enforced length of lines is more reasonable and not rooted in a
   bell curve of the Linux Kernel's commit activity (which served no
   valid justification for other projects at large, in my opinion). So
   the default is 72 chars for a subject line, not 50.

 * The subject line requires at least one ticket ID. This is arbitrary
   and annoying, and formats may vary (see **Overrides*), but most
   projects always work with an issue tracker. If they don't, they
   should.
   This is contentious though, and likely to be the most disabled rule
   of this commit hook, if I had to take a wild guess.

 * The imperative mood detection is based on inspection of the first
   word's ending, instead of using a blacklist of words. This is still
   error-prone, but easier and better in general. I didn't like the idea
   of a global list of words to blindly check against. Checking for line
   endings isn't very clever either, and will only work for English in
   the current form, but at least it's more maintainable.

 * It is configurable, in so far as you can:

   * override some of the default values,
   * enable/disable some of the rules.

 * Most importantly (for me), it uses POSIX shell and not Bash. Nothing
   wrong with Bash, but I like to have most scripts that I use on
   multiple platforms to conform to POSIX shells for portability
   reasons. If they outgrow this restriction, usually it's time to aim
   for a more capable language anyways.

### Related Work

* http://chris.beams.io/posts/git-commit
* http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
* https://www.git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project#Commit-Guidelines
* Tim Perry's excellent [git-confim](https://github.com/pimterry/git-confirm)
  hook, which provided Tom Marhsall with the inspiration and base work for
  `git-good-commit`.
* Tom Marshall's
  [git-good-commit](https://github.com/tommarshall/git-good-commit),
  which provided me with the inspiration and base work for
  `git-strict-commit-hook`.

## Contributors

### Original Contributors

I originally intended to contribute back to [Tom
Marshall](https://github.com/tommarshall)'s
[`git-good-commit`](https://github.com/tommarshall/git-good-commit)
repository , but then realized I had a rather different approach and
created a real fork instead, which I pushed to GitLab (where I host my
primary repos, while I generally only mirror to other code hubs like
GitHub and BitBucket).

So, all contributors to Tom's repo up to commit
[27a2b06e2e158c53aa9f7e835c83b8af9e299a13](https://github.com/tommarshall/git-good-commit/commit/27a2b06e2e158c53aa9f7e835c83b8af9e299a13)
rightfully deserve credit as I used his repo as the original upstream
for mine until I forked.

These include:

 * [tommarshall](https://github.com/tommarshall)
 * [rakeen](https://github.com/rakeen)
 * [walle](https://github.com/walle)
