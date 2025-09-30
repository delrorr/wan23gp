# CUDA base image with cuDNN
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/opt/conda/bin:$PATH

# Install system dependencies + SSH server
RUN apt-get update && apt-get install -y \
    wget \
    git \
    curl \
    bzip2 \
    ca-certificates \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH
RUN mkdir /var/run/sshd && \
    echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# Install Miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    /opt/conda/bin/conda clean -afy

SHELL ["/bin/bash", "-c"]

# Accept Conda TOS and create environment
RUN conda config --set always_yes yes --set changeps1 no && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
    conda create -n wan2gp python=3.10.9 -y

# Add conda env to PATH
ENV PATH=/opt/conda/envs/wan2gp/bin:$PATH

# Install PyTorch (test cu128 build)
RUN pip install torch==2.7.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/test/cu128

# Set working directory
WORKDIR /workspace

# Clone Wan2GP repo directly into workspace
RUN git clone https://github.com/deepbeepmeep/Wan2GP.git /workspace

# Install requirements from repo
RUN pip install -r requirements.txt

# Expose SSH
EXPOSE 22

# Start SSH, activate conda, and run wgp.py
CMD bash -c "source /opt/conda/etc/profile.d/conda.sh && conda activate wan2gp && service ssh start && python wgp.py && exec bash"
