*** Settings ***
Library           SSHLibrary
Library           DateTime
Suite Setup       Setup connection and test suite tools
Suite Teardown    Tear down connection and test suite tools

*** Variables ***
${SSH_KEYFILE}    %{HOME}/.ssh/id_ecdsa
${NODE_ADDR}      127.0.0.1
${SCENARIO}       install
${IMAGE_URL}      ghcr.io/nethserver/ldapproxy:latest
${JOURNAL_SINCE}  0

*** Keywords ***
Connect to the node
    Log    connecting to ${NODE_ADDR}
    Open Connection   ${NODE_ADDR}
    Login With Public Key    root    ${SSH_KEYFILE}
    ${output} =    Execute Command    systemctl is-system-running --wait
    Should Be True    '${output}' == 'running' or '${output}' == 'degraded'

Setup connection and test suite tools
    Connect to the node
    Save the journal begin timestamp
    Run scenario

Tear down connection and test suite tools
    Collect the suite journal

Save the journal begin timestamp
    ${tsnow} =    Get Current Date    result_format=epoch
    Set Global Variable    ${JOURNAL_SINCE}    ${tsnow}

Collect the suite journal
    Execute Command    journalctl -S @${JOURNAL_SINCE} >journal-dump.log
    SSHLibrary.Get File    journal-dump.log    ${OUTPUT DIR}/journal-${SUITE NAME}.log

Run scenario
    Log  Scenario ${SCENARIO} with ${IMAGE_URL}  console=${True}
    IF    r'${SCENARIO}' == 'update'
        ${out}  ${rc} =  Execute Command  api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["ldapproxy1"]}'  return_rc=${True}
        Should Be Equal As Integers  ${rc}  0  action update-module ${IMAGE_URL} failed
    END
