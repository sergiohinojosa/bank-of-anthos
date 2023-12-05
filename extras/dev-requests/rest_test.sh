#!/bin/bash

easytravel_dns="18-133-122-1.nip.io"
developer_name=""

get_signin_body() {
    cat <<EOF
{
    "firstName": "$developer_name",
    "lastName": "$developer_name LastName",
    "email": "$developer_name",
    "password": "$developer_name",
    "state": "Bavaria",
    "city": "Munich",
    "street": "Beer Street 10",
    "door": "1",
    "phone": "+49123456789"
}
EOF
}

get_login_body() {
    cat <<EOF
{
    "username": "$developer_name",
    "password": "$developer_name"
}
EOF
}

do_signin() {
    curl -v POST "http://$easytravel_dns/easytravel/rest/signin" \
        -H "accept: application/json" \
        -H "x-developer: $developer_name" \
        -H "Content-Type: application/json" \
        -d "$(get_signin_body)"
}

do_login() {
    curl -v POST "http://$easytravel_dns/easytravel/rest/login" \
        -H "accept: application/json" \
        -H "x-developer: $developer_name" \
        -H "Content-Type: application/json" \
        -d "$(get_login_body)"
}

print_usage() {
    echo "Usage: bash rest_test.sh [test_function] [developer_name]    "
    echo "                                                                "
    echo "test_function                                                   "
    echo "   signin                          creates the given account    "
    echo "   login                           logins to an account         "
    echo "                                                                "
    echo "================================================================"
}

echo "================================================================"
echo "EasyTravel REST Developer Tester                                "
echo "================================================================"

if [[ $# -eq 2 ]]; then

    test_function=$1
    developer_name=$2

    case $test_function in
    signin)
        echo "----------------------------------------------"
        echo "SignIn: Creating an Account for developer:$developer_name with the following Payload:"
        echo ""
        echo "$(get_signin_body)"
        do_signin
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
    echo "You need to pass exactly 2 parameters                          "
    echo ""
    print_usage

fi
