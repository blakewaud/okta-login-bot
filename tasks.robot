*** Settings ***
Documentation       Logs into an Okta SSO environment on a schedule to confirm account is working.

Library             RPA.Browser.Playwright
Library             RPA.Robocorp.Vault
Library             RPA.Robocorp.WorkItems


*** Tasks ***
Login to Okta
    Attempt initial login    %{DOMAIN}    %{SECRET}    %{USER_KEY}    %{PASS_KEY}
    Try to answer security question    %{SECRET}    %{QUESTION_KEY}
    Verify we are logged in    %{EXPECTED_VERIFICATION_LOCATOR}


*** Keywords ***
Attempt initial login
    [Documentation]    Starts the login process by filling in username/password and clicking login.
    [Arguments]    ${login_domain}    ${secret_name}    ${username_key}=username    ${password_key}=password
    New browser
    New context
    New page    https://${login_domain}.okta.com/signin
    ${creds}=    Get secret    ${secret_name}
    Fill text    id=okta-signin-username    ${creds}[${username_key}]
    Fill secret    id=okta-signin-password    $creds["${password_key}"]
    Click    id=okta-signin-submit

Try to answer security question
    [Documentation]
    ...    Tries to answer the security question, if none is experienced, it assumes login
    ...    was successful without the need to asnwer it.
    [Arguments]    ${secret_name}    ${question_key}=question
    ${creds}=    Get secret    ${secret_name}
    TRY
        Fill secret    xpath=//input[@name="answer"]    $creds["${question_key}"]
        Click    text=Verify
    EXCEPT    EOFError    type=starts
        Log    Security question not visible, we are likely logged in already.
    END

Verify we are logged in
    [Documentation]    Checks if the provided locator exists
    [Arguments]    ${check_locator}=text\=My Apps
    TRY
        Wait for elements state    ${check_locator}
    EXCEPT    EOFError
        Release input work item
        ...    FAILED
        ...    exception_type=APPLICATION
        ...    code=LOGIN_VERIFY_FAILED
        ...    message=Locator '${check_locator}' could not be found, application did not successfully login.
    END
