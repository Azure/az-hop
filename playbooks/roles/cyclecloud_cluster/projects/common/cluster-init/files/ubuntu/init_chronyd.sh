#!/bin/bash
if ! dpkg -l chrony; then
  apt-get install -y chrony
fi
