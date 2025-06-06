#!/bin/bash

KEYCLOAK_HOME=/opt/keycloak
KEYCLOAK_URL=http://localhost:8080
KEYCLOAK_REALM=test-realm
KEYCLOAK_REALM_DISPLAY_NAME="TEST REALM"
KEYCLOAK_DEBUG='["true"]'
KEYCLOAK_LDAP_CONNECTION_URL='["ldap://openldap"]'
KEYCLOAK_USERS_DN='["ou=users,dc=example,dc=org"]'
KEYCLOAK_BIND_DN='["cn=admin,dc=example,dc=org"]'
KEYCLOAK_BIND_CREDENTIAL='["admin_password"]'
KEYCLOAK_USER_OBJECT_CLASSES='["person","organizationalPerson","inetOrgPerson"]'
KEYCLOAK_KERBEROS_AUTHN='["false"]'
KEYCLOAK_KERBEROS_FOR_PASS='["false"]'


echo "-----------------"
echo "| Step A: Login |"
echo "-----------------"
${KEYCLOAK_HOME}/bin/kcadm.sh config credentials --server "${KEYCLOAK_URL}" --realm master --user "${KC_BOOTSTRAP_ADMIN_USERNAME}" --password "${KC_BOOTSTRAP_ADMIN_PASSWORD}"

echo "------------------------"
echo "| Step B: Create Realm |"
echo "------------------------"
${KEYCLOAK_HOME}/bin/kcadm.sh create realms -s id=${KEYCLOAK_REALM} -s realm="${KEYCLOAK_REALM}" -s enabled=true -s displayName="${KEYCLOAK_REALM_DISPLAY_NAME}" -s loginWithEmailAllowed=false

echo "----------------------------------------"
echo "| Step C.1: Create LDAP Storage Provider |"
echo "----------------------------------------"
${KEYCLOAK_HOME}/bin/kcadm.sh create components -r ${KEYCLOAK_REALM} -s parentId=${KEYCLOAK_REALM} \
    -s id=${KEYCLOAK_REALM}-ldap-provider -s name=${KEYCLOAK_REALM}-ldap-provider \
    -s providerId=ldap -s providerType=org.keycloak.storage.UserStorageProvider \
    -s config.debug=${KEYCLOAK_DEBUG} \
    -s config.authType='["simple"]' \
    -s config.vendor='["other"]' \
    -s config.priority='["0"]' \
    -s config.connectionUrl=${KEYCLOAK_LDAP_CONNECTION_URL} \
    -s config.editMode='["UNSYNCED"]' \
    -s config.usersDn=${KEYCLOAK_USERS_DN} \
    -s config.serverPrincipal='[""]' \
    -s config.bindDn="${KEYCLOAK_BIND_DN}" \
    -s config.bindCredential=${KEYCLOAK_BIND_CREDENTIAL} \
    -s 'config.fullSyncPeriod=["86400"]' \
    -s 'config.changedSyncPeriod=["-1"]' \
    -s 'config.cachePolicy=["NO_CACHE"]' \
    -s config.evictionDay=[] \
    -s config.evictionHour=[] \
    -s config.evictionMinute=[] \
    -s config.maxLifespan=[] \
    -s config.importEnabled='["true"]' \
    -s 'config.batchSizeForSync=["1000"]' \
    -s 'config.syncRegistrations=["false"]' \
    -s 'config.usernameLDAPAttribute=["uid"]' \
    -s 'config.rdnLDAPAttribute=["uid"]' \
    -s 'config.uuidLDAPAttribute=["uid"]' \
    -s config.userObjectClasses="${KEYCLOAK_USER_OBJECT_CLASSES}" \
    -s 'config.searchScope=["2"]' \
    -s 'config.useTruststoreSpi=["Always"]' \
    -s 'config.connectionPooling=["true"]' \
    -s 'config.pagination=["true"]' \
    -s config.allowKerberosAuthentication=${KEYCLOAK_KERBEROS_AUTHN} \
    -s config.keyTab='[""]' \
    -s config.kerberosRealm='[""]' \
    -s config.useKerberosForPasswordAuthentication=${KEYCLOAK_KERBEROS_FOR_PASS}

echo "----------------------------------------"
echo "| Step C.2: Create group LDAP mapper |"
echo "----------------------------------------"
${KEYCLOAK_HOME}/bin/kcadm.sh  create components \
    -r ${KEYCLOAK_REALM} \
    -s name=group-ldap-mapper \
    -s providerId=group-ldap-mapper \
    -s providerType=org.keycloak.storage.ldap.mappers.LDAPStorageMapper \
    -s parentId=${KEYCLOAK_REALM}-ldap-provider \
    -s 'config."groups.dn"=["ou=groups,dc=example,dc=org"]' \
    -s 'config."group.name.ldap.attribute"=["cn"]' \
    -s 'config."group.object.classes"=["groupOfNames"]' \
    -s 'config."preserve.group.inheritance"=["false"]' \
    -s 'config."membership.ldap.attribute"=["member"]' \
    -s 'config."membership.attribute.type"=["DN"]' \
    -s 'config."groups.ldap.filter"=["(!(cn='testGroup1'))"]' \
    -s 'config.mode=["READ_ONLY"]' \
    -s 'config."user.roles.retrieve.strategy"=["LOAD_GROUPS_BY_MEMBER_ATTRIBUTE"]' \
    -s 'config."mapped.group.attributes"=[""]' \
    -s 'config."drop.non.existing.groups.during.sync"=["true"]' \
    -s 'config.roles=["admins"]' \
    -s 'config.groups=[""]' \
    -s 'config.group=[]' \
    -s 'config.preserve=["false"]' \
    -s 'config.membership=["member"]'

echo "----------------------"
echo "| Step D: Sync Users |"
echo "----------------------"
${KEYCLOAK_HOME}/bin/kcadm.sh create -r ${KEYCLOAK_REALM} user-storage/${KEYCLOAK_REALM}-ldap-provider/sync?action=triggerFullSync

echo "-------------------------------"
echo "| Step E: Query for firstName |"
echo "-------------------------------"
${KEYCLOAK_HOME}/bin/kcadm.sh get users -r ${KEYCLOAK_REALM} | grep firstName