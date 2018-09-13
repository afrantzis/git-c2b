#!/bin/sh

GIT_C2B=$(pwd)/git-c2b
TEST_DIR=""

add_commit() {
    echo $1 > $1.txt
    git add $1.txt
    git commit -q -a -m "$1"
}

create_repo() {
    repo=$(mktemp -d $TEST_DIR/repo.XXXXXXXXXX)
    (
     cd $repo;
     git init -q .;
     add_commit a;
     add_commit b;
    )
    echo $repo
}

destroy_repo() {
    [ -d "$1"/.git ] && rm -rf "$1"
}

assert() {       
  if ! $1; then
    echo "Assertion failed:  \"$1\""
    exit 1
  fi  
}

assert_fail() {       
  if $1; then
    echo "Assertion failed:  \"$1\""
    exit 1
  fi  
}

get_commit() {
    git rev-parse $1
}

get_num_branches() {
    git branch -a | wc -l
}

cleanup() {
    rm -rf "$TEST_DIR"
}

prepare_for_run() {
    TEST_DIR=$(mktemp -d -t git-c2b.test.XXXXXXXXXX)
    trap cleanup EXIT
}

run_test() {
    log=$(mktemp)
    if ($1 > $log 2>&1 ;); then
	echo "$1: \e[0;32mSuccess\e[0m"
    else
	echo "$1: \e[0;31mFail\e[0m"
	cat $log
    fi
    rm $log
}

test_git_c2b_in_branch_without_upstream_fails() {
    repo="$(create_repo)"
    cd $repo

    # master has no upstream
    assert_fail "$GIT_C2B"

    # feature without upstream
    git checkout -b feature
    assert_fail "$GIT_C2B"

    destroy_repo $repo
}

test_git_c2b_in_empty_branch_with_upstream_has_no_effect() {
    repo="$(create_repo)"
    cd $repo

    # feature with upstream
    git checkout -b feature -t master
    assert "$GIT_C2B"

    assert "[ "$(get_commit feature)" = "$(get_commit master)" ]"
    assert "[ "$(get_num_branches)" -eq 2 ]"

    destroy_repo $repo
}

test_git_c2b_in_branch_with_upstream_creates_branches() {
    repo="$(create_repo)"
    cd $repo

    # feature with upstream
    git checkout -b feature -t master
    add_commit c
    add_commit d
    add_commit e

    assert "$GIT_C2B"

    assert "[ "$(get_commit feature-1)" = "$(get_commit feature~2)" ]"
    assert "[ "$(get_commit feature-2)" = "$(get_commit feature~1)" ]"
    assert "[ "$(get_commit feature-3)" = "$(get_commit feature)" ]"

    destroy_repo $repo
}

test_git_c2b_with_branch_while_in_branch_creates_branches() {
    repo="$(create_repo)"
    cd $repo

    # feature with upstream
    git checkout -b feature -t master
    add_commit c
    add_commit d
    add_commit e

    assert "$GIT_C2B feature"

    assert "[ "$(get_commit feature-1)" = "$(get_commit feature~2)" ]"
    assert "[ "$(get_commit feature-2)" = "$(get_commit feature~1)" ]"
    assert "[ "$(get_commit feature-3)" = "$(get_commit feature)" ]"

    destroy_repo $repo
}

test_git_c2b_with_branch_with_upstream_while_in_other_branch_creates_branches() {
    repo="$(create_repo)"
    cd $repo

    # feature with upstream
    git checkout -b feature -t master
    add_commit c
    add_commit d
    add_commit e

    git checkout master
    assert "$GIT_C2B feature"

    assert "[ "$(get_commit feature-1)" = "$(get_commit feature~2)" ]"
    assert "[ "$(get_commit feature-2)" = "$(get_commit feature~1)" ]"
    assert "[ "$(get_commit feature-3)" = "$(get_commit feature)" ]"

    destroy_repo $repo
}

test_git_c2b_with_count_creates_correctly_numbered_branches() {
    repo="$(create_repo)"
    cd $repo

    # feature with upstream
    git checkout -b feature -t master
    add_commit c
    add_commit d
    add_commit e

    assert "$GIT_C2B -n 5"

    assert "[ "$(get_commit feature-5)" = "$(get_commit feature~2)" ]"
    assert "[ "$(get_commit feature-6)" = "$(get_commit feature~1)" ]"
    assert "[ "$(get_commit feature-7)" = "$(get_commit feature)" ]"

    destroy_repo $repo
}

test_git_c2b_updates_branches() {
    repo="$(create_repo)"
    cd $repo

    # feature with upstream
    git checkout -b feature -t master
    add_commit c
    add_commit d
    add_commit e

    assert "$GIT_C2B"

    commit_c=$(get_commit feature~2)
    commit_d=$(get_commit feature~1)
    commit_e=$(get_commit feature)

    assert "[ "$(get_commit feature-1)" = "$commit_c" ]"
    assert "[ "$(get_commit feature-2)" = "$commit_d" ]"
    assert "[ "$(get_commit feature-3)" = "$commit_e" ]"

    # Update feature branch with new commits
    git reset --hard master
    add_commit c1
    add_commit d1
    add_commit e1

    assert "$GIT_C2B"

    # Check that created branches point to new commits
    assert "[ "$(get_commit feature-1)" = "$(get_commit feature~2)" ]"
    assert "[ "$(get_commit feature-1)" != "$commit_c" ]"

    assert "[ "$(get_commit feature-2)" = "$(get_commit feature~1)" ]"
    assert "[ "$(get_commit feature-1)" != "$commit_d" ]"

    assert "[ "$(get_commit feature-3)" = "$(get_commit feature)" ]"
    assert "[ "$(get_commit feature-1)" != "$commit_e" ]"

    destroy_repo $repo
}

prepare_for_run

run_test test_git_c2b_in_branch_without_upstream_fails
run_test test_git_c2b_in_empty_branch_with_upstream_has_no_effect
run_test test_git_c2b_in_branch_with_upstream_creates_branches
run_test test_git_c2b_with_branch_while_in_branch_creates_branches
run_test test_git_c2b_with_branch_with_upstream_while_in_other_branch_creates_branches
run_test test_git_c2b_with_count_creates_correctly_numbered_branches
run_test test_git_c2b_updates_branches
