# go-send-heartbeat

export AWS_VAULT_FILE_PASSPHRASE="$(cat /root/.awsvaultk)"

aws-vault exec dev -- terraform -chdir=./terraform/01 init
aws-vault exec dev -- terraform -chdir=./terraform/01 apply --auto-approve

source ./terraform/01/terraform.tmp

go mod init go-send-heartbeat
go mod tidy

export HEARTBEAT_QUEUE_URL=https://sqs.<REGION>.amazonaws.com/<ACCOUNT_ID>/<SQS_NAME>

go run cmd/main.go

export HEARTBEAT_RUN_ONCE=true

go run cmd/main.go

mkdir -p ./terraform/02/external
env GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -tags lambda.norpc -ldflags="-s -w" -o ./terraform/02/external/bootstrap ./cmd/main.go
chmod +x ./terraform/02/external/bootstrap
zip -j ./terraform/02/external/bootstrap.zip ./terraform/02/external/bootstrap

aws-vault exec dev -- terraform -chdir=./terraform/02 init
aws-vault exec dev -- terraform -chdir=./terraform/02 apply --auto-approve
