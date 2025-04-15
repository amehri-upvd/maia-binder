# Use a Conda base image compatible with Binder
FROM mambaorg/micromamba:1.5.8

# Define arguments for user setup
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV NB_USER=${NB_USER}
ENV NB_UID=${NB_UID}
ENV HOME=/home/${NB_USER}
ARG ENV_NAME=maia-env
ENV ENV_NAME=${ENV_NAME}

# Run root-privileged operations
USER root
RUN useradd --create-home --uid ${NB_UID} ${NB_USER} && \
    chown -R ${NB_USER}:${NB_USER} ${HOME}

# Install system dependencies using apt-get
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    make \
    zlib1g-dev \
    libbz2-dev \
    build-essential \
    software-properties-common \
    python3-dev \
    libscotchparmetis-dev \
    libptscotch-dev \
    libopenmpi-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Switch to jovyan user
USER ${NB_USER}
WORKDIR ${HOME}

# Copier environment.yml
COPY --chown=${NB_USER}:${NB_USER} environment.yml ${HOME}/


# Activate Conda environment and set environment variables
RUN micromamba env create -f environment.yml -n ${ENV_NAME} && \
    micromamba clean --all --yes

# Activation permanente de l'environnement
ENV PATH="/opt/conda/envs/${ENV_NAME}/bin:${PATH}"
ENV CONDA_DEFAULT_ENV=${ENV_NAME}

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

ENV PATH="/opt/conda/envs/${ENV_NAME}/bin:${PATH}"
    

# Expose port for JupyterLab
EXPOSE 8888

# Start JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--ServerApp.token=''"]
