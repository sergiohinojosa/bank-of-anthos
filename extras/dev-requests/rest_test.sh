#!/bin/bash

bankofAnthosURL="development-banking.whydevslovedynatrace.com"
developer_name=""
developer_pass=""

get_signup_body() {
cat <<EOF
username=$developer_name&\
password=$developer_pass&\
password-repeat=$developer_pass&\
firstname=$developer_name&\
lastname=$developer_name&\
birthday=2000-01-01&\
timezone=-5&\
address=123+Nth+Avenue%2C+New+York+City&\
state=NY&\
zip=10004&\
ssn=111-22-3333&\
country=United+States
EOF
}

get_login_body() {
cat <<EOF
username=$developer_name&\
password=$developer_pass
EOF
}

do_signup() {
    result=$(curl -v -X POST "https://$bankofAnthosURL/signup" \
        -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7" \
        -H "x-developer: $developer_name" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "$(get_signup_body)"
        )
        echo "$result";

}

do_login() {
    result=$(curl -v -X POST "https://$bankofAnthosURL/login" \
        -H "accept: application/json" \
        -H "x-developer: $developer_name" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "$(get_login_body)"
        )

}

print_usage() {
    echo "Usage: bash rest_test.sh [test_function] [developer_name] [developer_pass] "
    echo "                                                                           "
    echo "test_function                                                              "
    echo "   signup                          creates the given account               "
    echo "   login                           logins to an account                    "
    echo "                                                                           "
    echo "==========================================================================="
}

echo "================================================================"
echo " Bank REST Developer Tester                                     "
echo "================================================================"

if [[ $# -eq 3 ]]; then

    test_function=$1
    developer_name=$2
    developer_pass=$3

    case $test_function in
    signup)
        echo "----------------------------------------------"
        echo "SignUp: Creating an Account for developer:$developer_name with the following Payload:"
        echo ""
        echo "$(get_signup_body)"
        echo ""
        do_signup
        ;;

    login)
        echo "----------------------------------------------"
        echo "Login: Doing a Login for developer:$developer_name with the following Payload:"
        echo ""
        echo "$(get_login_body)"
        do_login
        ;;
    *)
        echo ""
        echo "Please give a valid test_function and not ($test_function)"
        print_usage
        ;;
    esac
else
    echo ""
    echo "----------------------------------------------"
    echo "You need to pass exactly 3 parameters                          "
    echo ""
    print_usage

fi
