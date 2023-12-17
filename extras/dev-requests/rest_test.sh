
#!/bin/bash

bankofAnthosURL="development-banking.34-118-0-68.sslip.io"
developer_name=""
developer_pass=""

get_signin_body() {
cat <<EOF
username=$developer_name&\
password=$developer_pass&\
password-repeat=$developer_pass&\
firstname=$developer_name&\
lastname=$developer_name&\
address=123+Nth+Avenue%2C+New+York+City&\
country=United+States&\
state=NY&\
zip=10004&\
ssn=111-22-3333&\
birthday=2023-12-07&\
timezone=-5
EOF
}

get_login_body() {
cat <<EOF
username=$developer_name&\
password=$developer_pass
EOF
}

do_signin() {
    result=$(curl -X POST "http://$bankofAnthosURL/signup" \
        -H "accept: application/json" \
        -H "x-developer: $developer_name" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "$(get_signin_body)"
        )
        echo "$result";

}

do_login() {
    result=$(curl -X POST "http://$bankofAnthosURL/login" \
        -H "accept: application/json" \
        -H "x-developer: $developer_name" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "$(get_login_body)"
        )

}

print_usage() {
    echo "Usage: bash rest_test.sh [test_function] [developer_name] [developer_pass]    "
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

if [[ $# -eq 3 ]]; then

    test_function=$1
    developer_name=$2
    developer_pass=$3

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
    echo "You need to pass exactly 3 parameters                          "
    echo ""
    print_usage

fi
