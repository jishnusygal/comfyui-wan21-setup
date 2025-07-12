# ComfyUI WAN 2.1 Setup Script

🚀 **Automated installation script for ComfyUI with WAN 2.1 model support on Pop!_OS and Ubuntu-based systems**

## Features

- ✅ **Complete Automation**: One-click installation of ComfyUI with WAN 2.1
- 🔧 **Smart GPU Detection**: Automatically configures for your hardware
- 📦 **Comprehensive Setup**: Includes models, custom nodes, and workflows
- 🎨 **Ready-to-Use**: Desktop integration and launch scripts included
- 🔄 **Easy Updates**: Built-in update mechanisms

## Quick Start

```bash
# Download and run the setup script
wget https://raw.githubusercontent.com/jishnusygal/comfyui-wan21-setup/main/setup_comfyui.sh
chmod +x setup_comfyui.sh
./setup_comfyui.sh
```

## What Gets Installed

### Core Components
- **ComfyUI**: Latest version from official repository
- **WAN 2.1 Models**: Base and refiner models
- **Python Environment**: Isolated virtual environment with all dependencies
- **PyTorch**: CUDA-enabled for GPU acceleration

### Additional Models
- **VAE Models**: SDXL VAE for better image quality
- **ControlNet**: Canny edge detection model
- **Upscaling**: RealESRGAN for image enhancement

### Custom Nodes
- **ComfyUI Manager**: Easy node installation and management
- **Efficiency Nodes**: Streamlined workflow components
- **ControlNet Aux**: Additional ControlNet utilities
- **Image Saver**: Enhanced image saving options

## System Requirements

### Minimum Requirements
- **OS**: Pop!_OS 20.04+ or Ubuntu 20.04+
- **RAM**: 8GB (16GB+ recommended)
- **Storage**: 20GB free space
- **Python**: 3.8+

### Recommended
- **GPU**: NVIDIA GPU with 8GB+ VRAM
- **RAM**: 16GB+
- **Storage**: 50GB+ SSD space
- **CUDA**: 11.8+ (auto-installed)

## Installation Directory Structure

```
~/ComfyUI/
├── models/
│   ├── checkpoints/          # WAN 2.1 and other checkpoint models
│   ├── vae/                  # VAE models
│   ├── loras/                # LoRA models
│   ├── controlnet/           # ControlNet models
│   ├── upscale_models/       # Upscaling models
│   └── embeddings/           # Text embeddings
├── custom_nodes/             # Installed custom nodes
├── workflows/                # Example workflows
├── input/                    # Input images
├── output/                   # Generated images
├── launch.sh                 # Auto-detect launch script
├── launch_cpu.sh             # CPU-only mode
└── launch_dev.sh             # Development mode
```

## Usage

### Starting ComfyUI

```bash
cd ~/ComfyUI
./launch.sh
```

Then open your browser to: `http://localhost:8188`

### Launch Options

- **`./launch.sh`** - Auto-detects GPU and sets optimal flags
- **`./launch_cpu.sh`** - Forces CPU-only mode
- **`./launch_dev.sh`** - Development mode with verbose logging

### Desktop Integration

The script creates a desktop entry, so you can also launch ComfyUI from your applications menu.

## Configuration

### GPU Memory Settings

The script automatically detects your GPU VRAM and sets appropriate flags:

- **<8GB VRAM**: `--lowvram` flag
- **8-12GB VRAM**: `--normalvram` flag  
- **>12GB VRAM**: `--highvram` flag
- **No GPU**: `--cpu` flag

### Custom Model Paths

Edit `extra_model_paths.yaml` to add custom model directories:

```yaml
base_path: /path/to/your/models/
checkpoints: /custom/checkpoints/
loras: /custom/loras/
```

## Troubleshooting

### Common Issues

**Out of Memory Errors**
```bash
# Use CPU mode if GPU memory is insufficient
./launch_cpu.sh
```

**CUDA Not Found**
```bash
# Reinstall CUDA toolkit
sudo apt install nvidia-cuda-toolkit
# Restart terminal and try again
```

**Models Not Loading**
```bash
# Check model file integrity
ls -la ~/ComfyUI/models/checkpoints/
# Re-download if files are corrupted
```

**Permission Errors**
```bash
# Fix permissions
chmod +x ~/ComfyUI/*.sh
sudo chown -R $USER:$USER ~/ComfyUI/
```

### Getting Help

1. Check the [ComfyUI Documentation](https://github.com/comfyanonymous/ComfyUI)
2. Visit the [ComfyUI Community](https://www.reddit.com/r/comfyui/)
3. Open an issue in this repository

## Updating

### Update ComfyUI
```bash
cd ~/ComfyUI
git pull
source venv/bin/activate
pip install -r requirements.txt
```

### Update Custom Nodes
Use the ComfyUI Manager interface or:
```bash
cd ~/ComfyUI/custom_nodes/ComfyUI-Manager
git pull
```

## Advanced Usage

### Adding New Models

1. Download models to appropriate directories:
   - Checkpoints: `~/ComfyUI/models/checkpoints/`
   - LoRAs: `~/ComfyUI/models/loras/`
   - VAE: `~/ComfyUI/models/vae/`

2. Restart ComfyUI to detect new models

### Custom Workflows

Example workflows are included in `~/ComfyUI/workflows/`. Load them in the ComfyUI interface:

1. Click "Load" in the interface
2. Select a `.json` workflow file
3. Configure parameters as needed

### Environment Variables

Customize installation by setting environment variables before running:

```bash
export INSTALL_DIR="/custom/path"
export COMFYUI_PORT="8080"
./setup_comfyui.sh
```

## Uninstallation

To completely remove ComfyUI:

```bash
# Remove installation directory
rm -rf ~/ComfyUI

# Remove desktop entry
rm ~/.local/share/applications/comfyui.desktop

# Remove workspace (optional)
rm -rf ~/AI-Workspace
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) - The amazing node-based UI
- [Stability AI](https://stability.ai/) - For the Stable Diffusion models
- [AUTOMATIC1111](https://github.com/AUTOMATIC1111/stable-diffusion-webui) - Inspiration and community

## Support

If this script helped you, consider:
- ⭐ Starring this repository
- 🐛 Reporting issues
- 💡 Suggesting improvements
- 📢 Sharing with others

---

**Happy AI art creation! 🎨✨**