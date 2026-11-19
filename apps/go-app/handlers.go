package main

import (
	"context"
	"fmt"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
)

func healthCheck(c *gin.Context) {
	c.String(http.StatusOK, "OK")
}

func resetDatabase(c *gin.Context) {
	ctx := context.Background()
	// TRUNCATE TABLE
	_, err := dbPool.Exec(ctx, "TRUNCATE TABLE data_a, data_b RESTART IDENTITY CASCADE")
	if err != nil {
		c.String(http.StatusInternalServerError, "Truncate error: "+err.Error())
		return
	}

	// SEEDING data_a TABLE
	batchA := &pgx.Batch{}
	for i := 0; i < 10000; i++ {
		batchA.Queue("INSERT INTO data_a (name, value) VALUES ($1, $2)", fmt.Sprintf("Name %d", i+1), (i+1)*10)
	}

	resA := dbPool.SendBatch(ctx, batchA)
	if err := resA.Close(); err != nil {
		c.String(http.StatusInternalServerError, "BatchA Error: "+err.Error())
		return
	}

	// SEEDING data_b TABLE
	batchB := &pgx.Batch{}
	for i := 0; i < 40000; i++ {
		dataAId := (i / 4) + 1
		batchB.Queue("INSERT INTO data_b (data_a_id, title, description) VALUES ($1, $2, $3)",
			dataAId, fmt.Sprintf("Title %d", i+1), fmt.Sprintf("Description %d", i+1))
	}

	resB := dbPool.SendBatch(ctx, batchB)
	if err := resB.Close(); err != nil {
		c.String(http.StatusInternalServerError, "BatchB Error: "+err.Error())
		return
	}

	c.String(http.StatusOK, "Database reset")
}

func teardown(c *gin.Context) {
	ctx := context.Background()
	_, err := dbPool.Exec(ctx, "DROP OWNED BY postgres CASCADE;")
	if err != nil {
		c.String(http.StatusInternalServerError, "Drop error: "+err.Error())
		return
	}

	c.String(http.StatusOK, "Database clear")
}

// CPU
func compute(c *gin.Context) {
	nStr := c.DefaultQuery("n", "50")
	n, _ := strconv.Atoi(nStr)
	c.JSON(http.StatusOK, fibonacci(n))
}

func fibonacci(n int) int {
	if n <= 1 {
		return n
	}
	return fibonacci(n-1) + fibonacci(n-2)
}

// IO, RAM, ORM
func getRecord(c *gin.Context) {
	id := c.Param("id")
	query := `
		SELECT a.id, a.name, a.value, b.id, b.title, b.description
		FROM data_a a 
		LEFT JOIN data_b b ON a.id = b.data_a_id
		WHERE a.id = $1`

	rows, err := dbPool.Query(context.Background(), query, id)
	if err != nil {
		c.String(http.StatusInternalServerError, err.Error())
		return
	}
	defer rows.Close()

	var parent DataA
	children := make([]DataB, 0)
	hasData := false

	for rows.Next() {
		hasData = true
		var bID *int
		var bTitle, bDesc *string
		err := rows.Scan(&parent.ID, &parent.Name, &parent.Value, &bID, &bTitle, &bDesc)
		if err != nil {
			c.String(http.StatusInternalServerError, err.Error())
			return
		}
		if bID != nil && bTitle != nil && bDesc != nil {
			children = append(children, DataB{
				ID:          *bID,
				Title:       *bTitle,
				Description: *bDesc,
			})
		}
	}

	if !hasData {
		c.Status(http.StatusNotFound)
		return
	}

	parent.DataB = children
	c.JSON(http.StatusOK, parent)
}

// Connection pool, Transaction duration
func createRecord(c *gin.Context) {
	ctx := context.Background()

	tx, err := dbPool.Begin(ctx)
	if err != nil {
		c.String(http.StatusInternalServerError, err.Error())
		return
	}
	defer tx.Rollback(ctx)

	var newID int
	err = tx.QueryRow(ctx, "INSERT INTO data_a (name, value) VALUES ($1, $2) RETURNING id", "POST TEST", 100).Scan(&newID)
	if err != nil {
		c.String(http.StatusInternalServerError, err.Error())
		return
	}

	children := []DataB{
		{Title: "TITLE 1", Description: "DESCRIPTION 1"},
		{Title: "TITLE 2", Description: "DESCRIPTION 2"},
		{Title: "TITLE 3", Description: "DESCRIPTION 3"},
		{Title: "TITLE 4", Description: "DESCRIPTION 4"},
	}

	batch := &pgx.Batch{}
	for _, ch := range children {
		batch.Queue("INSERT INTO data_b (data_a_id, title, description) VALUES ($1, $2, $3) RETURNING id", newID, ch.Title, ch.Description)
	}

	res := tx.SendBatch(ctx, batch)
	for i := range children {
		if err := res.QueryRow().Scan(&children[i].ID); err != nil {
			res.Close()
			c.String(http.StatusInternalServerError, err.Error())
			return
		}
	}
	if err := res.Close(); err != nil {
		c.String(http.StatusInternalServerError, err.Error())
		return
	}

	if err := tx.Commit(ctx); err != nil {
		c.String(http.StatusInternalServerError, err.Error())
		return
	}

	c.JSON(http.StatusOK, DataA{ID: newID, Name: "POST TEST", Value: 100, DataB: children})
}
