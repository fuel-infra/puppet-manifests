#!/usr/bin/python

from git import *
import re
import os

REPO_LOCAL = os.environ.get("REPO_LOCAL", "")
if re.match("^~", REPO_LOCAL):
    REPO_LOCAL = os.path.expanduser(REPO_LOCAL)
REPO_LOCAL = os.path.abspath(REPO_LOCAL)

MANAGE_COLLECTOR = REPO_LOCAL + "/collector/manage_collector.py"
DB_MIGRATION = REPO_LOCAL + "/collector/collector/api/db/migrations"


def __main__():
    try:
        repo = Repo(REPO_LOCAL, odbt=GitDB)
    except InvalidGitRepositoryError:
        print "Invalid GIT repository path"
        exit(1)
    remote_fetch = repo.remotes.origin.fetch()[0]

    if repo.head.commit == remote_fetch.commit:
        # update code goes here
        print "No updates available"
        exit(0)

    # Ok, we need to update local repos
    migration = False
    for diff in repo.head.commit.diff(remote_fetch.commit):
        print "Changed file {0}".format(diff.b_blob.abspath)
        if DB_MIGRATION in diff.b_blob.abspath:
            print "Migration found"
            migration = True

    print "Pull from remote repo"
    repo.remotes.origin.pull()

    if migration:
        os.system(
            "python {0} --mode=test db upgrade -d {1}".format(
                MANAGE_COLLECTOR, DB_MIGRATION
            )
        )
    # os.system("service uwsgi restart")


if __name__ == "__main__":
    __main__()
