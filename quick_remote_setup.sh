#!/bin/bash

# Quick ComfyUI Remote Access Setup
# One-command setup for secure remote access

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}🌐 ComfyUI Remote Access Setup${NC}"
    echo "=================================="
}

print_step() {
    echo -e "${GREEN}➤${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Check if ComfyUI is installed
check_comfyui() {
    if [ ! -d "$HOME/ComfyUI" ]; then
        print_error "ComfyUI not found. Please install ComfyUI first."
        echo "Run: wget https://raw.githubusercontent.com/jishnusygal/comfyui-wan21-setup/main/setup_comfyui.sh && chmod +x setup_comfyui.sh && ./setup_comfyui.sh"
        exit 1
    fi
}

# Method 1: Tailscale Setup (Recommended)
setup_tailscale() {
    print_step "Setting up Tailscale (Secure VPN)"
    
    # Install Tailscale
    curl -fsSL https://tailscale.com/install.sh | sh
    
    print_step "Starting Tailscale..."
    sudo tailscale up
    
    # Get Tailscale IP
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
    
    if [ ! -z "$TAILSCALE_IP" ]; then
        echo ""
        echo "🎉 Tailscale setup complete!"
        echo "📱 Install Tailscale on your devices from: https://tailscale.com/download"
        echo "🔗 Access ComfyUI securely at: http://$TAILSCALE_IP:8188"
        echo ""
    fi
}

# Method 2: Cloudflare Tunnel Setup
setup_cloudflare() {
    print_step "Setting up Cloudflare Tunnel"
    
    # Install cloudflared
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb
    rm cloudflared-linux-amd64.deb
    
    print_step "Login to Cloudflare..."
    cloudflared tunnel login
    
    print_step "Creating tunnel..."
    cloudflared tunnel create comfyui
    
    # Get tunnel ID
    TUNNEL_ID=$(cloudflared tunnel list | grep comfyui | awk '{print $1}')
    
    # Create config
    mkdir -p ~/.cloudflared
    cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: ~/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: comfyui.your-domain.com
    service: http://localhost:8188
  - service: http_status:404
EOF
    
    print_step "Starting tunnel..."
    cloudflared tunnel run comfyui &
    
    echo ""
    echo "🎉 Cloudflare tunnel created!"
    echo "🌐 Add DNS record: comfyui CNAME $TUNNEL_ID.cfargotunnel.com"
    echo "🔗 Access at: https://comfyui.your-domain.com"
    echo ""
}

# Method 3: ngrok Setup (Quick & Easy)
setup_ngrok() {
    print_step "Setting up ngrok tunnel"
    
    # Download ngrok
    wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
    tar xvzf ngrok-v3-stable-linux-amd64.tgz
    sudo mv ngrok /usr/local/bin/
    rm ngrok-v3-stable-linux-amd64.tgz
    
    echo "📝 Get your auth token from: https://dashboard.ngrok.com/get-started/your-authtoken"
    read -p "Enter your ngrok auth token: " NGROK_TOKEN
    
    ngrok config add-authtoken "$NGROK_TOKEN"
    
    print_step "Starting ngrok tunnel..."
    nohup ngrok http 8188 > /tmp/ngrok.log 2>&1 &
    
    sleep 5
    
    # Get ngrok URL
    NGROK_URL=$(curl -s localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url' 2>/dev/null || echo "Check http://localhost:4040")
    
    echo ""
    echo "🎉 ngrok tunnel started!"
    echo "🔗 Access ComfyUI at: $NGROK_URL"
    echo "📊 Monitor at: http://localhost:4040"
    echo ""
}

# Create enhanced launch script
create_launch_script() {
    print_step "Creating enhanced launch script..."
    
    cd "$HOME/ComfyUI"
    
    cat > launch_with_tunnel.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate

echo "🌐 ComfyUI Remote Access Launcher"
echo "=================================="

# Check for active connections
echo "🔍 Checking remote access status..."

# Check Tailscale
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
if [ ! -z "$TAILSCALE_IP" ]; then
    echo "✅ Tailscale: http://$TAILSCALE_IP:8188"
fi

# Check ngrok
if pgrep -f ngrok >/dev/null; then
    NGROK_URL=$(curl -s localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[0].public_url' 2>/dev/null || echo "Active")
    echo "✅ ngrok: $NGROK_URL"
fi

# Check Cloudflare
if pgrep -f cloudflared >/dev/null; then
    echo "✅ Cloudflare Tunnel: Active"
fi

echo "🏠 Local: http://localhost:8188"
echo "=================================="

# Auto-detect GPU settings
VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
LAUNCH_FLAGS="--listen 0.0.0.0"

if [[ -z "$VRAM" ]]; then
    echo "🖥️  CPU mode"
    LAUNCH_FLAGS="$LAUNCH_FLAGS --cpu"
elif [[ $VRAM -lt 8000 ]]; then
    echo "🎮 Low VRAM mode ($VRAM MB)"
    LAUNCH_FLAGS="$LAUNCH_FLAGS --lowvram"
elif [[ $VRAM -lt 12000 ]]; then
    echo "🎮 Normal VRAM mode ($VRAM MB)"
    LAUNCH_FLAGS="$LAUNCH_FLAGS --normalvram"
else
    echo "🚀 High VRAM mode ($VRAM MB)"
    LAUNCH_FLAGS="$LAUNCH_FLAGS --highvram"
fi

echo ""
echo "🎨 Starting ComfyUI..."
python main.py $LAUNCH_FLAGS --port 8188
EOF
    
    chmod +x launch_with_tunnel.sh
    print_step "Enhanced launch script created!"
}

# Create service management script
create_service_manager() {
    print_step "Creating service management script..."
    
    cat > ~/comfyui_manager.sh << 'EOF'
#!/bin/bash

# ComfyUI Remote Access Manager

COMFYUI_DIR="$HOME/ComfyUI"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_status() {
    echo "🌐 ComfyUI Remote Access Status"
    echo "==============================="
    
    # ComfyUI status
    if pgrep -f "python.*main.py" >/dev/null; then
        echo -e "🎨 ComfyUI: ${GREEN}Running${NC}"
    else
        echo -e "🎨 ComfyUI: ${RED}Stopped${NC}"
    fi
    
    # Tailscale status
    if command -v tailscale >/dev/null && tailscale status >/dev/null 2>&1; then
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null)
        echo -e "🔒 Tailscale: ${GREEN}Connected${NC} ($TAILSCALE_IP)"
    else
        echo -e "🔒 Tailscale: ${RED}Disconnected${NC}"
    fi
    
    # ngrok status
    if pgrep -f ngrok >/dev/null; then
        NGROK_URL=$(curl -s localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[0].public_url' 2>/dev/null || echo "Active")
        echo -e "🚇 ngrok: ${GREEN}Running${NC} ($NGROK_URL)"
    else
        echo -e "🚇 ngrok: ${RED}Stopped${NC}"
    fi
    
    # Cloudflare status
    if pgrep -f cloudflared >/dev/null; then
        echo -e "☁️  Cloudflare: ${GREEN}Running${NC}"
    else
        echo -e "☁️  Cloudflare: ${RED}Stopped${NC}"
    fi
    
    echo ""
}

start_comfyui() {
    if pgrep -f "python.*main.py" >/dev/null; then
        echo "ComfyUI is already running"
    else
        echo "Starting ComfyUI..."
        cd "$COMFYUI_DIR"
        nohup ./launch_with_tunnel.sh > /tmp/comfyui.log 2>&1 &
        echo "ComfyUI started in background"
    fi
}

stop_comfyui() {
    if pgrep -f "python.*main.py" >/dev/null; then
        echo "Stopping ComfyUI..."
        pkill -f "python.*main.py"
        echo "ComfyUI stopped"
    else
        echo "ComfyUI is not running"
    fi
}

start_ngrok() {
    if pgrep -f ngrok >/dev/null; then
        echo "ngrok is already running"
    else
        echo "Starting ngrok..."
        nohup ngrok http 8188 > /tmp/ngrok.log 2>&1 &
        sleep 3
        echo "ngrok started"
    fi
}

stop_ngrok() {
    if pgrep -f ngrok >/dev/null; then
        echo "Stopping ngrok..."
        pkill -f ngrok
        echo "ngrok stopped"
    else
        echo "ngrok is not running"
    fi
}

show_menu() {
    echo "ComfyUI Remote Access Manager"
    echo "============================="
    echo "1) Show status"
    echo "2) Start ComfyUI"
    echo "3) Stop ComfyUI"
    echo "4) Start ngrok tunnel"
    echo "5) Stop ngrok tunnel"
    echo "6) Restart all"
    echo "7) Show logs"
    echo "8) Exit"
    echo ""
    read -p "Choose option (1-8): " choice
}

show_logs() {
    echo "Recent ComfyUI logs:"
    echo "==================="
    tail -20 /tmp/comfyui.log 2>/dev/null || echo "No logs found"
    echo ""
    echo "Recent ngrok logs:"
    echo "=================="
    tail -20 /tmp/ngrok.log 2>/dev/null || echo "No logs found"
}

restart_all() {
    echo "Restarting all services..."
    stop_comfyui
    stop_ngrok
    sleep 2
    start_comfyui
    start_ngrok
    echo "All services restarted"
}

# Main menu loop
while true; do
    show_status
    show_menu
    
    case $choice in
        1) show_status ;;
        2) start_comfyui ;;
        3) stop_comfyui ;;
        4) start_ngrok ;;
        5) stop_ngrok ;;
        6) restart_all ;;
        7) show_logs ;;
        8) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
EOF
    
    chmod +x ~/comfyui_manager.sh
    print_step "Service manager created at ~/comfyui_manager.sh"
}

# Create auto-start systemd service
create_systemd_service() {
    print_step "Creating systemd service for auto-start..."
    
    sudo tee /etc/systemd/system/comfyui.service > /dev/null << EOF
[Unit]
Description=ComfyUI Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/ComfyUI
ExecStart=$HOME/ComfyUI/launch_with_tunnel.sh
Restart=always
RestartSec=10
Environment=PATH=/usr/bin:/usr/local/bin
Environment=HOME=$HOME

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable comfyui
    
    print_step "Systemd service created. Control with:"
    echo "  sudo systemctl start comfyui"
    echo "  sudo systemctl stop comfyui"
    echo "  sudo systemctl status comfyui"
}

# Main setup function
main() {
    print_header
    check_comfyui
    
    echo "Choose your remote access method:"
    echo "1) 🔒 Tailscale (Recommended - Secure VPN)"
    echo "2) ☁️  Cloudflare Tunnel (Custom domain)"
    echo "3) 🚇 ngrok (Quick temporary access)"
    echo "4) 📋 Just create management scripts"
    echo ""
    read -p "Enter choice (1-4): " method
    
    case $method in
        1)
            setup_tailscale
            ;;
        2)
            setup_cloudflare
            ;;
        3)
            setup_ngrok
            ;;
        4)
            echo "Creating management scripts only..."
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    create_launch_script
    create_service_manager
    
    read -p "Create auto-start service? (y/N): " create_service
    if [[ $create_service =~ ^[Yy]$ ]]; then
        create_systemd_service
    fi
    
    echo ""
    echo "🎉 Setup complete!"
    echo ""
    echo "📋 Quick commands:"
    echo "  ~/comfyui_manager.sh    - Service manager"
    echo "  cd ~/ComfyUI && ./launch_with_tunnel.sh - Start manually"
    echo ""
    
    if [[ $method == "1" ]]; then
        print_warning "Remember to install Tailscale on your devices!"
        echo "Download from: https://tailscale.com/download"
    elif [[ $method == "2" ]]; then
        print_warning "Don't forget to add the DNS record in Cloudflare!"
    elif [[ $method == "3" ]]; then
        print_warning "ngrok URLs change on restart. Consider upgrading for static URLs."
    fi
    
    echo ""
    echo "🔧 Manage your setup:"
    echo "  Run: ~/comfyui_manager.sh"
    echo ""
}

# Run main function
main "$@"