# Official image; we only add config useful for performance work (Phase 1).
FROM postgres:18-alpine

# Runs once, on first start with an empty data volume.
COPY init/ /docker-entrypoint-initdb.d/

# pg_stat_statements: per-query stats (find slow queries).
# track_io_timing: real I/O timings in EXPLAIN (ANALYZE, BUFFERS).
CMD ["postgres", \
     "-c", "shared_preload_libraries=pg_stat_statements", \
     "-c", "track_io_timing=on"]
