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



RUN apt-get -y install gcc

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

COPY ./pyenv.yml /home/coder/conda/pyenv.yml

RUN conda env create -f /home/coder/conda/pyenv.yml

RUN activate py3 

RUN sudo apt-get -y install g++
RUN sudo apt-get -y install lldb 
RUN sudo apt-get -y install cmake

##########################################
########## SETUP Visual Studio Code
#########################################


RUN mkdir -p ~/.local/lib ~/.local/bin
RUN curl -fL https://github.com/cdr/code-server/releases/download/v3.4.1/code-server-3.4.1-linux-amd64.tar.gz \
  | tar -C ~/.local/lib -xz
RUN mv ~/.local/lib/code-server-3.4.1-linux-amd64 ~/.local/lib/code-server-3.4.1
RUN ln -s ~/.local/lib/code-server-3.4.1/bin/code-server ~/.local/bin/code-server
ENV PATH="/home/coder/.local/bin:${PATH}"

ENV SHELL /bin/bash


WORKDIR /home/coder
RUN echo $(echo "source activate py3" >> /home/coder/.bashrc)
COPY  --chown=coder ./settings.json ./.local/share/code-server/User/settings.json

RUN code-server --version
RUN code-server --install-extension ms-vscode.cpptools
RUN code-server --install-extension ms-python.python@2020.5.86806
RUN code-server --install-extension ms-vscode.cmake-tools
RUN code-server --install-extension twxs.cmake

#RUN code-server
#COPY ./config.yaml /home/coder/.config/code-server/config.yaml
#COPY --chown=coder ./test1  /home/coder/project2

RUN echo $(cat ~/.config/code-server/config.yaml)

COPY --chown=coder ./start.sh /home/coder/start.sh

SHELL ["/bin/bash", "-c"]

ENTRYPOINT ["dumb-init", "start.sh"]
#ENTRYPOINT ["dumb-init", "/bin/bash"]