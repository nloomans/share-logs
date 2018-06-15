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
# Fork me on GitHub:
#   https://github.com/nloomans/share-logs
#

check_connection () {
    echo "---> Checking if transfer.sh is reachable..."
    if curl -s https://transfer.sh/ > /dev/null; then
        echo "     Success"
    else
        echo "FATAL ERROR: https://transfer.sh/ is not reachable!"
        echo "Data not uploaded."
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
    echo "   (probably contains identifying information!)"
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
            echo "Skipping eopkg check..."
            ;;
        * ) 
            echo "---> Running eopkg check..."
            sudo eopkg check -N 2>&1 | tee "$tmpdir/eopkg-check.log"
            ;;
    esac

    echo "---> Collecting journalctl log files from the last 5 boots..."
    sudo journalctl -b 2>&1 > "$tmpdir/journalctl.0.log"
    sudo journalctl -b 1 2>&1 > "$tmpdir/journalctl.1.log"
    sudo journalctl -b 2 2>&1 > "$tmpdir/journalctl.2.log"
    sudo journalctl -b 3 2>&1 > "$tmpdir/journalctl.3.log"
    sudo journalctl -b 4 2>&1 > "$tmpdir/journalctl.4.log"

    echo "---> Collecting hardware information"
    inxi -F 2>&1 | tee "$tmpdir/inxi"
    lspci 2>&1 | tee "$tmpdir/lspci"
    lsusb 2>&1 | tee "$tmpdir/lsusb"
    linux-driver-management status 2>&1 | tee "$tmpdir/linux-driver-management"

    cd /tmp
    tar czf share-logs.tar.gz $tmpdir

    upload_data ./share-logs.tar.gz ".tar.gz"
}

record_command () {
    clear # Clear to screen to make it clear that we are launching a sub shell
    echo "--> The output of whatever happens in the following shell will be uploaded to"
    echo "--> transfer.sh. You will be given an option to cancel the upload."
    echo "--> Type exit when you are done."

    # The default .bashrc screws up the logging info.
    bash --noprofile --norc -i 2>&1 | tee "$tmpdir/bash.sh"

    read -p "--> Command recorded, press enter to upload, CTRL+C to cancel..." throw_away_var
    upload_data "$tmpdir/bash.sh" ".sh"
}

upload_data () {
    echo "---> Uploading collected data, data will be downloadable for 1 hour"
    echo "     PLEASE SHARE THE FOLLOWING LINK:"
    curl -H "Max-Downloads: 5" -H "Max-Days: 0.042" --upload-file "$1" "https://transfer.sh/share-logs$2"
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
    echo "Usage: bash share-logs.sh <command>"
    echo
    echo "Commands:"
    echo "  basic       Collect end send basic logs and system info. Use this if unsure."
    echo "  record      Record the output of a custom command."
    echo
    echo "Credits:"
    echo "  Noah Loomans (mrCyborg on IRC) for creating this script"
fi
