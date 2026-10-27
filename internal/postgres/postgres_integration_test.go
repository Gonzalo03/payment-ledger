//go:build integration

package postgres

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func TestDatabase(t *testing.T) {
	dbURL := os.Getenv("DATABASE_URL")

	if dbURL == "" {
		t.Skip("DATABASE URL IS NOT SET")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)

	defer cancel()

	pool, err := pgxpool.New(ctx, dbURL)

	if err != nil {
		t.Fatal("ERROR CONNECTING DB", err)
	}

	defer pool.Close()

	t.Run("ping the database", func(t *testing.T) {

		ping := pool.Ping(ctx)

		if ping != nil {
			t.Fatal("ERROR IN PING DB", ping.Error())
		}

	})

	t.Run("accounts table exists", func(t *testing.T) {

		var table *string

		err := pool.QueryRow(ctx, "SELECT to_regclass('accounts')").Scan(&table)

		if err != nil {
			t.Fatalf("ACCOUNTS TABLE NOT EXISTS %v", err)
		}

		if table == nil {
			t.Fatal("WTF THERE IS NO TABLD")
		}

	})

	t.Run("accounts table has rows", func(t *testing.T) {
		var totalRows *int

		err := pool.QueryRow(ctx, "SELECT count(*) FROM accounts").Scan(&totalRows)

		if err != nil {
			t.Fatalf("FAILED TO GET ACCOUNTS TOTAL ROWS %v", err)
		}

		if *totalRows == 0 {
			t.Skip("THERE IS NO DATA IN ACCOUNTS")
		}

	})

}
