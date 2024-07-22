# go-send-heartbeat

```bash
export AWS_VAULT_FILE_PASSPHRASE="$(cat /root/.awsvaultk)"
```

```bash
aws-vault exec dev -- terraform -chdir=./terraform/01 init
```

```bash
aws-vault exec dev -- terraform -chdir=./terraform/01 apply --auto-approve
```

```bash
source ./terraform/01/terraform.tmp
```

```bash
go mod init go-send-heartbeat
```

```bash
go mod tidy
```

```bash
export HEARTBEAT_QUEUE_URL=https://sqs.<REGION>.amazonaws.com/<ACCOUNT_ID>/<SQS_NAME>
```

```bash
go run cmd/main.go
```

```bash
export HEARTBEAT_RUN_ONCE=true
```

```bash
go run cmd/main.go
```

```bash
mkdir -p ./terraform/02/external
```

```bash
env GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -tags lambda.norpc -ldflags="-s -w" -o ./terraform/02/external/bootstrap ./cmd/main.go
```

```bash
chmod +x ./terraform/02/external/bootstrap
```

```bash
zip -j ./terraform/02/external/bootstrap.zip ./terraform/02/external/bootstrap
```

```bash
aws-vault exec dev -- terraform -chdir=./terraform/02 init
```

```bash
aws-vault exec dev -- terraform -chdir=./terraform/02 apply --auto-approve
```
