
docker run --rm -it --runtime nvidia --gpus all \
-v `pwd`/run:/comfy/mnt \
-v `pwd`/basedir:/basedir \
-v /mnt/shared/models:/mnt/shared/models:shared \
-e WANTED_UID=`id -u` -e WANTED_GID=`id -g` \
-e BASE_DIRECTORY=/basedir -e SECURITY_LEVEL=weak -p 127.0.0.1:8188:8188 \
--name comfyui-nvidia comfyui-nvidia-docker:ubuntu24_cuda12.8 \
bash