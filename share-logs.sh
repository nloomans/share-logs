#!/bin/bash

#
# This is a small program intended to quickly share some useful Solus* logs
# for trouble shooting.
# Run the following command to execute:
#   wget -N https://noahloomans.com/share-logs.sh
#   bash share-logs.sh
#
# *I'll probably add support for more distros later
#
# AVAILABLE FLAGS:
#  c  --  Run a command and upload the output
#

send_logs () {
    tmpdir="$(mktemp -d)"

    export LC_ALL=en_US.UTF-8

    echo "---> Checking if transfer.sh is reachable..."
    if curl https://transfer.sh/ > /dev/null; then
        echo "Success"
    else
        echo "FATAL ERRROR: https://transfer.sh/ is not reachable!"
        echo "You probably don't have any internet."
        exit 1
    fi

    echo

    echo "WARNING: The following system data may be uploaded:"
    echo " - The full log files from the last 5 boots"
    echo " - Hardware information"
    echo " - Integrity of installed packages"
    echo
    echo "Are you sure you want to continue?"
    read -p "Press enter to continue, CTRL+C to cancel..."

    echo

    read -p "Would you like to run eopkg check? (takes a minute or two!) [Y/n] " yn
    case $yn in
        [Nn]* )
            echo "Slipping eopkg check..."
            ;;
        * ) 
            echo "---> Running eopkg check..."
            sudo eopkg check -N 2>&1 | tee "$tmpdir/eopkg-check.log"
            ;;
    esac

    echo "---> Collecting journalctl log files from the last 5 boots..."
    sudo journalctl -b > "$tmpdir/journalctl.0.log"
    sudo journalctl -b 1 > "$tmpdir/journalctl.1.log"
    sudo journalctl -b 2 > "$tmpdir/journalctl.2.log"
    sudo journalctl -b 3 > "$tmpdir/journalctl.3.log"
    sudo journalctl -b 4 > "$tmpdir/journalctl.4.log"

    echo "---> Collecting hardware information"
    inxi | tee "$tmpdir/inxi"
    lspci | tee "$tmpdir/lspci"
    lsusb | tee "$tmpdir/lsusb"
    linux-driver-management status | tee "$tmpdir/linux-driver-management"

    cd /tmp
    tar czf share-logs.tar.gz $tmpdir

    echo "---> Uploading collected data, PLEASE SHARE THE FOLLOWING LINK:"
    curl --upload-file ./share-logs.tar.gz https://transfer.sh/share-logs.tar.gz
    echo # Add a trailing new line
}

send_command_output() {
    tmpdir="$(mktemp -d)"

    echo "--> The output of whatever happens in the following shell will be uploaded to"
    echo "--> transfer.sh. You will be given an option to cancel the upload."
    echo "--> Type exit when you are done."

    bash | tee "$tmpdir/bash.sh"

    read -p "--> Command recorded, press enter to upload, CTRL+C to cancel..." throw_away_var
    echo "---> Uploading collected data, PLEASE SHARE THE FOLLOWING LINK:"
    curl --upload-file $tmpdir/bash.sh https://transfer.sh/bash.sh
    echo # Add a trailing new line
}

{ # Make sure the entire program is downloaded before executing code
    echo "Please enter any flags you are asked to enter."
    echo "If unsure press enter"
    read -p "FLAGS: " flags

    if [ "$flags" = "c" ]; then
        send_command_output;
        exit 0
    fi

    send_logs;
}
