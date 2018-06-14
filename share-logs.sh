#!/bin/bash

{ # Make sure the entire program is downloaded before executing code
    mkdir /tmp/share-logs.data

    export LC_ALL=en_US.UTF-8

    echo "---> Running eopkg check..."
    # sudo eopkg check -N 2>&1 | tee /tmp/share-logs.data/eopkg-check.log

    echo "---> Collecting journalctl log files from the last 5 boots..."
    sudo journalctl -b > /tmp/share-logs.data/journalctl.0.log
    sudo journalctl -b 1 > /tmp/share-logs.data/journalctl.1.log
    sudo journalctl -b 2 > /tmp/share-logs.data/journalctl.2.log
    sudo journalctl -b 3 > /tmp/share-logs.data/journalctl.3.log
    sudo journalctl -b 4 > /tmp/share-logs.data/journalctl.4.log

    cd /tmp
    tar czf share-logs.tar.gz share-logs.data

    echo "---> Uploading collected data, PLEASE SHARE THE FOLLOWING LINK:"
    curl --upload-file ./share-logs.tar.gz https://transfer.sh/share-logs.tar.gz
    echo # Add a trailing new line
}