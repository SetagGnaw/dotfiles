function prof(){
    aws configure list-profiles
    # cat ~/.aws/credentials
}

function freetier(){
    aws ec2 describe-instance-types \
        --filters "Name=free-tier-eligible,Values=true" \
        --query "InstanceTypes[].InstanceType" --region us-east-1
}
