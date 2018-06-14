#!/bin/bash

#
# This is a small program intended to quickly share some useful Solus* logs
# for trouble shooting.
# Run the following command to execute:
#   curl https://noahloomans.com/share-logs.sh | bash
#
# *I'll probably add support for more distros later
#

{ # Make sure the entire program is downloaded before executing code
    mkdir /tmp/share-logs.data

    export LC_ALL=en_US.UTF-8

    echo "---> Checking if transfer.sh is reachable..."
    if curl https://transfer.sh/ > /dev/null; then
        echo "Success"
    else
        echo "FATAL ERRROR: https://transfer.sh/ is not reachable!"
        echo "You probably don't have any internet."
        exit 1
    fi

    read -p "Would you like to run eopkg check? (takes a minute or two!) [Y/n] " yn
    case $yn in
        [Nn]* )
            echo "Slipping eopkg check..."
            ;;
        * ) 
            echo "---> Running eopkg check..."
            sudo eopkg check -N 2>&1 | tee /tmp/share-logs.data/eopkg-check.log
            ;;
    esac

    echo "---> Collecting journalctl log files from the last 5 boots..."
    sudo journalctl -b > /tmp/share-logs.data/journalctl.0.log
    sudo journalctl -b 1 > /tmp/share-logs.data/journalctl.1.log
    sudo journalctl -b 2 > /tmp/share-logs.data/journalctl.2.log
    sudo journalctl -b 3 > /tmp/share-logs.data/journalctl.3.log
    sudo journalctl -b 4 > /tmp/share-logs.data/journalctl.4.log

    echo "---> Collecting hardware information"
    inxi | tee /tmp/share-logs.data/inxi
    lspci | tee /tmp/share-logs.data/lspci
    lsusb | tee /tmp/share-logs.data/lsusb
    linux-driver-management status | tee /tmp/share-logs.data/linux-driver-management

    cd /tmp
    tar czf share-logs.tar.gz share-logs.data

    echo "---> Uploading collected data, PLEASE SHARE THE FOLLOWING LINK:"
    curl --upload-file ./share-logs.tar.gz https://transfer.sh/share-logs.tar.gz
    echo # Add a trailing new line
}
