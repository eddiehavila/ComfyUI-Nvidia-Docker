ComfyUI-Nvidia_devel-Docker

Windows10, WSL2, Docker-desktop

Physical disk formated ext4 containing comfyUI-Docker basedir/ and run/, and models folder

Pyshical disk mounted on WSL under /mnt/shared

Physical disk mounted to container via dcoker volume mount `-v /mnt/shared/models:/mnt/shared/models:shared`


Start Docker-desktop. It should automatically start WSL.

Open a powerShell terminal as Administrator ("run as admin")

Identify DEVICE ID of physical disk: `wmic diskdrive list brief`

```
Caption                       DeviceID            Model                         Partitions  Size
Samsung SSD 970 EVO Plus 1TB  \\.\PHYSICALDRIVE2  Samsung SSD 970 EVO Plus 1TB  1           1000202273280
```

Mount physical disk to WSL: `wsl --mount \\.\PHYSICALDRIVE2` 

Ignore error?:

```
Catastrophic failure
Error code: Wsl/Service/DetachDisk/E_UNEXPECTED
```


Enter WSL: `wsl`

If this is the first time mounting the disk, get the disk UUID and add to /etc/fstab. Note its `defaults,shared` so docker can access the double/nested mounted directory

```
UUID=9377b589-b3ff-4e62-8fb4-af089693ea0c /mnt/shared ext4 defaults,shared 0 0
```

Place `start.sh` and `shell.sh` on `/mnt/shared/comfy-docker`

Create `/mnt/shared/comfy-docker/basedir` and `/mnt/shared/comfy-docker/run` directories

Place `users_script.sh` in `/mnt/shared/comfy-docker/run`


Link basedir/models to mounted disk models directory in WSL, execute `sudo ln -s /mnt/shared/comfy-docker/basedir/models /mnt/shared/models`

Full `start.sh` docker run command:

```
docker run --rm -it --runtime nvidia --gpus all \
-v `pwd`/run:/comfy/mnt \
-v `pwd`/basedir:/basedir \
-v /mnt/shared/models:/mnt/shared/models:shared \
-e WANTED_UID=`id -u` -e WANTED_GID=`id -g` \
-e BASE_DIRECTORY=/basedir -e SECURITY_LEVEL=weak -p 127.0.0.1:8188:8188 \
--name comfyui-nvidia comfyui-nvidia-docker:ubuntu24_cuda12.8_devel 
```


```
user@localhost:/mnt/shared/comfyui-docker$ tree /mnt/shared/ -L 3
/mnt/shared/
├── comfyui-docker
│   ├── basedir
│   │   ├── custom_nodes
│   │   ├── input
│   │   ├── models -> /mnt/shared/models/
│   │   ├── output
│   │   └── user
│   ├── run
│   │   ├── ComfyUI
│   │   ├── HF
│   │   ├── sageattention
│   │   ├── triton
│   │   ├── user_script.bash
│   │   └── venv
│   ├── shell.sh
│   └── start.sh
├── lost+found
└── models
    ├── Codeformer
    │   ├── codeformer-v0.1.0.pth
    │   └── detection_Resnet50_Final.pth
    ├── CogVideo
    │   ├── CogVideoX-5b-1.5
    │   ├── CogVideoX-5b-I2V
    │   └── CogVideoX-5b-Tora
    ├── Diffusers
    │   ├── hunyuan3d-delight-v2-0
    │   └── hunyuan3d-paint-v2-0
    ├── GFPGAN
    ├── LDSR
    ├── LLM
    [..........]
```


