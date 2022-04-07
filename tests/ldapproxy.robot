*** Settings ***
Library    SSHLibrary

*** Test Cases ***
Check if ldapproxy service is loaded correctly
    ${output}  ${rc} =    Execute Command    ssh -o StrictHostKeyChecking=no ldapproxy1@localhost systemctl --user show --property=LoadState ldapproxy
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Be Equal As Strings    ${output}    LoadState=loaded
