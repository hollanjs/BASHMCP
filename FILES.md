# BASHMCP Project Files

## Project Structure

```
/home/hollanjs/dev/BASHMCP/
├── bashmcp.sh                    # Main MCP server implementation
├── test.sh                       # Comprehensive test suite
├── .mcp.json                     # MCP configuration file
├── BASHMCP.code-workspace        # VS Code workspace file
├── README.md                     # User documentation
├── QUICKSTART.md                 # Quick start guide
├── IMPLEMENTATION_SUMMARY.md     # Technical implementation details
├── COMPARISON.md                 # Comparison with PSMCP
└── FILES.md                      # This file
```

## File Descriptions

### Core Implementation

#### bashmcp.sh (548 lines, 15.8 KB)
The main MCP server implementation. Contains:
- JSON-RPC 2.0 protocol handler
- Path security and validation
- 9 file/directory management tools
- Event loop for stdin/stdout communication
- Unicode/UTF-8 support

**Key functions:**
- `send_json()` - Output JSON responses
- `json_get*()` - Parse JSON parameters
- `resolve_safe_path()` - Validate paths stay in root
- `invoke_tool()` - Execute requested tool
- Main loop - Handle incoming requests

**Entry point:** `bash bashmcp.sh [--root /path]`

### Testing

#### test.sh (59 lines, 1.7 KB)
Comprehensive test suite that verifies:
1. Server initialization
2. Tool listing
3. File creation/reading/updating/deletion
4. Directory creation/listing/deletion
5. Security (path traversal prevention)
6. Error handling
7. Unicode support

**Run with:** `bash test.sh`

All tests should pass with proper success/error status codes.

### Configuration

#### .mcp.json (11 lines, 242 bytes)
VS Code Copilot MCP server configuration. Defines:
- Server type: stdio
- Command: bash
- Arguments: path to bashmcp.sh
- Environment: BASHMCP_ROOT
- Tools: all available

**Usage:** Add to VS Code settings or .mcp.json configuration

#### BASHMCP.code-workspace (7 lines, 60 bytes)
VS Code workspace file. Minimal configuration for:
- Current directory as workspace root
- Empty settings (inherit from VS Code)

**Usage:** `code BASHMCP.code-workspace`

### Documentation

#### README.md (4063 bytes, ~120 lines)
User-facing documentation covering:
- Features and tools provided
- Installation instructions
- Configuration for VS Code
- Usage examples
- Security guarantees
- Testing instructions
- Compatibility information

**Audience:** End users, system administrators

#### QUICKSTART.md (3526 bytes, ~100 lines)
Quick reference guide with:
- Project overview
- Quick setup steps
- VS Code configuration
- File descriptions
- Troubleshooting tips

**Audience:** New users, quick reference

#### IMPLEMENTATION_SUMMARY.md (6328 bytes, ~200 lines)
Technical deep dive covering:
- Architecture and design
- Core components
- Data flow
- JSON parsing approach
- Path resolution strategy
- Tool implementations
- Protocol details
- Testing coverage
- Design decisions
- Security features
- Performance characteristics
- Future enhancements

**Audience:** Developers, maintainers, technical reviewers

#### COMPARISON.md (4500 bytes, ~150 lines)
Detailed comparison with PSMCP including:
- Feature matrix
- Security comparison
- Protocol compliance
- Configuration examples
- Performance benchmarks
- Dependency analysis
- Code complexity
- Error handling
- Use case guidance
- Migration path
- Conclusion and recommendations

**Audience:** Users considering both options, migration planning

#### FILES.md (This file)
Project file structure and description

**Audience:** Anyone exploring the project

## Statistics

```
Total lines:      ~1100 (code + tests)
Code:             548 lines (bashmcp.sh)
Tests:            59 lines (test.sh)
Documentation:    ~550 lines (4 markdown files)

Total file size:  ~35 KB
Scripts:          ~18 KB
Docs:             ~17 KB
Config:           ~300 bytes
```

## Usage Workflow

### 1. Installation Phase
```bash
# Extract/download BASHMCP
cd /home/hollanjs/dev/BASHMCP

# Verify executable
chmod +x bashmcp.sh test.sh

# Run tests
bash test.sh
```

### 2. Configuration Phase
```bash
# Copy .mcp.json configuration
# Update BASHMCP_ROOT to your workspace
# Add to VS Code settings
```

### 3. Runtime Phase
```bash
# Copilot/MCP Client starts the server:
bash bashmcp.sh

# Server reads JSON-RPC from stdin
# Server writes JSON-RPC to stdout
# Server logs to stderr
```

## File Dependencies

```
bashmcp.sh (standalone)
  ├── Uses: Bash 4.0+
  ├── Uses: Standard Unix utils (find, mkdir, rm, cp, mv, grep, sed, cut)
  └── Requires: No external files

test.sh → bashmcp.sh
  ├── Calls: bashmcp.sh with BASHMCP_ROOT env var
  └── Sends: JSON-RPC requests via stdin

.mcp.json
  └── References: bashmcp.sh path

*.md (Documentation, independent)
  └── Reference: Each other for cross-linking

BASHMCP.code-workspace
  └── Standalone configuration
```

## Modification Guide

### Adding a New Tool

1. Add tool definition to `create_tools_list()` function
2. Add case in `invoke_tool()` function
3. Implement using bash + Unix utilities
4. Add test case to `test.sh`
5. Update documentation

### Fixing a Bug

1. Identify in which file/function
2. Add test case demonstrating bug
3. Fix implementation
4. Verify all tests pass
5. Document in commit message

### Improving Performance

Focus areas:
- JSON parsing (currently grep/sed based)
- Path validation (currently multiple sed passes)
- Find usage (currently spawns process for each call)

### Adding Security Features

Check these areas:
- `resolve_safe_path()` - Path validation
- `invoke_tool()` - Operation validation
- Input parameter extraction
- Output escaping/sanitization

## Distribution

### Single File Distribution
- Send only `bashmcp.sh` (includes all functionality)
- User provides environment variable or --root parameter

### Complete Package
- All files in repository
- User gets documentation and tests
- Easier to understand and audit

### Installation Methods
1. **Direct:** Copy bashmcp.sh to $PATH
2. **Repo:** Clone/download entire project
3. **Package:** Create distro-specific package

## Maintenance

### Regular Tasks
- Run tests after any changes
- Keep documentation in sync
- Monitor GitHub issues/discussions
- Update version if needed

### Testing Checklist
- [ ] All 12 tests pass
- [ ] No security warnings
- [ ] Unicode handling works
- [ ] Path validation active
- [ ] Error messages clear

## Support Files

For future enhancements, might add:
- `.gitignore` - Ignore test artifacts
- `LICENSE` - Licensing information
- `CHANGELOG.md` - Version history
- `SECURITY.md` - Security policy
- `.github/workflows/` - CI/CD automation
- `examples/` - Usage examples

## Version Info

```
Project: BASHMCP
Version: 1.0.0
Protocol: MCP 2.0
Status: Production Ready
Last Updated: 2026-11-05
```

## Quick Reference

| Need | File | Section |
|------|------|---------|
| Setup | QUICKSTART.md | Quick Start |
| How it works | README.md | Features |
| Deep dive | IMPLEMENTATION_SUMMARY.md | Architecture |
| vs PSMCP | COMPARISON.md | Overview |
| File locations | FILES.md | This file |
| Configuration | .mcp.json | mcpServers |
| Testing | test.sh | All tests |
| Implementation | bashmcp.sh | Main loop |
