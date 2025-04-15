# Utiliser micromamba avec activation explicite
FROM mambaorg/micromamba:1.5.8

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV HOME=/home/${NB_USER}
ENV ENV_NAME=maia_tutorials

# Configuration système
USER root
RUN useradd --create-home --uid ${NB_UID} ${NB_USER} && \
    chown -R ${NB_USER}:${NB_USER} ${HOME}

# Installer dépendances système
RUN apt-get update && apt-get install -y --no-install-recommends \
        g++ build-essential openmpi-bin libopenmpi-dev \
        git cmake make \
        zlib1g-dev libbz2-dev \
        software-properties-common python3-dev \
        libscotchparmetis-dev libptscotch-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copier environment.yml
COPY --chown=${NB_USER}:${NB_USER} environment.yml ${HOME}/

# Configuration Conda
USER ${NB_USER}
WORKDIR ${HOME}

RUN micromamba env create -f environment.yml -n ${ENV_NAME} && \
    micromamba clean --all --yes

# Activate Conda environment and set environment variables
ENV PATH=/opt/conda/envs/maia-env/bin:$PATH
ENV CONDA_DEFAULT_ENV=maia-env

# Clone MAIA and build it
RUN git clone https://github.com/onera/Maia.git && \
    cd Maia && \
    git submodule update --init && \
    mkdir -p Dist && \
    mkdir -p build && \
    cd build && \
    export CC=$(which gcc) && \
    export CXX=$(which g++) && \
    export MPICC=$(which mpicc) && \
    export MPICXX=$(which mpicxx) && \
    PYTHON_EXECUTABLE=$(which python) && \
    PYTHON_INCLUDE_DIR=$(python -c "import sysconfig; print(sysconfig.get_path('include'))") && \
    NUMPY_INCLUDE_DIR=$(python -c "import numpy; print(numpy.get_include())") && \
    cmake .. \
      -DCMAKE_INSTALL_PREFIX="$(pwd)/../Dist" \
      -DCMAKE_C_COMPILER="${CC}" \
      -DCMAKE_CXX_COMPILER="${CXX}" \
      -DMPI_C_COMPILER="${MPICC}" \
      -DMPI_CXX_COMPILER="${MPICXX}" \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_EXE_LINKER_FLAGS='-lz -lbz2' \
      -DCMAKE_SHARED_LINKER_FLAGS='-lz -lbz2' \
      -DPDM_ENABLE_LONG_G_NUM=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DPython_EXECUTABLE="${PYTHON_EXECUTABLE}" \
      -DPython_ROOT_DIR="$(dirname $(dirname ${PYTHON_EXECUTABLE}))" \
      -DPython_INCLUDE_DIRS="${PYTHON_INCLUDE_DIR}" \
      -DPython_NumPy_INCLUDE_DIRS="${NUMPY_INCLUDE_DIR}" \
      -DPython3_EXECUTABLE="${PYTHON_EXECUTABLE}" \
      -DPython3_INCLUDE_DIRS="${PYTHON_INCLUDE_DIR}" \
      -DPython3_NumPy_INCLUDE_DIRS="${NUMPY_INCLUDE_DIR}" \
      -DPython_NumPy=ON && \
    make -j && \
    make install

# Fix PYTHONPATH warning by initializing it explicitly
ENV PYTHONPATH=/home/jovyan/Maia/Dist/lib:${PYTHONPATH}

# Expose port for JupyterLab
EXPOSE 8888

# Start JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--ServerApp.token=''"]
