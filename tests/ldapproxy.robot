*** Settings ***
Library    SSHLibrary

*** Test Cases ***
Check if ldapproxy service is loaded correctly
    ${output}  ${rc} =    Execute Command    runagent -m ldapproxy1 systemctl --user show --property=LoadState ldapproxy
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Be Equal As Strings    ${output}    LoadState=loaded
