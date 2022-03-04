#!/bin/sh
printenv

echo "nessusUninstall: $nessusUninstall"


if [ "x$nessusUninstall" = "xtrue" ] ; then
  echo "Performing uninstall of Nessus Agent"
  /opt/nessus_agent/sbin/nessuscli agent unlink
  dpkg -r NessusAgent
  sleep 5
  rm -rf /opt/nessus
else
  echo "Performing install of Nessus Agent"
  curl $linuxBinaryUrl -o NessusAgent.deb

  echo "***Nessus Agent Binary: $linuxBinaryUrl***"
  echo "***Nessus Agent Linking Key: $nessusagentlinkingkey***"
  echo "***Nessus Agent Group: $nessusagentgroup***"

  dpkg -i NessusAgent.deb

  sleep 5
  /bin/systemctl start nessusagent.service

  sleep 10

  /opt/nessus_agent/sbin/nessuscli agent link --key=$nessusagentlinkingkey --groups="$nessusagentgroup" --cloud
fi



