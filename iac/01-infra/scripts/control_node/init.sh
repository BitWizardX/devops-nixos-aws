#!/bin/bash

set -euxo pipefail

export DEBIAN_FRONTEND="noninteractive"
export PIPX_HOME="/opt/pipx"
export PIPX_BIN_DIR="/usr/local/bin"

WORKDIR="/tmp/packages"
DOH_URL="https://cloudflare-dns.com/dns-query"

AWS_SSM_AGENT_PACKAGE="amazon-ssm-agent.deb"
AWS_SSM_AGENT_PACKAGE_URL="https://s3.ap-northeast-1.amazonaws.com/amazon-ssm-ap-northeast-1/latest/debian_amd64/amazon-ssm-agent.deb"

AWS_SSM_PLUGIN_PACKAGE="session-manager-plugin.deb"
AWS_SSM_PLUGIN_PACKAGE_URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb"

AWS_CLI_PACKAGE="awscliv2.zip"
AWS_CLI_PACKAGE_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"

TARGET_USER="admin"

download_files() {
  mkdir --parents "${WORKDIR}"
  cd "${WORKDIR}"

  curl --compressed \
    --disallow-username-in-url \
    --doh-url "${DOH_URL}" \
    --fail \
    --false-start \
    --location \
    --parallel \
    --remote-time \
    --show-error \
    --silent \
    --tcp-fastopen \
    --tcp-nodelay \
    -o "${AWS_SSM_AGENT_PACKAGE}" "${AWS_SSM_AGENT_PACKAGE_URL}" \
    -o "${AWS_SSM_PLUGIN_PACKAGE}" "${AWS_SSM_PLUGIN_PACKAGE_URL}" \
    -o "${AWS_CLI_PACKAGE}" "${AWS_CLI_PACKAGE_URL}"
}

install_aws_ssm_agent() {
  apt-get install --yes "${WORKDIR}/${AWS_SSM_AGENT_PACKAGE}"
}

install_aws_ssm_plugin() {
  apt-get install --yes "${WORKDIR}/${AWS_SSM_PLUGIN_PACKAGE}"
}

install_awscli() {
  unzip -q "${WORKDIR}/${AWS_CLI_PACKAGE}" -d "${WORKDIR}"
  "${WORKDIR}/aws/install"
}

install_ansible() {
  pipx install --include-deps ansible
  pipx inject --include-apps ansible argcomplete boto3 botocore
  su - "${TARGET_USER}" -c "activate-global-python-argcomplete --user"
}

clean() {
  rm --force --recursive "${WORKDIR}"

  apt-get autopurge --yes
  apt-get clean
}

main() {
  trap clean EXIT

  download_files
  install_aws_ssm_agent
  install_aws_ssm_plugin
  install_awscli
  install_ansible
}

main "$@"
