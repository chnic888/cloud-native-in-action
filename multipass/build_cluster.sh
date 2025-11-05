#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <instance_number> <is_replace_source>"
    exit 1
fi

node_count=$1
replace_source=$2
INVENTORY_PATH="./inventory"

function clean_up() {
    rm -f "${INVENTORY_PATH}"
    rm -f "./multipass/sources.list"
    rm -f "./multipass/hosts"
}

function pre_check() {
    echo "Check OS and Arch..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
        ARCH=$(uname -m)
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        ARCH=$(uname -m)
    else
        echo "Unknown OS and architecture..."
        exit 1
    fi

    echo "${OS}_${ARCH}"
}

function generate_source_list() {
    if [[ "$replace_source" == "false" ]]; then
        echo "Skip generate sources.list and will use default config..."
        return 0
    fi

    if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        cp "./multipass/sources.list.aarch64" "./multipass/sources.list"
    else
        cp "./multipass/sources.list.amd64" "./multipass/sources.list"
    fi
}

function launch_cluster() {
    echo "Start to launch cluster..."
    cat ~/.ssh/id_rsa.pub > ./1.tmp
    echo "[kvms]" > "${INVENTORY_PATH}"
    start_index=0

    for ((i = start_index; i < node_count; i++));
    do
        instance="kvm$i"

        if [ ${#i} -eq 1 ]; then
            instance="kvm0$i"
        fi

        if multipass list | grep -q $instance; then
            continue
        fi

        echo "Launch Kubernetes VM instance ${instance}..."
        multipass launch jammy --name $instance -c 1 -m 2G -d 10G

        echo "Copy id_rsa.pub to ${instance}..."
        multipass transfer ./1.tmp $instance:/tmp/id_rsa.pub
        multipass exec $instance -- bash -c 'mkdir -p ~/.ssh && cat /tmp/id_rsa.pub >> ~/.ssh/authorized_keys && rm /tmp/id_rsa.pub'

        ip=$(multipass exec $instance -- bash -c "hostname -I | cut -d ' ' -f 1")
        echo "Write IP ${ip} to inventory and hosts files..."
        echo "${instance} ansible_host=${ip}" >> "${INVENTORY_PATH}"
        echo "${ip} ${instance}" >> "./multipass/hosts"

        echo "Launch Kubernetes VM instance ${instance} successfully..."
    done

    rm "./1.tmp"
}

function install_vm() {
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory ./multipass/install_vm.yaml --extra-vars "{'replace_source': $replace_source}"
    sleep 5
}

function restart_vm() {
    for ((i = start_index; i <= node_count; i++));
    do
        local vm_name="kvm$i"
        if [ ${#i} -eq 1 ]; then
            vm_name="kvm0$i"
        fi

        echo "Restart vm ${vm_name}..."
        multipass restart "$vm_name"
        sleep 1
    done
}

clean_up
pre_check
generate_source_list
launch_cluster
install_vm
restart_vm