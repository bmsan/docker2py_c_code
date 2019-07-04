FROM node:10.15.1
RUN apt-get update && apt-get install -y \
	libxkbfile-dev \
	libsecret-1-dev
	
FROM ubuntu:18.04

RUN apt-get -y update

RUN apt-get update && apt-get install -y \
	openssl \
	net-tools \
	git \
	locales \
	sudo \
	dumb-init \
	vim \
	curl \
	wget
	
RUN locale-gen en_US.UTF-8
# We unfortunately cannot use update-locale because docker will not use the env variables
# configured in /etc/default/locale so we need to set it manually.
ENV LC_ALL=en_US.UTF-8



RUN apt-get update &&  apt-get -y install gcc g++ cmake

# http://packages.ubuntu.com/de/trusty/valgrind
RUN apt-get -y install valgrind





RUN adduser --gecos '' --disabled-password coder && \
	echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

USER coder

RUN mkdir -p /home/coder/project

##########################################
########## SETUP PYTHON
##########################################
RUN mkdir -p /home/coder/conda

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /home/coder/conda/miniconda.sh
#COPY ./Miniconda3-latest-Linux-x86_64.sh /home/coder/conda/miniconda.sh


RUN bash /home/coder/conda/miniconda.sh -b -p /home/coder/conda/miniconda
ENV PATH="/home/coder/conda/miniconda/bin:${PATH}"

RUN conda create -n py3 python=3.6

RUN pip install cffi
RUN pip install numpy
RUN pip install pillow 
RUN conda install pytorch-cpu torchvision-cpu -c pytorch
RUN pip install jupyter
RUN pip install pip
RUN pip install matplotlib
RUN pip install pyyaml
RUN pip install tqdm
RUN pip install typing


RUN activate py3 



##########################################
########## SETUP Visual Studio Code
#########################################
WORKDIR /home/coder/project

RUN wget https://github.com/cdr/code-server/releases/download/1.1156-vsc1.33.1/code-server1.1156-vsc1.33.1-linux-x64.tar.gz
RUN tar -xvzf code-server1.1156-vsc1.33.1-linux-x64.tar.gz
#COPY ./code-server /usr/local/bin/code-server
RUN chmod +x /usr/local/bin/code-server

RUN code-server --install-extension ms-vscode.cpptools
RUN code-server --install-extension ms-python.python
RUN code-server --install-extension vector-of-bool.cmake-tools
RUN code-server --install-extension twxs.cmake


ENTRYPOINT ["dumb-init", "code-server"]