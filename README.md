git-c2b is git tool to create separate branches from each commit in a branch
(over its tracking branch). You can call the script directly, or install it
somewhere in your $PATH, in which case you can use it as a git command `git
c2b`.

Usage: `git c2b [-h] [-n NUM_START] [branch]`

For example, from a branch 'feature' containing the commits D-E-F over
its tracking branch 'master':

    A-B-C       [master]
         \
          D-E-F [feature]

running git-c2b produces the following:

    A-B-C       [master]
         \
          D     [feature-1]
           \
            E   [feature-2]
             \
              F [feature-3] [feature]

You can change the starting number of the produced branch names by using the -n
parameter. Running `git-c2b -n 2` on the original 'feature' branch gives:

    A-B-C       [master]
         \
          D     [feature-2]
           \
            E   [feature-3]
             \
              F [feature-4] [feature]

If the produced branches already exist, git-c2b updates them with the new
contents.
