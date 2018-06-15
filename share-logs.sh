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

check_connection () {
    echo "---> Checking if transfer.sh is reachable..."
    if curl -s https://transfer.sh/ > /dev/null; then
        echo "     Success"
    else
        echo "FATAL ERRROR: https://transfer.sh/ is not reachable!"
        echo "You probably don't have any internet."
        exit 1
    fi
    
}

create_tmp_dir () {
    echo "---> Creating tmp dir..."
    tmpdir="$(mktemp -d -t share-logs.XXXXXXXXXX)"
    echo "     NOTE: All files will be stored in $tmpdir"
}

send_logs () {
    echo
    echo "WARNING: The following system data may be uploaded:"
    echo " - The full log files from the last 5 boots"
    echo " - Hardware information"
    echo " - Integrity of installed packages"
    echo
    echo "Are you sure you want to continue?"
    read -p "Press enter to continue, CTRL+C to cancel..."
    echo

    echo "Would you like to check the integrity of installed packages?"
    read -p "   (takes a minute or two!) [Y/n] " yn
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
    inxi -F | tee "$tmpdir/inxi"
    lspci | tee "$tmpdir/lspci"
    lsusb | tee "$tmpdir/lsusb"
    linux-driver-management status | tee "$tmpdir/linux-driver-management"

    cd /tmp
    tar czf share-logs.tar.gz $tmpdir

    echo "---> Uploading collected data, PLEASE SHARE THE FOLLOWING LINK:"
    curl --upload-file ./share-logs.tar.gz https://transfer.sh/share-logs.tar.gz
    echo # Add a trailing new line
}

record_command() {
    clear # Clear to screen to make it clear that we are launching a sub shell
    echo "--> The output of whatever happens in the following shell will be uploaded to"
    echo "--> transfer.sh. You will be given an option to cancel the upload."
    echo "--> Type exit when you are done."

    bash | tee "$tmpdir/bash.sh"

    read -p "--> Command recorded, press enter to upload, CTRL+C to cancel..." throw_away_var
    echo "---> Uploading collected data, PLEASE SHARE THE FOLLOWING LINK:"
    curl --upload-file $tmpdir/bash.sh https://transfer.sh/bash.sh
    echo # Add a trailing new line
}

# Ensure that child processes always output in English.
export LC_ALL=en_US.UTF-8

if [ "$1" == "record" ]; then
    check_connection
    create_tmp_dir
    record_command
elif [ "$1" == "basic" ]; then
    check_connection
    create_tmp_dir
    send_logs
else
    echo "Usuage: bash share-logs.sh <command>"
    echo
    echo "Commands:"
    echo "  basic       Collect end send basic logs and system info. Use this if unsure."
    echo "  record      Record the output of a custom command."
    echo
    echo "Credits:"
    echo "  Noah Loomans (mrCyborg on IRC) for creating this script"
fi
