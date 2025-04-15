FROM mambaorg/micromamba:1.5.8

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV NB_USER=${NB_USER} \
    NB_UID=${NB_UID} \
    HOME=/home/${NB_USER}

USER root
RUN apt-get update && apt-get install -y \
    git cmake make zlib1g-dev libbz2-dev \
    libparmetis-dev libptscotch-dev libopenmpi-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid ${NB_UID} ${NB_USER} \
    && chown -R ${NB_USER}:${NB_USER} ${HOME}

USER ${NB_USER}
WORKDIR ${HOME}

RUN micromamba create -n maia-env -c conda-forge \
    python=3.9 \
    numpy=1.26.0 \
    mpi4py=3.1.5 \
    openmpi \
    jupyterlab \
    && micromamba clean --all --yes

ENV CONDA_PREFIX=/opt/conda/envs/maia-env \
    PATH=/opt/conda/envs/maia-env/bin:$PATH

RUN git clone https://github.com/onera/Maia.git && \
    cd Maia && \
    git submodule update --init && \
    mkdir -p build && cd build && \
    cmake .. \
      -DCMAKE_INSTALL_PREFIX=${CONDA_PREFIX} \
      -DCMAKE_CXX_STANDARD=17 \
      -DPython_EXECUTABLE=${CONDA_PREFIX}/bin/python \
      -DPython3_NumPy_INCLUDE_DIRS=${CONDA_PREFIX}/lib/python3.9/site-packages/numpy/core/include \
    && make -j $(nproc) \
    && make install

EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--ServerApp.token=''"]
