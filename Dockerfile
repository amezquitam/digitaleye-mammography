ARG PYTORCH="1.12.1"
ARG CUDA="11.3"
ARG CUDNN="8"


FROM pytorch/pytorch:${PYTORCH}-cuda${CUDA}-cudnn${CUDNN}-devel

USER root
EXPOSE 8888
ENV HOSTNAME=digitaleye-mammography

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && apt-get install -y \
    libxext6 libxrender-dev libncurses5-dev libncursesw5-dev \
    apt-utils libcurl4 gcc g++ git curl wget nano \
    iputils-ping cmake sudo htop unrar unzip libsm6 tmux python3-pip \
    gnupg software-properties-common ffmpeg python3-distutils

RUN apt-get install -y \
    libgl1 \
    libglib2.0-0

RUN rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos '' cbddobvyz \
    && usermod -aG sudo cbddobvyz \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


# Instala Python 3.8
RUN apt-get update && apt-get install -y python3.8 python3.8-dev python3.8-distutils curl \
    && curl -sS https://bootstrap.pypa.io/pip/3.8/get-pip.py | python3.8 \
    && ln -sf /usr/bin/python3.8 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip \
    && ln -sf /usr/bin/python3.8 /usr/bin/python3

ENV PATH="/home/cbddobvyz/.local/bin:${PATH}"

WORKDIR /workspace

USER cbddobvyz

COPY requirements.txt /workspace/requirements.txt
RUN python3.8 --version
RUN python3.8 -m pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host=files.pythonhosted.org opencv-contrib-python-headless==4.7.0.72 \
    torch==1.12.1+cu116 torchvision==0.13.1+cu116 torchaudio==0.12.1 --extra-index-url https://download.pytorch.org/whl/cu116
RUN python3.8 -m pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host=files.pythonhosted.org \
    --upgrade pip \
    -r requirements.txt \
    jupyterlab

COPY ./mmcv-1.7.0 /workspace/mmcv-1.7.0
WORKDIR /workspace/mmcv-1.7.0

RUN python3.8 -m pip install -r requirements/optional.txt
RUN python3.8 -m pip install setuptools==64.0

RUN nvcc --version

USER root
RUN chown -R cbddobvyz:cbddobvyz /workspace/mmcv-1.7.0
USER cbddobvyz

RUN TORCH_CUDA_ARCH_LIST="8.6" FORCE_CUDA="1" MMCV_WITH_OPS=1 python3.8 -m pip install -e . -v

RUN python3.8 .dev_scripts/check_installation.py

#RUN python3 -m pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host=files.pythonhosted.org opencv-contrib-python-headless==4.7.0.72 \
#    torch==1.12.1+cu116 torchvision==0.13.1+cu116 torchaudio==0.12.1 --extra-index-url https://download.pytorch.org/whl/cu116 
COPY ./ /home/cbddobvyz/workspace/
WORKDIR /home/cbddobvyz/workspace
USER root
RUN chown -R cbddobvyz:cbddobvyz /home/cbddobvyz/workspace
USER cbddobvyz
CMD ["jupyter", "lab","--ip=0.0.0.0","--NotebookApp.allow_origin='*'","--port=8888", "--no-browser","--NotebookApp.token=''","--NotebookApp.password=''","--ServerApp.terminado_settings={\"shell_command\": [\"/bin/bash\"]}"]
