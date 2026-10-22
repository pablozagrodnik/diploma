package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var dbPool *pgxpool.Pool

func main() {
	host := getEnv("DB_HOST", "localhost")
	user := getEnv("DB_USER", "postgres")
	password := getEnv("DB_PASSWORD", "password")
	dbName := getEnv("DB_NAME", "postgres")

	connString := fmt.Sprintf("postgres://%s:%s@%s/%s?pool_max_conns=50&pool_min_conns=10", user, password, host, dbName)

	var err error
	dbPool, err = pgxpool.New(context.Background(), connString)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer dbPool.Close()

	initDatabaseSchema(context.Background(), dbPool)

	prometheus.MustRegister(prometheus.NewGaugeFunc(
		prometheus.GaugeOpts{
			Name: "pgxpool_acquired_conns",
			Help: "Number of currently acquired conns in the pool",
		},
		func() float64 {
			return float64(dbPool.Stat().AcquiredConns())
		}))

	prometheus.MustRegister(prometheus.NewCounterFunc(
		prometheus.CounterOpts{
			Name: "pgxpool_empty_acquire_count",
			Help: "Number of acquires waiting for connection",
		},
		func() float64 {
			return float64(dbPool.Stat().EmptyAcquireCount())
		}))
	
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())

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

func initDatabaseSchema(ctx context.Context, db *pgxpool.Pool) {
	schemaQuery := `
	CREATE TABLE IF NOT EXISTS data_a (
		id SERIAL PRIMARY KEY,
		name VARCHAR(255) NOT NULL,
		value INTEGER NOT NULL
	);

	CREATE TABLE IF NOT EXISTS data_b (
		id SERIAL PRIMARY KEY,
		data_a_id INTEGER NOT NULL REFERENCES data_a(id) ON DELETE CASCADE,
		title VARCHAR(50) NOT NULL,
		description VARCHAR(255) NOT NULL
	);

	CREATE INDEX IF NOT EXISTS idx_data_b_a_id ON data_b(data_a_id);
	`
	_, err := db.Exec(ctx, schemaQuery)
	if err != nil {
		log.Fatalf("Unable to initialize schema: %v\n", err)
	}
	log.Println("Database schema initialized")
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
