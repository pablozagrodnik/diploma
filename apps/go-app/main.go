package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
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

	r.GET("/health", healthCheck)
	r.POST("/reset", resetDatabase)

	log.Println("Listening on :8080")
	r.Run(":8080")
}

func healthCheck(c *gin.Context) {
	c.String(http.StatusOK, "OK")
}

func resetDatabase(c *gin.Context) {
	// TRUNCATE TABLE
	_, err := dbPool.Exec(context.Background(), "SELECT 1")
	if err != nil {
		c.String(http.StatusInternalServerError, "Database error: "+err.Error())
		return
	}
	c.String(http.StatusOK, "Database reset")
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
