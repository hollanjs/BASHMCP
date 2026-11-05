# BASHMCP - Quick Setup Guide

## What is BASHMCP?

BASHMCP is a pure Bash implementation of an MCP (Model Context Protocol) server that provides file and directory management capabilities. It's a Linux/Unix equivalent of PSMCP (PowerShell MCP).

**Key Features:**
- ✅ Zero 3rd party dependencies (uses only bash and standard Unix tools)
- ✅ Works on any Linux/Unix/macOS system
- ✅ Identical API to PSMCP
- ✅ Full path sandboxing (prevents directory traversal attacks)
- ✅ 9 file and directory management tools

## Quick Start

### 1. Clone/Download
The BASHMCP server is now available in `/home/hollanjs/dev/BASHMCP/`

### 2. Verify Installation
```bash
cd /home/hollanjs/dev/BASHMCP
bash test.sh
```

You should see all tests pass with `isError:false` for successful operations and `isError:true` for expected failures (like security violations).

### 3. Configure for VS Code Copilot

Add this to your VS Code Copilot `.mcp.json` configuration:

```json
{
  "mcpServers": {
    "bashmcp": {
      "type": "stdio",
      "command": "bash",
      "args": [
        "/home/hollanjs/dev/BASHMCP/bashmcp.sh"
      ],
      "tools": ["*"],
      "env": {
        "BASHMCP_ROOT": "/path/to/your/workspace"
      }
    }
  }
}
```

Replace `/path/to/your/workspace` with your actual workspace directory.

### 4. Use the Tools

Once configured, you can use these tools with Copilot:

**File Operations:**
- `file_create` - Create files
- `file_read` - Read file contents  
- `file_update` - Update/append file contents
- `file_delete` - Delete files
- `file_move` - Move/rename files
- `file_copy` - Copy files and directories

**Directory Operations:**
- `dir_create` - Create directories (with parents)
- `dir_list` - List directory contents
- `dir_delete` - Delete directories

## Files

- **bashmcp.sh** - Main MCP server implementation
- **test.sh** - Test suite
- **README.md** - Full documentation
- **.mcp.json** - Example configuration file
- **BASHMCP.code-workspace** - VS Code workspace file

## How It Works

1. Copilot sends JSON-RPC 2.0 requests via stdin
2. BASHMCP processes them and returns results via stdout
3. All paths are validated to stay within the configured `BASHMCP_ROOT`
4. Supports full Unicode (including emojis and multibyte characters)

## Comparison: PSMCP vs BASHMCP

| Aspect | PSMCP | BASHMCP |
|--------|-------|---------|
| Language | PowerShell 7 | Bash 4+ |
| OS | Windows | Linux, macOS, Unix |
| Dependencies | PowerShell runtime | Bash (already on most systems) |
| Tools | 9 | 9 (identical) |
| Security | Path sandboxing | Path sandboxing |
| Protocol | MCP 2.0 | MCP 2.0 |
| Setup | pwsh needed | Already have bash |

## Troubleshooting

### Script won't execute
```bash
chmod +x bashmcp.sh
```

### Permission denied errors
Make sure `BASHMCP_ROOT` is readable/writable and the script has execute permission.

### Path resolution issues
Always use paths relative to `BASHMCP_ROOT`. The root is automatically secured - you cannot escape it.

## Performance

- Lightweight: ~15KB script
- Fast startup: No compilation or runtime loading
- Suitable for all file sizes up to system limits
- Optimized for general use cases

## Development

To modify or extend BASHMCP:

1. Edit `bashmcp.sh`
2. Run `test.sh` to verify changes
3. Test with Copilot integration

The code is well-commented and uses simple bash constructs for easy maintenance.

## See Also

- [PSMCP](https://github.com/psmcp/) - Original PowerShell implementation  
- [MCP Protocol Spec](https://modelcontextprotocol.io/)
