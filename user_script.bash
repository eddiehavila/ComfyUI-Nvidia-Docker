#!/bin/bash


# Install triton & SageAttention for speed optimizations 
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo "##############   TRITON & SageAttention   #################################"

source /comfy/mnt/venv/bin/activate

/comfy/mnt/venv/bin/python3 -m ensurepip --upgrade
/comfy/mnt/venv/bin/python3 -m pip install --upgrade setuptools


/comfy/mnt/venv/bin/python3 -m pip install --upgrade --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128 || error_exit "torch install/upgrade failed"

# common missing packages when running an exisitng custom_nodes/ on a new venv's 
# should had been taken care for by "ComfyUI-Manager/cm-cli.py fix all" but its not working
/comfy/mnt/venv/bin/python3 -m pip install --upgrade --pre segment-anything scikit-image piexif opencv-python3-headless scipy numpy dill \
                      matplotlib accelerate diffusers transformers jax \
                      timm segment_anything addict yapf fairscale pycocoevalcap opencv-python3 qrcode \
                      pytorch_lightning pydantic omegaconf boto3 ultralytics numpy watchdog pyOpenSSL

# # trying to fix any broken nodes
# echo "trying to fix any broken nodes via /basedir/custom_nodes/ComfyUI-Manager/cm-cli.py fix all"
# /comfy/mnt/venv/bin/python3 /basedir/custom_nodes/ComfyUI-Manager/cm-cli.py fix all || echo "ComfyUI-Manager CLI failed -- in case of issue with custom nodes: use 'Manager -> Custom Nodes Manager -> Filter: Import Failed -> Try Fix' from the WebUI"

# Assume by default that we don't need to compile triton
compile_flag=false
if pip show triton &>/dev/null; then
  # Extract the installed version of triton
  triton_version=$(pip show triton | grep '^Version:' | awk '{print $2}')
  
  # Use version sort to check if triton_version is below 3.3.
  # This command prints the lowest version of the two.
  # If the lowest isn't "3.3", then triton_version is below 3.3.
  if [ "$(printf '%s\n' "$triton_version" "3.3" | sort -V | head -n1)" != "3.3" ]; then
    compile_flag=true
  fi
else
  # If triton is not installed, we also want to compile
  compile_flag=true
fi

if [ "$compile_flag" = true ]; then
  echo "Compiling triton, will take a while..."
  git clone https://github.com/triton-lang/triton.git /comfy/mnt/triton
  cd /comfy/mnt/triton
  python3 -m pip install ninja cmake wheel pybind11 # build-time dependencies
  /comfy/mnt/venv/bin/python3 -m pip install -e python 
  cd -
else
  echo "triton is installed with version $triton_version which is 3.3 or above. No need to compile."
fi



# Assume by default that we don't need to compile sageattention
compile_flag=false
if pip show sageattention &>/dev/null; then
  # Extract the installed version of sageattention
  sageattention_version=$(pip show sageattention | grep '^Version:' | awk '{print $2}')
  echo "sageattention is installed with version $sageattention_version"

  # Use version sort to check if sageattention_version is below 2.1.
  # This command prints the lowest version of the two.
  # If the lowest isn't "2.1", then sageattention_version is below 2.1.
  if [ "$(printf '%s\n' "$sageattention_version" "2.1" | sort -V | head -n1)" != "2.1" ]; then
    echo "Need to compile sageattention"
    compile_flag=true
  fi
else
  # If sageattention is not installed, we also want to compile
  echo "Need to compile sageattention"
  compile_flag=true
fi

if [ "$compile_flag" = true ]; then
  echo "Compiling sageattention, will take a while..."
  git clone https://github.com/thu-ml/SageAttention.git /comfy/mnt/sageattention
  cd /comfy/mnt/sageattention
  # python3 setup.py install
  # pip install -e .
  /comfy/mnt/venv/bin/python3 -m pip install -e .
  cd -
else
  echo "sageattention is installed with version $sageattention_version which is 2.1 or above. No need to compile."
fi

# echo "Adding '--use-sage-attention' to comfy command line"
# echo "${COMFY_CMDLINE_EXTRA}"
# export COMFY_CMDLINE_EXTRA="${COMFY_CMDLINE_EXTRA} --use-sage-attention"
# echo "${COMFY_CMDLINE_EXTRA}"

echo "##########################################################################"
echo ""
echo ""
echo ""
echo ""
echo ""



echo "== Adding system package"
DEBIAN_FRONTEND=noninteractive sudo apt update
DEBIAN_FRONTEND=noninteractive sudo apt install -y nvtop

echo "== Adding python package"
source /comfy/mnt/venv/bin/activate
pip3 install pipx
echo "== Adding nvitop"
# nvitop will be installed in the user's .local/bin directory which will be removed when the container is updated
pipx install nvitop

# extend the path to include the installation directory
export PATH=/comfy/.local/bin:${PATH}
# when starting a new docker exec, will still need to be run as ~/.local/bin/nvitop
# but will be in the PATH for commands run from within this script

echo "== Override ComfyUI launch command with: python3 ./main.py --listen 0.0.0.0 --disable-auto-launch --fast ${COMFY_CMDLINE_EXTRA}"
# Make sure to have 1) activated the venv before running this command 
# 2) use the COMFY_CMDLINE_EXTRA environment variable to pass additional command-line arguments set during the init script
cd /comfy/mnt/ComfyUI
python3 ./main.py --listen 0.0.0.0 --disable-auto-launch --fast ${COMFY_CMDLINE_EXTRA}

echo "== To prevent the regular Comfy command from starting, we 'exit 1'"
echo "   If we had not overridden it, we could simply end with an ok exit: 'exit 0'" 
exit 1

# exit 0