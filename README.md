# Description

This project was setup to test ldap filters when pulling ldap groups from keycloak. 

It includes 2 docker-compose files: 

- docker-compose.yml : for quick test, no database for keycloak. Keycloak configuration is automated through the init script
- docker-compose-with-persistence.yml : Keycloak configuration is not automated. This is for manual configurations. Changes in keycloak are saved on a volumes so that they are not lost when container is destroyed

# setup

## Install

```
docker compose up
```

## Configure ldap

This is a one time action (configuration is saved in a volume)

For some reason the container fails if the `ldif/bootstrap.ldif` contains instructions, so: 

- after first startup, populate the `ldif/bootstrap.ldif` with: 

  - `cp bootstrap.ldif ldif/`

- then apply the ldap configuration by exec-ing into the `keycloak_stack-openldap-1` container. Then remove the file content for further restarts:

```
docker exec -it keycloak_stack-openldap-1 /bin/sh
ldapadd -Z -D cn=admin,dc=example,dc=org -w admin_password -f /container/service/slapd/assets/config/bootstrap/ldif/custom/bootstrap.ldif
> /container/service/slapd/assets/config/bootstrap/ldif/custom/bootstrap.ldif
```

## Configure keycloak

This is automatically configured with the entrypoint.

For reference: 

user federation, add ldap provider:

- vendor: other
- Connection URL: `ldap://openldap`
- bind type: `simple`
- bind dn: `cn=admin,dc=example,dc=org`
- bind credentials: `admin_password`
- edit mode: `UNSYNCED`
- users DN: `ou=users,dc=example,dc=org`
- UUID LDAP attribute: `uid`
- User object classes: `person,organizationalPerson,inetOrgPerson`
- Search scope: `subtree`
- Sync registration: `Off`
- Cache settings: `NO_CACHE`

group ldap mapper:

- mapper type: `group-ldap-mapper`

- LDAP Groups DN: `ou=groups,dc=example,dc=org`

- Preserve Group Inheritance : `Off`

- LDAP Filter: `(!(cn=testGroup1))`

  - Do not add a quote in this filter it would break it!

- Mode: `READ_ONLY`

- User Groups Retrieve Strategy: `LOAD_GROUP_BY_MEMBER_ATTRIBUTE`

- Drop non-existing groups during sync: `On`

  

# Test

Just restart the app, wait for keycloak to start and the init script to run and check standard output

```
docker compose down
docker compose up
```

Expected: `testGroup1` not present:

```
keycloak_container    | -------------------------------
keycloak_container    | | Step F: Query for group names |
keycloak_container    | -------------------------------
keycloak_container    |   "name" : "prodGroup1",
```



# Access

- keycloak: http://localhost:8080/admin/master/console/ `admin` / `admin`
- phpldapadmin: http://localhost:8099 `cn=admin,dc=example,dc=org` / `admin_password`

# Testing ldap filter

```
docker exec -it keycloak_stack-openldap-1 /bin/sh
ldapsearch -Z -D cn=admin,dc=example,dc=org -w admin_password -b "ou=groups,dc=example,dc=org" '(!(cn=testGroup1))' dn
# extended LDIF
#
# LDAPv3
# base <ou=groups,dc=example,dc=org> with scope subtree
# filter: (!(cn=testGroup1))
# requesting: dn
#

# groups, example.org
dn: ou=groups,dc=example,dc=org

# prod, groups, example.org
dn: ou=prod,ou=groups,dc=example,dc=org

# test, groups, example.org
dn: ou=test,ou=groups,dc=example,dc=org

# prodGroup1, prod, groups, example.org
dn: cn=prodGroup1,ou=prod,ou=groups,dc=example,dc=org

# search result
search: 3
result: 0 Success

# numResponses: 5
# numEntries: 4
#
```

=> OK `testGroup1` is excluded



Without the filter, `testGroup1` is found: 

```
docker exec -it keycloak_stack-openldap-1 /bin/sh
ldapsearch -Z -D cn=admin,dc=example,dc=org -w admin_password -b "ou=groups,dc=example,dc=org" dn
...
# prodGroup1, prod, groups, example.org
dn: cn=prodGroup1,ou=prod,ou=groups,dc=example,dc=org

# testGroup1, test, groups, example.org
dn: cn=testGroup1,ou=test,ou=groups,dc=example,dc=org

```

