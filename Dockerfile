FROM nvidia/cuda:10.0-base-ubuntu18.04

# Install some basic utilities
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    git \
    bzip2 \
    libx11-6 \
 && rm -rf /var/lib/apt/lists/*

# Create a working directory
RUN mkdir /app
WORKDIR /app

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos '' --shell /bin/bash user \
 && chown -R user:user /app
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user
USER user

# All users can use /home/user as their home directory
ENV HOME=/home/user
RUN chmod 777 /home/user

# Install project dependencies (steps based on `install_dependencies.sh`)
RUN sudo apt-get update && sudo apt-get install -y \
    build-essential \
    wget \
    gfortran \
    ncurses-dev \
    unzip \
    tar \
 && sudo rm -rf /var/lib/apt/lists/*
RUN curl -sLO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
 && bash ./Miniconda3-latest-Linux-x86_64.sh -b -p ~/miniconda \
 && rm Miniconda3-latest-Linux-x86_64.sh
ENV PATH=/home/user/miniconda/bin:$PATH
RUN conda install -y python=3.6 tensorflow-gpu=1.13.1 Cython matplotlib pillow imageio ffmpeg scikit-image scikit-learn tqdm numba
RUN conda install -y -c menpo opencv3
RUN pip install attrdict jpeg4py transforms3d more_itertools spacepy
RUN git clone https://github.com/cocodataset/cocoapi \
 && cd cocoapi/PythonAPI \
 && make \
 && python setup.py install \
 && cd ../.. \
 && rm -rf cocoapi
RUN cd /tmp \
 && curl -sLO https://github.com/anibali/h36m-fetch/releases/download/v0.0.0/cdf38_0-dist-all.tar.gz \
 && tar xzf cdf38_0-dist-all.tar.gz \
 && cd cdf38_0-dist \
 && make OS=linux ENV=gnu CURSES=yes FORTRAN=no UCOPTIONS=-O2 SHARED=yes all \
 && sudo make INSTALLDIR=/usr/local/cdf install \
 && cd .. \
 && rm -rf cdf38_0-dist
RUN pip install imageio-ffmpeg

# Install OpenCV dependencies
RUN sudo apt-get update && sudo apt-get install -y \
    libgtk2.0-dev \
 && sudo rm -rf /var/lib/apt/lists/*

# Install ImageMagick
RUN sudo apt-get update && sudo apt-get install -y \
    imagemagick \
 && sudo rm -rf /var/lib/apt/lists/*

# Create empty SpacePy config (suppresses an annoying warning message)
RUN mkdir /home/user/.spacepy && echo "[spacepy]" > /home/user/.spacepy/spacepy.rc

# Copy in project files
COPY --chown=user:user . /app

# Enable NVIDIA capabilities
ENV NVIDIA_DRIVER_CAPABILITIES=video,compute,utility

ENV DATA_ROOT=/data

# Set the default command to python3
CMD ["python3"]
