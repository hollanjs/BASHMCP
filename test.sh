#!/bin/bash
#
# Test script for BASHMCP
#

set -u

# Setup
BASHMCP_ROOT=$(mktemp -d)
echo "Test root: $BASHMCP_ROOT"

# Helper to create JSON-RPC requests
function req() {
    local id="$1"
    local method="$2"
    local params="$3"
    
    if [[ -z "$params" ]]; then
        echo "{\"jsonrpc\":\"2.0\",\"id\":$id,\"method\":\"$method\",\"params\":{}}"
    else
        echo "{\"jsonrpc\":\"2.0\",\"id\":$id,\"method\":\"$method\",\"params\":$params}"
    fi
}

function tool_call() {
    local id="$1"
    local name="$2"
    local args="$3"
    
    echo "{\"jsonrpc\":\"2.0\",\"id\":$id,\"method\":\"tools/call\",\"params\":{\"name\":\"$name\",\"arguments\":$args}}"
}

# Test cases
{
    req 1 "initialize" ""
    echo "{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}"
    req 2 "tools/list" ""
    tool_call 3 "dir_create" "{\"path\":\"a/b\"}"
    tool_call 4 "file_create" "{\"path\":\"a/b/x.txt\",\"content\":\"héllo\"}"
    tool_call 5 "file_update" "{\"path\":\"a/b/x.txt\",\"content\":\" world\",\"append\":true}"
    tool_call 6 "file_read" "{\"path\":\"a/b/x.txt\"}"
    tool_call 7 "dir_list" "{\"recursive\":true}"
    tool_call 8 "file_read" "{\"path\":\"../../etc/passwd\"}"
    tool_call 9 "dir_delete" "{\"path\":\"a\"}"
    tool_call 10 "file_delete" "{\"path\":\"a/b/x.txt\"}"
    tool_call 11 "dir_delete" "{\"path\":\"a\",\"recursive\":true}"
    tool_call 12 "dir_list" "{}"
} | BASHMCP_ROOT="$BASHMCP_ROOT" bash "$(dirname "$0")/bashmcp.sh" | while read -r line; do
    len=${#line}
    if [[ $len -gt 300 ]]; then
        echo "${line:0:300}..."
    else
        echo "$line"
    fi
done

# Cleanup
rm -rf "$BASHMCP_ROOT"

