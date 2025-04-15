# Use a Conda base image compatible with Binder
FROM mambaorg/micromamba:1.5.8

# Arguments for Binder user
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV NB_USER=${NB_USER}
ENV NB_UID=${NB_UID}
ENV HOME=/home/${NB_USER}

# Create the user
USER root
RUN useradd --create-home --uid ${NB_UID} ${NB_USER} && \
    chown -R ${NB_USER}:${NB_USER} ${HOME}

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
        openmpi-bin libopenmpi-dev \
        git cmake make \
        zlib1g-dev libbz2-dev build-essential \
        software-properties-common python3-dev \
        libscotchparmetis-dev libptscotch-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


    
# Switch to user
USER ${NB_USER}
WORKDIR ${HOME}

# Copy notebooks
COPY --chown=${NB_USER}:${NB_USER} *.ipynb ./
COPY --chown=${NB_USER}:${NB_USER} environment.yml .

# Create and activate Conda env
RUN micromamba env create -f environment.yml && \
    micromamba clean --all --yes

ENV PATH=/opt/conda/envs/maia_tutorials/bin:$PATH
ENV CONDA_DEFAULT_ENV=maia_tutorials

# Installer numpy avec pip (important pour CMake)
RUN pip install numpy

# Clone et installe MAIA
RUN git clone https://github.com/onera/Maia.git && \
    cd Maia && \
    git submodule update --init && \
    mkdir -p build && cd build && \
    cmake .. \
      -DCMAKE_INSTALL_PREFIX=/opt/conda/envs/maia_tutorials \
      -DCMAKE_C_COMPILER=mpicc \
      -DCMAKE_CXX_COMPILER=mpicxx \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_BUILD_TYPE=Release \
      -DPython_EXECUTABLE=/opt/conda/envs/maia_tutorials/bin/python \
      -DPython3_NumPy_INCLUDE_DIRS=/opt/conda/envs/maia_tutorials/lib/python3.10/site-packages/numpy/core/include && \
    make  && make install

# Ajout au PYTHONPATH
ENV PYTHONPATH=/opt/conda/envs/maia_tutorials/lib

EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--ServerApp.token=''"]
