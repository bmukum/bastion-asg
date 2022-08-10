
#!/bin/bash
sudo apt-get update -y

#remove old docker versions
sudo apt-get remove -y docker docker.io containerd runc

# install docker
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo chmod 666 /var/run/docker.sock
sudo update-rc.d  docker defaults
sudo usermod -a -G docker ubuntu

# install git unzip and aws cli
sudo apt-get install git unzip jq -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

#set up ssm
sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
sudo snap install amazon-ssm-agent --classic
sudo snap start amazon-ssm-agent

# #install libssl to get enable connection
# sudo apt-get update && sudo apt-get upgrade -y
# sudo apt install build-essential checkinstall zlib1g-dev -y
# cd /usr/local/src/
# sudo wget https://www.openssl.org/source/openssl-1.1.1c.tar.gz
# sudo tar -xf openssl-1.1.1c.tar.gz
# cd openssl-1.1.1c
# sudo ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib
# sudo make
# #sudo make test
# sudo make install
# sudo chmod 770 /etc/ld.so.conf.d/openssl-1.1.1c.conf
# sudo bash -c 'echo "/usr/local/ssl/lib" >> /etc/ld.so.conf.d/openssl-1.1.1c.conf'
# sudo ldconfig -v
# export PATH=$PATH:"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/ssl/bin"


# install github runner application
sudo apt-get update && sudo apt-get upgrade -y
sudo -u ubuntu mkdir /home/ubuntu/actions-runner
sudo -u ubuntu curl -o /home/ubuntu/actions-runner/actions-runner-linux-x64-2.278.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.278.0/actions-runner-linux-x64-2.278.0.tar.gz
sudo -u ubuntu tar xzf /home/ubuntu/actions-runner/actions-runner-linux-x64-2.278.0.tar.gz -C /home/ubuntu/actions-runner


#configure the runner
echo 'Configuring the runner now'
export PAT=$(sed -e 's/^"//' -e 's/"$//' <<<$(aws ssm get-parameter --name "gha-pat" --with-decryption --query 'Parameter.Value'))
export token=$(curl -s -XPOST \
                -H "authorization: token $PAT" \
                https://api.github.com/repos/Enflick/docker-kubernetes-deploy/actions/runners/registration-token |\
                jq -r .token)
export GITHUB_ACTIONS_RUNNER_TLS_NO_VERIFY=1
export url="https://github.com/Enflick/docker-kubernetes-deploy"
EC2_INSTANCE_ID=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
export name="ubuntu-runner-${EC2_INSTANCE_ID}"
bash -c 'cd /home/ubuntu/actions-runner/;./config.sh --url $url --token $token --name $name --work _work --runasservice'

# start the github runner as a service on startup
cd /home/ubuntu/actions-runner/;./svc.sh install
cd /home/ubuntu/actions-runner/;./svc.sh start
