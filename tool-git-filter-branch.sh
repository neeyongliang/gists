#! /bin/bash

OLD_EMAIL="tuowazi@outlook.com"
NEW_EMAIL="neeyongliang@gmail.com"
NEW_NAME="asdfnee"

git filter-branch --commit-filter '
        if [ "$GIT_AUTHOR_EMAIL" = "tuowazi@outlook.com" ];
        then
                GIT_AUTHOR_NAME="asdfnee";
                GIT_AUTHOR_EMAIL="neeyongliang@gmail.com";
                git commit-tree "$@";
        else
                git commit-tree "$@";
        fi' HEAD
