#!/bin/bash

# ComfyUI WAN 2.1 Complete Setup Script for Pop!_OS
# This script automates the entire installation and configuration process

set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
INSTALL_DIR="$HOME/ComfyUI"
PYTHON_VERSION="3.10"
COMFYUI_PORT="8188"
WORKSPACE_DIR="$HOME/AI-Workspace"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Check if running on Pop!_OS
check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$NAME" == "Pop!_OS" ]]; then
            print_status "Detected Pop!_OS - continuing with setup"
        else
            print_warning "Not running on Pop!_OS, but script should work on Ubuntu-based systems"
        fi
    fi
}

# Check system requirements
check_requirements() {
    print_header "CHECKING SYSTEM REQUIREMENTS"

    # Check available disk space (need at least 20GB)
    available_space=$(df -h "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ ${available_space%.*} -lt 20 ]]; then
        print_error "Insufficient disk space. Need at least 20GB available."
        exit 1
    fi

    # Check RAM (recommend at least 8GB)
    total_ram=$(free -g | awk 'NR==2{print $2}')
    if [[ $total_ram -lt 8 ]]; then
        print_warning "Less than 8GB RAM detected. Consider using --lowvram flag"
    fi

    # Check GPU
    if command -v nvidia-smi &>/dev/null; then
        print_status "NVIDIA GPU detected:"
        nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    else
        print_warning "No NVIDIA GPU detected. Will use CPU mode."
    fi
}

# Install system dependencies
install_dependencies() {
    print_header "INSTALLING SYSTEM DEPENDENCIES"

    sudo apt update
    sudo apt install -y \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        git \
        wget \
        curl \
        build-essential \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgomp1 \
        ffmpeg

    # Install NVIDIA drivers and CUDA if GPU detected
    if lspci | grep -i nvidia >/dev/null; then
        print_warning "NVIDIA GPU detected.\nPlease install the latest NVIDIA drivers and CUDA toolkit manually from the official NVIDIA website: https://www.nvidia.com/Download/index.aspx and https://developer.nvidia.com/cuda-downloads.\nSkipping automatic installation to avoid system issues."
        # Do NOT install drivers or CUDA automatically
        # sudo apt install -y nvidia-driver-525 nvidia-cuda-toolkit
        # echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
        # echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    fi
}

# Create workspace directory
create_workspace() {
    print_header "CREATING WORKSPACE"

    mkdir -p "$WORKSPACE_DIR"
    cd "$WORKSPACE_DIR"
    print_status "Created workspace at $WORKSPACE_DIR"
}

# Clone and setup ComfyUI
setup_comfyui() {
    print_header "SETTING UP COMFYUI"

    # Clone ComfyUI
    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "ComfyUI directory already exists. Updating..."
        cd "$INSTALL_DIR"
        git pull
    else
        print_status "Cloning ComfyUI..."
        git clone https://github.com/comfyanonymous/ComfyUI.git "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi

    # Create virtual environment
    print_status "Creating Python virtual environment..."
    python3 -m venv venv
    source venv/bin/activate

    # Upgrade pip
    pip install --upgrade pip

    # Install PyTorch with CUDA support
    print_status "Installing PyTorch with CUDA support..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

    # Install ComfyUI requirements
    print_status "Installing ComfyUI requirements..."
    pip install -r requirements.txt

    # Install additional useful packages
    pip install \
        opencv-python \
        pillow \
        requests \
        tqdm \
        scipy \
        scikit-image
}

# Create directory structure
create_directories() {
    print_header "CREATING DIRECTORY STRUCTURE"

    cd "$INSTALL_DIR"

    # Create model directories
    mkdir -p models/{checkpoints,vae,clip,unet,loras,embeddings,upscale_models,controlnet}
    mkdir -p custom_nodes
    mkdir -p input
    mkdir -p output

    print_status "Created model directories"
}

# Download WAN 2.1 model
download_wan21() {
    print_header "DOWNLOADING WAN 2.1 MODEL"

    cd "$INSTALL_DIR/models/checkpoints"

    # WAN 2.1 model download URLs (you may need to update these)
    WAN21_URL="https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
    WAN21_REFINER_URL="https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors"

    print_status "Downloading WAN 2.1 base model..."
    wget -O "wan21_base.safetensors" "$WAN21_URL" || {
        print_error "Failed to download WAN 2.1 base model"
        print_warning "You may need to manually download the model from the official source"
    }

    print_status "Downloading WAN 2.1 refiner model..."
    wget -O "wan21_refiner.safetensors" "$WAN21_REFINER_URL" || {
        print_error "Failed to download WAN 2.1 refiner model"
        print_warning "You may need to manually download the model from the official source"
    }
}

# Download additional models
download_additional_models() {
    print_header "DOWNLOADING ADDITIONAL MODELS"

    cd "$INSTALL_DIR/models"

    # VAE models
    cd vae
    print_status "Downloading VAE models..."
    wget -O "sdxl_vae.safetensors" "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors"

    # ControlNet models
    cd ../controlnet
    print_status "Downloading ControlNet models..."
    wget -O "canny_controlnet.safetensors" "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/diffusers_xl_canny_full.safetensors"

    # Upscale models
    cd ../upscale_models
    print_status "Downloading upscale models..."
    wget -O "RealESRGAN_x4plus.pth" "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth"
}

# Install useful custom nodes
install_custom_nodes() {
    print_header "INSTALLING CUSTOM NODES"

    cd "$INSTALL_DIR/custom_nodes"

    # ComfyUI Manager
    print_status "Installing ComfyUI Manager..."
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git

    # Additional useful nodes
    print_status "Installing additional custom nodes..."

    # Efficiency Nodes
    git clone https://github.com/jags111/efficiency-nodes-comfyui.git

    # ControlNet Aux
    git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git

    # Image Saver
    git clone https://github.com/giriss/comfy-image-saver.git
}

# Create launch scripts
create_launch_scripts() {
    print_header "CREATING LAUNCH SCRIPTS"

    cd "$INSTALL_DIR"

    # Create main launch script
    cat >launch.sh <<'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate

# Check available VRAM and set appropriate flags
VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
LAUNCH_FLAGS=""

if [[ -z "$VRAM" ]]; then
    echo "No NVIDIA GPU detected, using CPU mode"
    LAUNCH_FLAGS="--cpu"
elif [[ $VRAM -lt 8000 ]]; then
    echo "Low VRAM detected ($VRAM MB), using low VRAM mode"
    LAUNCH_FLAGS="--lowvram"
elif [[ $VRAM -lt 12000 ]]; then
    echo "Medium VRAM detected ($VRAM MB), using normal VRAM mode"
    LAUNCH_FLAGS="--normalvram"
else
    echo "High VRAM detected ($VRAM MB), using high VRAM mode"
    LAUNCH_FLAGS="--highvram"
fi

echo "Starting ComfyUI with flags: $LAUNCH_FLAGS"
python main.py --listen 0.0.0.0 --port 8188 $LAUNCH_FLAGS
EOF

    # Create CPU-only launch script
    cat >launch_cpu.sh <<'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
echo "Starting ComfyUI in CPU mode"
python main.py --listen 0.0.0.0 --port 8188 --cpu
EOF

    # Create development launch script
    cat >launch_dev.sh <<'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
echo "Starting ComfyUI in development mode"
python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header --verbose
EOF

    # Make scripts executable
    chmod +x launch.sh launch_cpu.sh launch_dev.sh

    print_status "Created launch scripts"
}

# Create desktop entry
create_desktop_entry() {
    print_header "CREATING DESKTOP ENTRY"

    mkdir -p ~/.local/share/applications

    cat >~/.local/share/applications/comfyui.desktop <<EOF
[Desktop Entry]
Name=ComfyUI
Comment=Stable Diffusion GUI
Exec=$INSTALL_DIR/launch.sh
Icon=applications-graphics
Type=Application
Categories=Graphics;Photography;
Path=$INSTALL_DIR
Terminal=true
StartupNotify=true
EOF

    print_status "Created desktop entry"
}

# Create configuration file
create_config() {
    print_header "CREATING CONFIGURATION FILES"

    cd "$INSTALL_DIR"

    # Create extra_model_paths.yaml
    cat >extra_model_paths.yaml <<EOF
# Extra model paths for ComfyUI
# Add your custom model paths here

base_path: $INSTALL_DIR/

checkpoints: models/checkpoints/
vae: models/vae/
clip: models/clip/
unet: models/unet/
loras: models/loras/
embeddings: models/embeddings/
upscale_models: models/upscale_models/
controlnet: models/controlnet/
EOF

    # Create workflow examples directory
    mkdir -p workflows

    print_status "Created configuration files"
}

# Final setup and instructions
final_setup() {
    print_header "FINAL SETUP AND INSTRUCTIONS"

    print_status "Installation completed successfully!"
    echo ""
    echo "🚀 ComfyUI with WAN 2.1 Setup Complete!"
    echo ""
    echo "📁 Installation location: $INSTALL_DIR"
    echo "🌐 Web interface: http://localhost:$COMFYUI_PORT"
    echo ""
    echo "🎯 To start ComfyUI:"
    echo "   cd $INSTALL_DIR"
    echo "   ./launch.sh"
    echo ""
    echo "🔧 Available launch options:"
    echo "   ./launch.sh      - Auto-detect GPU settings"
    echo "   ./launch_cpu.sh  - CPU-only mode"
    echo "   ./launch_dev.sh  - Development mode"
    echo ""
    echo "📝 Model locations:"
    echo "   Checkpoints: $INSTALL_DIR/models/checkpoints/"
    echo "   VAE: $INSTALL_DIR/models/vae/"
    echo "   LoRAs: $INSTALL_DIR/models/loras/"
    echo "   ControlNet: $INSTALL_DIR/models/controlnet/"
    echo ""
    echo "🎨 Custom nodes installed:"
    echo "   - ComfyUI Manager"
    echo "   - Efficiency Nodes"
    echo "   - ControlNet Aux"
    echo "   - Image Saver"
    echo ""
    echo "⚠️  Important notes:"
    echo "   - First run may take longer as models are loaded"
    echo "   - Check GPU memory usage if you encounter issues"
    echo "   - Use ComfyUI Manager to install additional nodes"
    echo ""
    echo "🔄 To update ComfyUI in the future:"
    echo "   cd $INSTALL_DIR && git pull"
    echo ""

    # Create a simple test workflow
    cat >"$INSTALL_DIR/workflows/test_wan21.json" <<'EOF'
{
  "3": {
    "inputs": {
      "seed": 42,
      "steps": 20,
      "cfg": 7,
      "sampler_name": "euler",
      "scheduler": "normal",
      "denoise": 1,
      "model": ["4", 0],
      "positive": ["6", 0],
      "negative": ["7", 0],
      "latent_image": ["5", 0]
    },
    "class_type": "KSampler"
  },
  "4": {
    "inputs": {
      "ckpt_name": "wan21_base.safetensors"
    },
    "class_type": "CheckpointLoaderSimple"
  },
  "5": {
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 1
    },
    "class_type": "EmptyLatentImage"
  },
  "6": {
    "inputs": {
      "text": "a beautiful landscape, detailed, high quality",
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "7": {
    "inputs": {
      "text": "blurry, low quality, distorted",
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "8": {
    "inputs": {
      "samples": ["3", 0],
      "vae": ["4", 2]
    },
    "class_type": "VAEDecode"
  },
  "9": {
    "inputs": {
      "filename_prefix": "ComfyUI_WAN21_test",
      "images": ["8", 0]
    },
    "class_type": "SaveImage"
  }
}
EOF

    print_status "Created test workflow: $INSTALL_DIR/workflows/test_wan21.json"
}

# Main execution
main() {
    print_header "COMFYUI WAN 2.1 SETUP SCRIPT"
    echo "This script will install ComfyUI with WAN 2.1 model support"
    echo "Installation directory: $INSTALL_DIR"
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi

    check_os
    check_requirements
    install_dependencies
    create_workspace
    setup_comfyui
    create_directories
    download_wan21
    download_additional_models
    install_custom_nodes
    create_launch_scripts
    create_desktop_entry
    create_config
    final_setup

    print_status "Setup completed! You can now start ComfyUI with: cd $INSTALL_DIR && ./launch.sh"
}

# Run main function
main "$@"
