#!/bin/bash

amixer get Master | awk -F'[]%[]' '/%/ { print $2"%" }'
