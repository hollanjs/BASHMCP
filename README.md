# BASHMCP - Bash MCP Server

A minimal MCP (Model Context Protocol) server implementation in pure Bash for Linux/Unix systems. No dependencies beyond standard Unix utilities.

## Features

- **File CRUD Operations**: Create, read, update, delete files
- **Directory Management**: Create, list, and delete directories
- **File Operations**: Move and copy files/directories
- **Security**: All operations sandboxed to a root directory to prevent path traversal attacks
- **Minimal Dependencies**: Uses only standard Bash and Unix utilities (no Python, Node.js, or other runtimes required)

## Tools Provided

### File Operations

- **file_create**: Create a new file with content
- **file_read**: Read a text file
- **file_update**: Update or append to a file
- **file_delete**: Delete a file
- **file_move**: Move or rename a file/directory
- **file_copy**: Copy a file or directory

### Directory Operations

- **dir_create**: Create a directory (with parents)
- **dir_list**: List directory contents (optionally recursive)
- **dir_delete**: Delete a directory

## Installation

1. Clone or download this repository
2. Make the script executable:
   ```bash
   chmod +x bashmcp.sh
   ```

3. Set up in VS Code's Copilot settings. Add to your `.mcp.json` or settings:
   ```json
   {
     "mcpServers": {
       "bashmcp": {
         "type": "stdio",
         "command": "bash",
         "args": ["/path/to/bashmcp.sh"],
         "env": {
           "BASHMCP_ROOT": "/path/to/your/workspace"
         }
       }
     }
   }
   ```

## Usage

### Via Environment Variable

```bash
export BASHMCP_ROOT=/path/to/sandbox
bash bashmcp.sh
```

### Via Command Line

```bash
bash bashmcp.sh --root /path/to/sandbox
```

### Default Behavior

If no root is specified, the current working directory is used.

## Example Operations

Once configured as an MCP server, you can use these tools:

**Create a file:**
```json
{
  "name": "file_create",
  "arguments": {
    "path": "notes/todo.txt",
    "content": "- Buy milk\n- Write code"
  }
}
```

**Read a file:**
```json
{
  "name": "file_read",
  "arguments": {
    "path": "notes/todo.txt"
  }
}
```

**Create nested directories:**
```json
{
  "name": "dir_create",
  "arguments": {
    "path": "project/src/components"
  }
}
```

**List directory with recursion:**
```json
{
  "name": "dir_list",
  "arguments": {
    "path": "project",
    "recursive": true
  }
}
```

## Security

- All paths are validated to ensure they stay within the configured root directory
- Path traversal attempts (e.g., `../../../etc/passwd`) are blocked
- Root directory cannot be deleted
- All operations work relative to the configured root

## Testing

Run the test script to verify functionality:

```bash
bash test.sh
```

The test script will:
1. Create a temporary directory
2. Run various file and directory operations
3. Display results
4. Clean up

## Compatibility

- Requires Bash 4.0+
- Works on Linux, macOS, and other Unix-like systems
- Uses only standard POSIX utilities (find, mkdir, rm, cp, mv, etc.)

## Protocol

Implements MCP 2.0 stdio protocol with newline-delimited JSON-RPC messages.

### Supported Methods

- `initialize` - Server initialization
- `ping` - Ping/heartbeat
- `tools/list` - List available tools
- `tools/call` - Invoke a tool

## Performance Considerations

- Designed for simplicity over performance
- JSON parsing uses basic grep/string manipulation
- Suitable for general file operations and small to medium workloads
- Not optimized for large directory operations or high-frequency calls

## Comparison to PSMCP

This is a Bash reimplementation of the PSMCP (PowerShell MCP) server with identical functionality:

| Feature | PSMCP | BASHMCP |
|---------|-------|---------|
| Language | PowerShell 7 | Bash 4+ |
| OS | Windows | Linux/Unix/macOS |
| Dependencies | pwsh | Bash, standard Unix tools |
| Tools | 9 | 9 (identical) |
| Security | Path sandboxing | Path sandboxing |
| Protocol | MCP 2.0 | MCP 2.0 |

## License

Same as PSMCP

## Contributing

Improvements and bug reports welcome!
