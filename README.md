# Blender + Claude

Control Blender with natural language through Claude AI using the Model Context Protocol (MCP).

## What this Flake does

Integrates Claude Desktop with Blender so you can:
- Create and modify 3D objects by talking to Claude
- Generate scenes, lighting, and materials through conversation
- Automate Blender workflows with AI assistance

## Prerequisites

- **Blender** installed (Flatpak or system package)
- **Nix** with flakes enabled

## Quick Start

```bash
# 1. Enter the environment
nix develop

# 2. Run setup (first time only)
setup-claude-config
setup-blender-addon

# 3. Launch Claude Desktop (in devshell)
claude-desktop

# 4. Launch Blender (another terminal)
blender
```

### In Blender

1. **Edit → Preferences → Add-ons**
2. Search for **"Blender MCP"** and enable it
3. Press **N** to open the sidebar
4. Click **BlenderMCP** tab → **Connect to Claude**
5. Claude should be connected, try prompting.

## Supported Installations

This flake automatically detects:
- **Flatpak Blender** (Steam Deck, Flatpak-based distros)
- **System Blender** (traditional package managers)

## Commands

| Command | Description |
|---------|-------------|
| `setup-claude-config` | Configure Claude Desktop MCP |
| `setup-blender-addon` | Install Blender addon |
| `claude-desktop` | Launch Claude Desktop |

## Configuration Paths

| File | Location |
|------|----------|
| Claude config | `~/.config/Claude/claude_desktop_config.json` |
| Blender addon (system) | `~/.config/blender/<version>/scripts/addons/` |
| Blender addon (Flatpak) | `~/.var/app/org.blender.Blender/config/blender/<version>/scripts/addons/` |

## Troubleshooting

### Blender not found
```bash
# Check installation
flatpak list | grep Blender  # For Flatpak
which blender                 # For system install
```

### Addon not appearing
```bash
# Reinstall
setup-blender-addon

# Then in Blender: Edit → Preferences → Add-ons → Refresh
```

### Connection failed
1. Restart Claude Desktop
2. In Blender: Click **"Connect to Claude"** again
3. Check for the connection in Claude Desktop settings

### Claude Desktop won't start
```bash
# Validate config
cat ~/.config/Claude/claude_desktop_config.json | jq

# Regenerate
setup-claude-config
```

## Other

### One-time run
```bash
nix run github:yourusername/blender-claude-mcp
```

### System installation
```nix
{
  inputs.blender-claude.url = "github:yourusername/blender-claude-mcp";
  
  outputs = { self, nixpkgs, blender-claude, ... }: {
    environment.systemPackages = [
      blender-claude.packages.x86_64-linux.claude-desktop
    ];
  };
}
```

## What Gets Installed

- **Claude Desktop** (with FHS environment for MCP)
- **UV** (Python package manager for MCP server)
- **Python 3.11** (Blender scripting)
- **Blender MCP addon** (downloaded from upstream)

**Note:** Blender itself is NOT installed - uses your existing installation!

## How It Works

1. **Blender MCP addon** runs a local server in Blender
2. **Claude Desktop** connects to it via MCP protocol
3. **uvx blender-mcp** acts as the bridge
4. Claude sends commands → MCP server → Blender Python API

## Credits

- [Blender MCP](https://github.com/ahujasid/blender-mcp) - Siddharth Ahuja
- [Claude Desktop Linux Flake](https://github.com/k3d3/claude-desktop-linux-flake) - k3d3
- [Anthropic](https://www.anthropic.com/) - Claude AI

## License

MIT License.
