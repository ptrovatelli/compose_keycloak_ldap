#!/bin/bash

echo "--------------------------"
echo "| Step 1: Start Keycloak |"
echo "--------------------------"

/opt/keycloak/bin/kc.sh start-dev &

echo "--------------------------------------"
echo "| Step 2: Wait for Keycloak to start |"
echo "--------------------------------------"
echo "Waiting for keycloak to start........"
# Keycloak container no longer has curl installed...
#until curl http://keycloak:8080 -sf -o /dev/null;
#do
#  echo $(date) " Still waiting for keycloak to accept requests..."
  sleep 90
#done

echo "---------------------"
echo "| Step 3: Configure |"
echo "---------------------"
/init/setup.sh

echo "----------"
echo "| READY! |"
echo "----------"

sleep infinity