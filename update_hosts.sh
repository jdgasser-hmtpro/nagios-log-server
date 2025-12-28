#!/bin/bash

# Ajoute le contenu de /mnt/config/custom_hosts à /etc/hosts
if [ -f /usr/local/nagioslogserver/hosts ]; then
    cat /usr/local/nagioslogserver/hosts >> /etc/hosts
fi

# Affiche le résultat (optionnel)
cat /etc/hosts
