*** Settings ***
Library    SSHLibrary
Library    Collections
Suite Setup       Create the test user domain
Suite Teardown    Remove the test user domain

*** Variables ***
${DOMAIN}          ldapproxy.test
${ADMPASS}         Nethesis,1234
${CLIENT_IMAGE}    docker.io/library/alpine:3

*** Test Cases ***
Listen on all IPv4 addresses
    ${output}  ${rc} =    Execute Command    ss -Htln 'sport = :${LDAP.port}'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Contain    ${output}    0.0.0.0:${LDAP.port}

Reach ldapproxy from a rootless container on the default network
    Query ldapproxy from a rootless container    pasta

Reach ldapproxy from a rootless container with a private address
    Query ldapproxy from a rootless container    pasta:-a,10.0.2.100,-n,24,-g,10.0.2.2

*** Keywords ***
Query ldapproxy from a rootless container
    [Arguments]    ${network}
    ${output}  ${rc} =    Execute Command    runagent -m ldapproxy1 podman run --rm --network=${network} ${CLIENT_IMAGE} sh -c 'apk add -q openldap-clients && ldapsearch -LLL -x -H ldap://cluster-localnode:${LDAP.port} -D "${LDAP.bind_dn}" -w "${LDAP.bind_password}" -s base -b "${LDAP.base_dn}" dn'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Contain    ${output}    dn: ${LDAP.base_dn}

Create the test user domain
    ${output}  ${rc} =    Execute Command    api-cli run add-internal-provider --data '{"image":"openldap","node":1}'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    ${response} =    Evaluate    json.loads('''${output}''')    modules=json
    ${rc} =    Execute Command    api-cli run module/${response['module_id']}/configure-module --data '{"provision":"new-domain","domain":"${DOMAIN}","admuser":"admin","admpass":"${ADMPASS}"}'
    ...    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Wait Until Keyword Succeeds    60s    5s    Get the ldapproxy domain settings

Get the ldapproxy domain settings
    ${output}  ${rc} =    Execute Command    runagent -m ldapproxy1 python3 -c 'import agent.ldapproxy, json; print(json.dumps(agent.ldapproxy.Ldapproxy().get_domain("${DOMAIN}")))'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    ${conf} =    Evaluate    json.loads('''${output}''')    modules=json
    Should Not Be Equal    ${conf}    ${None}
    ${conf} =    Convert To Dictionary    ${conf}
    Set Suite Variable    &{LDAP}    &{conf}

Remove the test user domain
    Execute Command    api-cli run remove-internal-domain --data '{"domain":"${DOMAIN}"}'
    # The domain removal does not raise any event handled by ldapproxy:
    # reload it to release the domain TCP port
    Execute Command    runagent -m ldapproxy1 systemctl --user reload ldapproxy
