#!/bin/bash

# A script that power cycles selected Pi(s)

declare -A name_id_map

# Map content
name_id_map[red1]=18
name_id_map[red2]=20
name_id_map[red3]=22
name_id_map[red4]=24
name_id_map[red5]=26
name_id_map[red6]=28
name_id_map[red7]=30
name_id_map[red8]=32

name_id_map[blue1]=2
name_id_map[blue2]=4
name_id_map[blue3]=6
name_id_map[blue4]=8
name_id_map[blue5]=10
name_id_map[blue6]=12
name_id_map[blue7]=14
name_id_map[blue8]=16

name_id_map[hpc_master]=13

# Literally just a single command
# But hey, you don't have to remember it!

if [ "$#" -ne 1 ]; then
    echo "Error: Give PI name"
    exit 1
fi

Pi_name=$1

# Ask for confirmation
    read -p "Are you sure you want to restart "$Pi_name"? (y/n) " -n 1 -r
    echo    # move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
    fi

if [ "$Pi_name" = "all" ]; then
    echo "Restarting all Raspberry Pis (excluding hpc_master)..."
    for name in "${!name_id_map[@]}"; do
        if [ "$name" != "hpc_master" ]; then
            ID=${name_id_map[$name]}
            echo "Restarting $name ($ID)"
            sshpass -p '<password>' ssh ubnt@192.168.2.254 "swctrl poe restart id $ID" &
            wait
            sleep 5
        fi
    done
    exit 0
fi

# Check if name is valid
if [[ -z "${name_id_map[$Pi_name]}" ]]; then
    if [ "$Pi_name" = "red" ]; then
                Pi_num=1
                Pi_ID=18
                for ((i=1; i<=8; i++)); do
                        echo "Restarting red"$Pi_num" ("$Pi_ID")"
                        # echo "swctrl poe restart id $Pi_ID"
                        sshpass -p '<password>' ssh ubnt@192.168.2.254 "swctrl poe restart id $Pi_ID" &
                        ((Pi_num++))
                        ((Pi_ID += 2))
                        wait
                        sleep 5  # Wait for 5 seconds
                done

    elif [ "$Pi_name" = "blue" ]; then
                Pi_num=1
                Pi_ID=2
                for ((i=1; i<=8; i++)); do
                        #echo "swctrl poe restart id $Pi_ID"
                        echo "Restarting blue"$Pi_num" ("$Pi_ID")"
                        sshpass -p '<password>' ssh ubnt@192.168.2.254 "swctrl poe restart id $Pi_ID" &
                        ((Pi_num++))
                        ((Pi_ID += 2))
                        wait
                        sleep 5  # Wait for 5 seconds
                done

    else
        echo "Error: Invalid name"
        exit 1
    fi

else

    # Print Pi ID (debug)
    # echo "${name_id_map[$Pi_name]}"

    # Print command for debug
    # echo "swctrl poe restart id ${name_id_map[$Pi_name]}"

    sshpass -p '<password>' ssh ubnt@192.168.2.254 "swctrl poe restart id ${name_id_map[$Pi_name]}"
fi