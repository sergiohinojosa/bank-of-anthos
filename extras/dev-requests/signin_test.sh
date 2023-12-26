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

do_signin() {
    curl -v -X POST "http://$easytravel_dns/easytravel/rest/signin" \
        -H "accept: application/json" \
        -H "x-developer: $developer_name" \
        -H "Content-Type: application/json" \
        -d "$(get_login_body)"
}

if [[ $# -eq 1 ]]; then
    developer_name=$1
    echo "----------------------------------------------"
    echo "Creating a SignIn for developer:$developer_name"
    do_signin
else
    echo "----------------------------------------------"
    echo "You need to pass 1 parameter                  "
    echo "Usage >bash signin_test.sh <developer_name>    "
fi
