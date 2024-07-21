package main

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"os/signal"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
)

var (
	queueURL string
	region   string
	runOnce  bool
)

func init() {
	queueURL = os.Getenv("HEARTBEAT_QUEUE_URL")
	if queueURL == "" {
		log.Fatal("HEARTBEAT_QUEUE_URL environment variable is required")
	}

	region = os.Getenv("AWS_REGION")
	if region == "" {
		log.Fatal("AWS_REGION environment variable is required")
	}

	runOnceEnv := os.Getenv("HEARTBEAT_RUN_ONCE")
	runOnce = runOnceEnv == "true"
}

type HeartbeatMessage struct {
	Timestamp string `json:"timestamp"`
	Region    string `json:"region"`
}

func sendHeartbeat(client *sqs.Client) {
	heartbeat := HeartbeatMessage{
		Timestamp: time.Now().Format(time.RFC3339),
		Region:    region,
	}

	messageBody, err := json.Marshal(heartbeat)
	if err != nil {
		log.Printf("failed to marshal heartbeat message: %v", err)
		return
	}

	input := &sqs.SendMessageInput{
		QueueUrl:    &queueURL,
		MessageBody: aws.String(string(messageBody)),
	}

	_, err = client.SendMessage(context.TODO(), input)
	if err != nil {
		log.Printf("failed to send heartbeat: %v", err)
	} else {
		log.Println("heartbeat sent successfully")
	}
}

func heartbeatSender(ctx context.Context) {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}

	client := sqs.NewFromConfig(cfg)

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt)

	if runOnce {
		sendHeartbeat(client)
		log.Println("'HEARTBEAT_RUN_ONCE=true' exiting...")
		return
	}

	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	go func() {
		for {
			select {
			case <-ticker.C:
				sendHeartbeat(client)
			case <-stop:
				log.Println("stopping heartbeat sender")
				return
			case <-ctx.Done():
				log.Println("context done, stopping heartbeat sender")
				return
			}
		}
	}()

	log.Println("heartbeat sender started")
	<-stop
	log.Println("exiting...")
}

func main() {
	if os.Getenv("LAMBDA_TASK_ROOT") == "" {
		heartbeatSender(context.TODO())
	} else {
		lambda.Start(func(ctx context.Context) {
			heartbeatSender(ctx)
		})
	}
}
