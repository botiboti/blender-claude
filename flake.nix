{
  description = "Claude MCP and Claude Desktop for Blender";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, claude-desktop }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Script to download and setup the Blender MCP addon
        setupAddon = pkgs.writeShellScriptBin "setup-blender-addon" ''
          #!/usr/bin/env bash
          set -e

          ADDON_URL="https://raw.githubusercontent.com/ahujasid/blender-mcp/main/addon.py"

          # Detect Blender version - works with both Flatpak and system installs
          if ${pkgs.flatpak}/bin/flatpak list 2>/dev/null | grep -q org.blender.Blender; then
            echo "Detected Flatpak Blender installation"
            BLENDER_VERSION=$(${pkgs.flatpak}/bin/flatpak run org.blender.Blender --version 2>/dev/null | grep -oP 'Blender \K[0-9]+\.[0-9]+' | head -1)
            # Flatpak Blender uses a different config path
            ADDON_DIR="$HOME/.var/app/org.blender.Blender/config/blender"
          elif command -v blender &> /dev/null; then
            echo "Detected system Blender installation"
            BLENDER_VERSION=$(blender --version 2>/dev/null | grep -oP 'Blender \K[0-9]+\.[0-9]+' | head -1)
            ADDON_DIR="$HOME/.config/blender"
          else
            echo "⚠ Error: Blender not found"
            echo "Please ensure Blender is installed (Flatpak or system)"
            exit 1
          fi

          SCRIPTS_DIR="$ADDON_DIR/$BLENDER_VERSION/scripts/addons"

          echo "Detected Blender version: $BLENDER_VERSION"
          echo "Setting up Blender MCP addon..."
          mkdir -p "$SCRIPTS_DIR"

          echo "Downloading addon.py..."
          ${pkgs.curl}/bin/curl -L "$ADDON_URL" -o "$SCRIPTS_DIR/blender_mcp_addon.py"

          echo ""
          echo "✓ Addon downloaded to: $SCRIPTS_DIR/blender_mcp_addon.py"
          echo ""
          echo "Next steps:"
          echo "1. Run 'claude-desktop', and ensure it is connected to your Claude account"
          echo "2. Launch Blender"
          echo "3. Go to Edit > Preferences > Add-ons"
          echo "4. Search for 'Blender MCP' (should be auto-detected)"
          echo "5. Enable the addon by checking the box"
          echo "6. Press N in the 3D view to show the sidebar"
          echo "7. Find the 'BlenderMCP' tab and click 'Connect to Claude'"
        '';

        # Script to setup Claude Desktop config
        setupClaudeConfig = pkgs.writeShellScriptBin "setup-claude-config" ''
          #!/usr/bin/env bash
          set -e

          CONFIG_DIR="$HOME/.config/Claude"
          CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

          echo "Setting up Claude Desktop MCP configuration..."
          mkdir -p "$CONFIG_DIR"

          if [ -f "$CONFIG_FILE" ]; then
            echo "Backing up existing config to $CONFIG_FILE.backup"
            cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
          fi

          cat > "$CONFIG_FILE" << 'EOF'
          {
            "mcpServers": {
              "blender": {
                "command": "uvx",
                "args": [
                  "blender-mcp"
                ]
              }
            }
          }
          EOF

          echo ""
          echo "✓ Claude Desktop config created at: $CONFIG_FILE"
          echo ""
          echo "Configuration complete!"
        '';

        launchEnvironment = pkgs.writeShellScriptBin "blender-claude" ''
          #!/usr/bin/env bash

          echo "╔════════════════════════════╗"
          echo "║      Blender + Claude      ║"
          echo "╚════════════════════════════╝"
          echo ""

          # Check if blender is available (Flatpak or system)
          if ! ${pkgs.flatpak}/bin/flatpak list 2>/dev/null | grep -q org.blender.Blender; then
            if ! command -v blender &> /dev/null; then
              echo "⚠ Error: Blender not found"
              echo "Please install Blender via Flatpak or system package manager"
              exit 1
            fi
          fi

          # Check if setup has been run
          CONFIG_FILE="$HOME/.config/Claude/claude_desktop_config.json"
          if [ ! -f "$CONFIG_FILE" ]; then
            echo "⚠ First time setup required!"
            echo ""
            read -p "Run setup now? (y/n) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
              setup-claude-config
              setup-blender-addon
              echo ""
              echo "Setup complete! Restart this command to continue."
              exit 0
            fi
          fi

          echo "Available commands:"
          echo "  claude-desktop       - Launch Claude Desktop"
          echo "  setup-blender-addon  - Setup/reinstall Blender addon"
          echo "  setup-claude-config  - Setup/update Claude config"
          echo ""
          echo "Quick start:"
          echo "  1. Run 'claude-desktop' in devshell"
          echo "  2. Launch Blender
          echo "  3. In Blender, enable the addon and connect to Claude"
        '';

      in
      {
        packages = {
          default = launchEnvironment;
          setup-addon = setupAddon;
          setup-config = setupClaudeConfig;
          claude-desktop = claude-desktop.packages.${system}.claude-desktop-with-fhs;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            claude-desktop.packages.${system}.claude-desktop-with-fhs
            pkgs.python311
            pkgs.python311Packages.pip
            pkgs.uv
            pkgs.curl
            pkgs.jq
            pkgs.flatpak
            setupAddon
            setupClaudeConfig
            launchEnvironment
          ];

          shellHook = ''
            echo "╔════════════════════════════╗"
            echo "║      Blender + Claude      ║"
            echo "╚════════════════════════════╝"
            echo ""
            echo "Environment loaded!"
            echo ""

            if ${pkgs.flatpak}/bin/flatpak list 2>/dev/null | grep -q org.blender.Blender; then
              echo "✓ Blender detected (Flatpak): $(${pkgs.flatpak}/bin/flatpak run org.blender.Blender --version 2>/dev/null | head -1)"
            elif command -v blender &> /dev/null; then
              echo "✓ Blender detected: $(blender --version 2>/dev/null | head -1)"
            else
              echo "⚠ Warning: Blender not found"
              echo "   Please install Blender via Flatpak or system package manager"
            fi

            echo ""
            echo "Setup commands:"
            echo "  setup-claude-config  - Configure Claude Desktop for MCP"
            echo "  setup-blender-addon  - Download and setup Blender addon"
            echo ""
            echo "Launch commands:"
            echo "  claude-desktop       - Start Claude Desktop"
            echo ""
            echo "Quick setup (first time):"
            echo "  1. setup-claude-config"
            echo "  2. setup-blender-addon"
            echo "  4. claude-desktop"
            echo ""
          '';
        };

        apps = {
          default = {
            type = "app";
            program = "${launchEnvironment}/bin/blender-claude";
          };
        };
      }
    );
}
