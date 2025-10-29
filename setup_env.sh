#!/usr/bin/env bash

# setup package manager
mkdir -p $PWD/bin
wget -q https://github.com/mamba-org/micromamba-releases/releases/download/2.3.3-0/micromamba-linux-64 -O $PWD/bin/mamba
chmod +x $PWD/bin/mamba
cp "$PWD/bin/mamba" "$PWD/bin/conda"

# init shell
export PATH=$PWD/bin:$PATH
eval "$(mamba shell hook --shell bash)"

# install dependencies
mamba create -n vizfold --file environment.yml -y
mamba activate vizfold
export LIBRARY_PATH=$CONDA_PREFIX/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
export CUDA_HOME=$CONDA_PREFIX

# install project
./scripts/install_third_party_dependencies.sh
./scripts/download_openfold_params.sh

