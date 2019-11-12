#!/bin/bash

TERM="xterm"

watch "echo 'open ssh connections\n\n' && ls -rt /home/user/.ssh/_batch/open_conn"
