# Utiliser micromamba seulement
FROM mambaorg/micromamba:1.5.8

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV NB_USER=${NB_USER}
ENV NB_UID=${NB_UID}
ENV HOME=/home/${NB_USER}

# Créer l'utilisateur
USER root
RUN useradd --create-home --uid ${NB_UID} ${NB_USER} && \
    chown -R ${NB_USER}:${NB_USER} ${HOME}

# Installer dépendances système
RUN apt-get update && \
    apt-get install -y \
        g++ build-essential openmpi-bin libopenmpi-dev \
        git cmake make \
        zlib1g-dev libbz2-dev \
        software-properties-common python3-dev \
        libscotchparmetis-dev libptscotch-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copier les fichiers nécessaires
COPY --chown=${NB_USER}:${NB_USER} environment.yml ./

# Créer l'environnement conda avec micromamba
# Définir le répertoire de travail
WORKDIR ${HOME}
# Créer l'environnement conda avec micromamba
USER ${NB_USER}
RUN micromamba env create -f environment.yml && micromamba clean --all --yes

# Activer l’environnement
ENV PATH=/opt/conda/envs/maia_tutorials/bin:$PATH
ENV CONDA_DEFAULT_ENV=maia_tutorials

# Installer numpy via pip
RUN pip install numpy

# Cloner et installer MAIA
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
    make && make install

ENV PYTHONPATH=/opt/conda/envs/maia_tutorials/lib

EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--ServerApp.token=''"]
