#!/bin/bash

function install_micro8s() {
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory ./microk8s/install_micro8s.yaml
}

install_micro8s