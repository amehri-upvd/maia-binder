# Utiliser micromamba avec activation explicite de l'environnement
FROM mambaorg/micromamba:1.5.8

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV HOME=/home/${NB_USER}
ENV CONDA_ENV=maia_tutorials

# Configuration système
USER root
RUN useradd --create-home --uid ${NB_UID} ${NB_USER} && \
    chown -R ${NB_USER}:${NB_USER} ${HOME}

# Installation des dépendances système (optimisé en une seule couche)
RUN apt-get update && apt-get install -y --no-install-recommends \
        g++ build-essential openmpi-bin libopenmpi-dev \
        git cmake make \
        zlib1g-dev libbz2-dev \
        software-properties-common python3-dev \
        libscotchparmetis-dev libptscotch-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copie du fichier environment.yml
COPY --chown=${NB_USER}:${NB_USER} environment.yml ${HOME}/

# Configuration Conda
USER ${NB_USER}
WORKDIR ${HOME}

# Création de l'environnement Conda avec vérification
RUN micromamba env create -f environment.yml -n ${CONDA_ENV} && \
    micromamba clean --all --yes

# Activation permanente de l'environnement Conda
ENV ENV_NAME=${CONDA_ENV}
RUN echo "micromamba activate ${ENV_NAME}" >> ~/.bashrc
SHELL ["/bin/bash", "--login", "-c"]

# Installation de MAIA avec activation explicite de l'environnement
RUN git clone https://github.com/onera/Maia.git && \
    cd Maia && \
    git submodule update --init && \
    mkdir -p build && cd build && \
    source activate ${ENV_NAME} && \
    cmake .. \
      -DCMAKE_INSTALL_PREFIX=/opt/conda/envs/${ENV_NAME} \
      -DCMAKE_C_COMPILER=mpicc \
      -DCMAKE_CXX_COMPILER=mpicxx \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_BUILD_TYPE=Release \
      -DPython_EXECUTABLE=/opt/conda/envs/${ENV_NAME}/bin/python && \
    make  && \
    make install 

# Configuration finale
ENV PATH="/opt/conda/envs/${ENV_NAME}/bin:${PATH}"
EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--ServerApp.token=''"]
