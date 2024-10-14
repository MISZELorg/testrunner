# base image
FROM ubuntu:24.04
# input GitHub runner version argument
ARG RUNNER_VERSION
ENV DEBIAN_FRONTEND=noninteractive
LABEL BaseImage="ubuntu:24.04"
LABEL RunnerVersion=${RUNNER_VERSION}
# update the base packages + add a non-sudo user
RUN apt-get update -y && apt-get upgrade -y && useradd -m docker
# install prerequisites
RUN apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    software-properties-common
# Add the Microsoft signing key and the Azure CLI APT repository
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list
# Update package list and install required packages
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    curl nodejs wget unzip vim git azure-cli jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip
# cd into the user directory, download and unzip the GitHub Actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
# install some additional dependencies
RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh
# add over the start.sh script
ADD scripts/start.sh /home/docker/start.sh
# make the script executable
RUN chmod +x /home/docker/start.sh
# set the user to "docker" so all subsequent commands are run as the docker user
USER docker
# set the entrypoint to the start.sh script
ENTRYPOINT ["/home/docker/start.sh"]