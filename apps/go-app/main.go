package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var dbPool *pgxpool.Pool

func main() {
	host := getEnv("DB_HOST", "localhost")
	user := getEnv("DB_USER", "postgres")
	password := getEnv("DB_PASSWORD", "password")
	dbName := getEnv("DB_NAME", "postgres")

	connString := fmt.Sprintf("postgres://%s:%s@%s/%s", user, password, host, dbName)

	var err error
	dbPool, err = pgxpool.New(context.Background(), connString)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer dbPool.Close()

	r := gin.Default()

	r.GET("/metrics", gin.WrapH(promhttp.Handler()))

	r.GET("/compute", compute)
	r.GET("/records/:id", getRecord)
	r.POST("/records", createRecord)

	r.GET("/health", healthCheck)
	r.POST("/reset", resetDatabase)
	r.POST("/teardown", teardown)

	log.Println("Listening on :8080")
	r.Run(":8080")
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
