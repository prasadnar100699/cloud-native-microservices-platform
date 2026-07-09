# 1. Create your state bucket in us-east-1
aws s3api create-bucket --bucket prasad-ops-tfstate-bucket --region us-east-1

# 2. Create the DynamoDB table to handle state-locking (prevents corrupting state)
aws dynamodb create-table \
    --table-name terraform-lock-table \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region us-east-1