# Common SQLcl Queries

Quick reference for common database inspection and debugging queries.

## Table Structure

### List all tables
```sql
SELECT table_name FROM user_tables ORDER BY table_name;
```

### Describe table structure
```sql
DESC table_name;
```

### Get column details
```sql
SELECT column_name, data_type, nullable FROM user_tab_columns WHERE table_name='TABLE_NAME' ORDER BY column_id;
```

## Data Inspection

### Count rows in table
```sql
SELECT COUNT(*) FROM table_name;
```

### View sample data
```sql
SELECT * FROM table_name WHERE ROWNUM <= 10;
```

### Check specific records
```sql
SELECT * FROM table_name WHERE id = value;
```

## Constraints and Keys

### Primary keys
```sql
SELECT constraint_name, column_name FROM user_constraints uc JOIN user_cons_columns ucc ON uc.constraint_name = ucc.constraint_name WHERE uc.table_name = 'TABLE_NAME' AND uc.constraint_type = 'P';
```

### Foreign keys
```sql
SELECT constraint_name, column_name FROM user_cons_columns WHERE table_name = 'TABLE_NAME' AND constraint_name IN (SELECT constraint_name FROM user_constraints WHERE table_name = 'TABLE_NAME' AND constraint_type = 'R');
```

### All indexes on table
```sql
SELECT index_name, column_name FROM user_ind_columns WHERE table_name = 'TABLE_NAME';
```

## Sequences

### List all sequences
```sql
SELECT sequence_name, last_number FROM user_sequences;
```

### Current sequence value
```sql
SELECT sequence_name.CURRVAL FROM dual;
```

## Schema Information

### List all tables with row count
```sql
SELECT table_name, num_rows FROM user_tables ORDER BY table_name;
```

### Table creation date
```sql
SELECT object_name, created FROM user_objects WHERE object_type = 'TABLE' ORDER BY created;
```

## Debugging Migrations

### Check pending changes (if versioning table exists)
```sql
SELECT * FROM schema_version ORDER BY installed_rank DESC;
```

### Verify constraint creation
```sql
SELECT constraint_name, constraint_type, status FROM user_constraints WHERE table_name = 'TABLE_NAME';
```

### Check for missing indexes
```sql
SELECT table_name, column_name FROM user_tab_columns WHERE table_name IN (SELECT table_name FROM user_tables) AND column_name LIKE '%ID%' AND column_name NOT IN (SELECT column_name FROM user_ind_columns);
```

