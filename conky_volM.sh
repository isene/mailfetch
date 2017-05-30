#!/bin/bash

amixer get Master | awk -F' ' '/off/ { print $6 }'
