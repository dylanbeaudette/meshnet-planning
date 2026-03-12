# meshnet-planning
Meshtastic Node Placement in Complex Terrain



# Mesh Network Described via Viewshed Analysis

![](figures/sierra-viewshed-estimate.png)


# Mesh Network Described via Successful Traceroute

![](figures/sierra-ms-log-graph-01.png)



# Meshtastic CLI

Best CLI meshtastic app seems to be [contact](https://github.com/pdxlocations/contact).


## CLI tools
 - https://github.com/pdxlocations/contact
 - https://github.com/iandennismiller/fmesh
 - https://github.com/ethzero/meshtastic-live-node-list
 - https://www.reddit.com/r/meshtastic/comments/190bw6c/guide_to_install_the_python_cli_and_configure/
 - https://github.com/datagod/meshwatch
 - https://meshtastic.org/docs/software/linux/usage/
 - https://vftp.net/N0ZYC/radio/meshtastic/nodes/node%20resources/meshtastic%20CLI/

## Node DB
 - https://github.com/pdxlocations/meshdb
 - dump node DB: `meshtastic --nodes > file` pretty-printed, but annoying to use
 - careful: `meshtastic --info > file` includes private keys!

## setup meshtastic CLI
 - https://meshtastic.org/docs/software/python/cli/
 - add user to dialout group
 - serial interface on /dev/ttyACM0

## Ubuntu Python Modules
 - python3 -m venv .python-env
 - add "~/.python-env/bin" to PATH 
 - .python-env/bin/pip install --upgrade pytap2
 - .python-env/bin/pip install --upgrade "meshtastic[cli]"
 - .python-env/bin/pip install "contact"
 - .python-env/bin/pip install "meshdb"

## python meshtastic module examples
 - https://github.com/pdxlocations/Meshtastic-Python-Examples/blob/main/print-traceroute.py
 - https://github.com/brad28b/meshtastic-cli-receive-text/blob/main/read_messages_serial.py
 - https://skylosblog.com/posts/meshtastic-client-code/

## Ideas
 - long-term monitoring -> logging -> analysis
 - CLI chat / interaction with nodes vs. phone


