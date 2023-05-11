FROM  gitpod/workspace-full:2022-08-17-18-37-55

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    sudo mv ./kubectl /usr/local/bin/kubectl && \
    mkdir ~/.kube

# Install doctl
RUN wget https://github.com/digitalocean/doctl/releases/download/v1.79.0/doctl-1.79.0-linux-amd64.tar.gz && \
    tar xf ./doctl-1.79.0-linux-amd64.tar.gz && \
    rm -rf ./doctl-1.79.0-linux-amd64.tar.gz && \
    sudo mv ./doctl /usr/local/bin

# Install helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh

# Add aliases
RUN echo 'alias k="kubectl"' >> /home/gitpod/.bashrc
