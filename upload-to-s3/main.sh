#!/bin/sh

log_and_exit_1() {
    printf "\033[38;2;201;71;71m%s: %s\033[0m\n" "error" "$1"
    return 1
}

get_file_path() {
    if [ ! "$1" = "" ]; then
        echo "$1"
        return
    fi

    echo "$FILE_PATH"
}

get_content_type() {
    if [ ! "$2" = "" ]; then
        echo "$2"
        return
    fi

    echo "$CONTENT_TYPE"
}

validate_inputs() {
    FILE_PATH=$(get_file_path "$@")

    if [ "$FILE_PATH" = "" ]; then
        log_and_exit_1 "missing input file"
    elif ! test -f "$FILE_PATH"; then
        log_and_exit_1 "file '$FILE_PATH' doesn't exist"
    fi

    if [ "$AWS_KEY" = "" ]; then
        log_and_exit_1 "missing 'AWS_KEY' environment variable"
    elif [ "$AWS_SECRET" = "" ]; then
        log_and_exit_1 "missing 'AWS_SECRET' environment variable"
    fi

    if [ "$S3_ACCESS_CONTROL" = "" ]; then
        log_and_exit_1 "missing 'S3_ACCESS_CONTROL' environment variable"
    elif [ "$S3_BUCKET_NAME" = "" ]; then
        log_and_exit_1 "missing 'S3_BUCKET_NAME' environment variable"

    fi

    # https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#canned-acl
    valid_acl_values="private public-read public-read-write aws-exec-read authenticated-read bucket-owner-read bucket-owner-full-control"

    if ! echo "$valid_acl_values" | grep -q "\\b$S3_ACCESS_CONTROL\\b"; then
        log_and_exit_1 "invalid 'S3_ACCESS_CONTROL'"
    fi
}

upload_file_to_S3() {
    S3_ACL="x-amz-acl:$S3_ACCESS_CONTROL"

    FILE_PATH=$(get_file_path "$@")

    CONTENT_TYPE=$(get_content_type "$@")
    if [ "$CONTENT_TYPE" = "" ]; then
        CONTENT_TYPE="$(file --mime-type "$FILE_PATH")"
    fi

    file_name=$(basename "$FILE_PATH")

    if [ "$S3_OBJECT_NAME" = "" ]; then
        S3_OBJECT_NAME="$file_name"
    fi

    if [ ! "$S3_BUCKET_PATH" = "" ]; then
        # Removing the slash at the beginning if needed
        S3_BUCKET_PATH="${S3_BUCKET_PATH#\/}"
        # Adding slash at the end if needed
        S3_BUCKET_PATH="${S3_BUCKET_PATH%/}/"
    fi

    date=$(date -R)

    sig_string="PUT\n\n$CONTENT_TYPE\n$date\n$S3_ACL\n/$S3_BUCKET_NAME/$S3_BUCKET_PATH$S3_OBJECT_NAME"
    signature=$(printf "$sig_string" | openssl sha1 -hmac "${AWS_SECRET}" -binary | base64)

    url="https://$S3_BUCKET_NAME.s3.amazonaws.com/$S3_BUCKET_PATH$S3_OBJECT_NAME"

    printf "\033[38;2;235;180;136mUploading '%s' to '%s'...\033[0m\n" "$FILE_PATH" "$url"

    curl -X PUT -T "$(readlink -f "$FILE_PATH")" \
        -H "Host: $S3_BUCKET_NAME.s3.amazonaws.com" \
        -H "Date: $date" \
        -H "$S3_ACL" \
        -H "Content-Type: $CONTENT_TYPE" \
        -H "Authorization: AWS ${AWS_KEY}:$signature" \
        "$url"

    printf "\n\033[38;2;237;233;242mDone\033[0m\n"
}

main() {
    set -e
    validate_inputs "$@"
    upload_file_to_S3 "$@"
}

main "$@"
