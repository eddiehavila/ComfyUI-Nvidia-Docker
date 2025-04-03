
# docker run --rm -it --runtime nvidia --gpus all \
docker start -a comfyui-nvidia 

# override init.bash
# -v /mnt/c/Users/user/Documents/source/ComfyUI-Nvidia-Docker/init.bash:/comfyui-nvidia_init.bash \