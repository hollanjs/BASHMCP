#!/bin/bash
#
# BASHMCP: Minimal MCP server (stdio, newline-delimited JSON-RPC 2.0) in pure Bash.
# File CRUD + directory management, sandboxed to a root directory.
# Root: env BASHMCP_ROOT, or the --root parameter, or the current directory.
#
# Usage: bashmcp.sh [--root /path/to/root]
#

set -u

ROOT="${BASHMCP_ROOT:-.}"
PROTOCOL_VERSION="2025-06-18"

# Resolve to absolute path and normalize
resolve_root() {
    cd "$1" 2>/dev/null || return 1
    pwd
}

ROOT_FULL=$(resolve_root "$ROOT") || {
    echo "[BASHMCP] Error: Cannot resolve root directory '$ROOT'" >&2
    exit 1
}

log() {
    echo "[BASHMCP] $*" >&2
}

# Send JSON response
send_json() {
    local obj="$1"
    echo "$obj"
}

# Resolve a user path inside the root; error if it escapes.
resolve_safe_path() {
    local user_path="$1"
    
    if [[ -z "$user_path" ]]; then
        echo "path is required" >&2
        return 1
    fi
    
    # Handle '.' specially
    if [[ "$user_path" == "." ]]; then
        echo "$ROOT_FULL"
        return 0
    fi
    
    # Build the path by combining root with user path
    local full
    if [[ "$user_path" = /* ]]; then
        full="$user_path"
    else
        full="$ROOT_FULL/$user_path"
    fi
    
    # Use Python or perl to resolve symlinks and .. safely, fallback to bash
    if command -v python3 &> /dev/null; then
        full=$(python3 -c "import os; print(os.path.abspath('$full'))" 2>/dev/null) || full=$(cd "$(dirname "$full")" 2>/dev/null && pwd)/"$(basename "$full")" || true
    else
        # Bash-only canonicalization: replace /..  and /. patterns
        while [[ "$full" == *"/.."* ]] || [[ "$full" == *"/."* ]]; do
            full=$(echo "$full" | sed 's#/\./##g')
            full=$(echo "$full" | sed 's#/[^/]*/\.\.##g')
        done
        full="${full%/.}"
        # Remove any trailing slash
        full="${full%/}"
    fi
    
    # Normalize ROOT_FULL for comparison
    local root_norm="${ROOT_FULL%/}"
    
    # Ensure it's within root
    if [[ "$full" != "$root_norm" ]] && [[ "$full" != "$root_norm"/* ]]; then
        echo "Path '$user_path' is outside the allowed root '$ROOT_FULL'" >&2
        return 1
    fi
    
    echo "$full"
}

# Return relative path
rel_path() {
    local full="$1"
    if [[ "$full" == "$ROOT_FULL" ]]; then
        echo "."
    else
        echo "${full#$ROOT_FULL/}"
    fi
}

# Create simple JSON schema
schema() {
    local props="$1"
    local required="${2:-}"
    
    if [[ -z "$required" ]]; then
        echo "{\"type\":\"object\",\"properties\":$props,\"required\":[]}"
    else
        echo "{\"type\":\"object\",\"properties\":$props,\"required\":[$required]}"
    fi
}

# Define tools
create_tools_list() {
    cat << 'EOF'
[
  {
    "name": "file_create",
    "description": "Create a new file (fails if it exists unless overwrite=true).",
    "inputSchema": {
      "type": "object",
      "properties": {
        "path": {"type": "string", "description": "File path relative to root"},
        "content": {"type": "string", "description": "File content"},
        "overwrite": {"type": "boolean", "description": "Overwrite if exists"}
      },
      "required": ["path", "content"]
    }
  },
  {
    "name": "file_read",
    "description": "Read a text file.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "path": {"type": "string", "description": "File path relative to root"}
      },
      "required": ["path"]
    }
  },
  {
    "name": "file_update",
    "description": "Replace the content of an existing file, or append to it.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "path": {"type": "string", "description": "File path relative to root"},
        "content": {"type": "string", "description": "New content"},
        "append": {"type": "boolean", "description": "Append instead of replace"}
      },
      "required": ["path", "content"]
    }
  },
  {
    "name": "file_delete",
    "description": "Delete a file.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "path": {"type": "string", "description": "File path relative to root"}
      },
      "required": ["path"]
    }
  },
  {
    "name": "file_move",
    "description": "Move or rename a file or directory.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "source": {"type": "string", "description": "Source path"},
        "destination": {"type": "string", "description": "Destination path"}
      },
      "required": ["source", "destination"]
    }
  },
  {
    "name": "file_copy",
    "description": "Copy a file or directory.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "source": {"type": "string", "description": "Source path"},
        "destination": {"type": "string", "description": "Destination path"}
      },
      "required": ["source", "destination"]
    }
  },
  {
    "name": "dir_create",
    "description": "Create a directory (including parents).",
    "inputSchema": {
      "type": "object",
      "properties": {
        "path": {"type": "string", "description": "Directory path relative to root"}
      },
      "required": ["path"]
    }
  },
  {
    "name": "dir_list",
    "description": "List directory contents.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "path": {"type": "string", "description": "Directory path (default \".\")"},
        "recursive": {"type": "boolean", "description": "Recurse into subdirectories"}
      },
      "required": []
    }
  },
  {
    "name": "dir_delete",
    "description": "Delete a directory (non-empty requires recursive=true).",
    "inputSchema": {
      "type": "object",
      "properties": {
        "path": {"type": "string", "description": "Directory path relative to root"},
        "recursive": {"type": "boolean", "description": "Delete contents too"}
      },
      "required": ["path"]
    }
  }
]
EOF
}

# Get string value from JSON via jq (handles escapes, commas, braces, newlines)
json_get_string() {
    local json="$1"
    local key="$2"
    jq -r --arg k "$key" '.[$k] // empty | if type == "string" then . else tojson end' <<<"$json"
}

# Like json_get_string but stores into a global (JSON_VALUE), preserving trailing newlines
json_get_raw() {
    local json="$1"
    local key="$2"
    JSON_VALUE=$(jq -j --arg k "$key" '.[$k] // empty | if type == "string" then . else tojson end' <<<"$json"; printf x)
    JSON_VALUE="${JSON_VALUE%x}"
}

# Get boolean value from JSON (returns "true" or "false" as string)
json_get_bool() {
    local json="$1"
    local key="$2"
    if [[ "$(jq -r --arg k "$key" '.[$k] // false' <<<"$json")" == "true" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Escape string for JSON
escape_json() {
    local str="$1"
    # Basic escaping: backslash, quotes, newlines, etc.
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

# Invoke a tool
invoke_tool() {
    local name="$1"
    local args="$2"
    local path dest content source recursive append overwrite
    
    case "$name" in
        file_create)
            path=$(json_get_string "$args" "path")
            json_get_raw "$args" "content"; content="$JSON_VALUE"
            overwrite=$(json_get_bool "$args" "overwrite")
            
            path=$(resolve_safe_path "$path") || return 1
            
            if [[ -e "$path" ]] && [[ "$overwrite" != "true" ]]; then
                echo "File already exists: $path" >&2
                return 1
            fi
            
            if [[ -d "$path" ]]; then
                echo "Path is a directory: $path" >&2
                return 1
            fi
            
            mkdir -p "$(dirname "$path")"
            printf '%s' "$content" > "$path"
            echo "Created $(rel_path "$path")"
            ;;
            
        file_read)
            path=$(json_get_string "$args" "path")
            path=$(resolve_safe_path "$path") || return 1
            
            if [[ ! -f "$path" ]]; then
                echo "File not found: $path" >&2
                return 1
            fi
            
            cat "$path"
            ;;
            
        file_update)
            path=$(json_get_string "$args" "path")
            json_get_raw "$args" "content"; content="$JSON_VALUE"
            append=$(json_get_bool "$args" "append")
            
            path=$(resolve_safe_path "$path") || return 1
            
            if [[ ! -f "$path" ]]; then
                echo "File not found: $path" >&2
                return 1
            fi
            
            if [[ "$append" == "true" ]]; then
                printf '%s' "$content" >> "$path"
                echo "Appended to $(rel_path "$path")"
            else
                printf '%s' "$content" > "$path"
                echo "Updated $(rel_path "$path")"
            fi
            ;;
            
        file_delete)
            path=$(json_get_string "$args" "path")
            path=$(resolve_safe_path "$path") || return 1
            
            if [[ ! -f "$path" ]]; then
                echo "File not found: $path" >&2
                return 1
            fi
            
            rm -f "$path"
            echo "Deleted $(rel_path "$path")"
            ;;
            
        file_move)
            source=$(json_get_string "$args" "source")
            dest=$(json_get_string "$args" "destination")
            
            source=$(resolve_safe_path "$source") || return 1
            dest=$(resolve_safe_path "$dest") || return 1
            
            if [[ ! -e "$source" ]]; then
                echo "Source not found: $source" >&2
                return 1
            fi
            
            if [[ -e "$dest" ]]; then
                echo "Destination exists: $dest" >&2
                return 1
            fi
            
            mkdir -p "$(dirname "$dest")"
            mv "$source" "$dest"
            echo "Moved $(rel_path "$source") -> $(rel_path "$dest")"
            ;;
            
        file_copy)
            source=$(json_get_string "$args" "source")
            dest=$(json_get_string "$args" "destination")
            
            source=$(resolve_safe_path "$source") || return 1
            dest=$(resolve_safe_path "$dest") || return 1
            
            if [[ ! -e "$source" ]]; then
                echo "Source not found: $source" >&2
                return 1
            fi
            
            if [[ -e "$dest" ]]; then
                echo "Destination exists: $dest" >&2
                return 1
            fi
            
            mkdir -p "$(dirname "$dest")"
            cp -r "$source" "$dest"
            echo "Copied $(rel_path "$source") -> $(rel_path "$dest")"
            ;;
            
        dir_create)
            path=$(json_get_string "$args" "path")
            path=$(resolve_safe_path "$path") || return 1
            
            if [[ -f "$path" ]]; then
                echo "A file exists at: $path" >&2
                return 1
            fi
            
            mkdir -p "$path"
            echo "Created directory $(rel_path "$path")"
            ;;
            
        dir_list)
            path=$(json_get_string "$args" "path")
            [[ -z "$path" ]] && path="."
            recursive=$(json_get_bool "$args" "recursive")
            
            path=$(resolve_safe_path "$path") || return 1
            
            if [[ ! -d "$path" ]]; then
                echo "Directory not found: $path" >&2
                return 1
            fi
            
            local output=""
            if [[ "$recursive" == "true" ]]; then
                output=$(find "$path" -mindepth 1 -printf '%y\t%p\t%s\n' | sort)
            else
                output=$(find "$path" -maxdepth 1 -mindepth 1 -printf '%y\t%p\t%s\n' | sort)
            fi
            
            if [[ -z "$output" ]]; then
                echo "(empty)"
            else
                while IFS=$'\t' read -r type file_path size; do
                    if [[ "$type" == "d" ]]; then
                        echo "[dir]  $(rel_path "$file_path")"
                    else
                        echo "[file] $(rel_path "$file_path") ($size bytes)"
                    fi
                done <<< "$output"
            fi
            ;;
            
        dir_delete)
            path=$(json_get_string "$args" "path")
            recursive=$(json_get_bool "$args" "recursive")
            
            path=$(resolve_safe_path "$path") || return 1
            
            if [[ "$path" == "$ROOT_FULL" ]]; then
                echo "Refusing to delete the root directory" >&2
                return 1
            fi
            
            if [[ ! -d "$path" ]]; then
                echo "Directory not found: $path" >&2
                return 1
            fi
            
            if [[ "$recursive" != "true" ]] && [[ -n "$(find "$path" -mindepth 1 -print -quit)" ]]; then
                echo "Directory not empty; set recursive=true" >&2
                return 1
            fi
            
            rm -rf "$path"
            echo "Deleted directory $(rel_path "$path")"
            ;;
            
        *)
            echo "Unknown tool: $name" >&2
            return 1
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)
            ROOT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

log "Started. Root: $ROOT_FULL"

# Main event loop - read JSON-RPC requests
while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue
    
    id=""
    method=""
    error_msg=""
    
    # Parse JSON (simple approach)
    id=$(echo "$line" | grep -o '"id"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' | head -1)
    method=$(json_get_string "$line" "method")
    
    is_request=false
    [[ -n "$id" ]] && [[ -n "$method" ]] && is_request=true
    
    case "$method" in
        initialize)
            resp=$(cat <<EOF
{"jsonrpc":"2.0","id":$id,"result":{"protocolVersion":"$PROTOCOL_VERSION","capabilities":{"tools":{"listChanged":false}},"serverInfo":{"name":"BASHMCP","version":"1.0.0"}}}
EOF
)
            send_json "$resp"
            ;;
            
        ping)
            send_json "{\"jsonrpc\":\"2.0\",\"id\":$id,\"result\":{}}"
            ;;
            
        tools/list)
            tools_list=$(create_tools_list | tr -d '\n')
            resp=$(cat <<EOF
{"jsonrpc":"2.0","id":$id,"result":{"tools":$tools_list}}
EOF
)
            send_json "$resp"
            ;;
            
        tools/call)
            tool_name=$(jq -r '.params.name // empty' <<<"$line")
            tool_args=$(jq -c '.params.arguments // {}' <<<"$line")
            
            # Invoke the tool and capture output
            tool_output=$(invoke_tool "$tool_name" "$tool_args" 2>&1)
            tool_exit=$?
            
            is_error="false"
            if [[ $tool_exit -ne 0 ]]; then
                is_error="true"
            fi
            
            # Escape the output for JSON
            escaped_output=$(escape_json "$tool_output")
            
            resp=$(cat <<EOF
{"jsonrpc":"2.0","id":$id,"result":{"content":[{"type":"text","text":"$escaped_output"}],"isError":$is_error}}
EOF
)
            send_json "$resp"
            ;;
            
        *)
            if [[ "$is_request" == "true" ]]; then
                resp="{\"jsonrpc\":\"2.0\",\"id\":$id,\"error\":{\"code\":-32601,\"message\":\"Method not found: $method\"}}"
                send_json "$resp"
            fi
            ;;
    esac
    
done

log "Stopped"
