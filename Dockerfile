# Utiliser micromamba seulement
FROM mambaorg/micromamba:1.5.8

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV HOME=/home/${NB_USER}

# Créer l'utilisateur et permissions
USER root
RUN useradd --create-home --uid ${NB_UID} ${NB_USER} && \
    chown -R ${NB_USER}:${NB_USER} ${HOME}

# Installer dépendances système (optimisé en une seule couche)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ build-essential openmpi-bin libopenmpi-dev \
        git cmake make \
        zlib1g-dev libbz2-dev \
        software-properties-common python3-dev \
        libscotchparmetis-dev libptscotch-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copier environment.yml en chemin absolu
COPY --chown=${NB_USER}:${NB_USER} environment.yml ${HOME}/

# Configuration conda
USER ${NB_USER}
WORKDIR ${HOME}

# Créer l'environnement conda (avec vérification de fichier)
RUN ls -l ${HOME}/environment.yml && \
    micromamba env create -f environment.yml -n maia_tutorials && \
    micromamba clean --all --yes

# Activer l'environnement automatiquement
ENV PATH="/opt/conda/envs/maia_tutorials/bin:${PATH}"
ENV CONDA_DEFAULT_ENV=maia_tutorials

# Installation MAIA (optimisé avec suppression des fichiers temporaires)
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
      -DPython_EXECUTABLE=/opt/conda/envs/maia_tutorials/bin/python && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf Maia

EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--ServerApp.token=''"]


EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--ServerApp.token=''"]
