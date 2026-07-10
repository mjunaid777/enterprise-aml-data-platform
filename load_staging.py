import psycopg2
import time
import os

# Database Connection Configurations

DB_CONFIG = {
    "dbname": "enterprise_aml_db",
    "user": "postgres",
    "password": "your password",  
    "host": "localhost",
    "port": "5432"
}

CLEAN_DATA_PATH = '../data_raw/validated_transactions.csv'
TABLE_NAME = 'staging_transactions'

def load_csv_to_staging():
    print(f"Initializing bulk load into database table: {TABLE_NAME}...")
    start_time = time.time()

    # 1. Checking if the clean file exists before connecting
    if not os.path.exists(CLEAN_DATA_PATH):
        print(f"Error: Clean data file not found at {CLEAN_DATA_PATH}")
        return

    try:
        # 2. Establishing connection to PostgreSQL
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print("Successfully connected to PostgreSQL database.")

        # 3. Opening the CSV file and execute high-speed COPY
        # i have used copy_expert because it gives us precise control over headers and formatting
        copy_sql = f"""
            COPY {TABLE_NAME} 
            FROM STDIN 
            WITH CSV HEADER;
        """
        
        print("Streaming data to database... Please wait.")
        with open(CLEAN_DATA_PATH, 'r', encoding='utf-8') as f:
            cursor.copy_expert(sql=copy_sql, file=f)
        
        # 4. Committing the transaction to save changes permanently
        conn.commit()
        end_time = time.time()
        elapsed_time = end_time - start_time
        print(f"Bulk data transfer complete in {elapsed_time:.2f} seconds.")

        # 5. Verification step: Running thid Query for table to count rows
        cursor.execute(f"SELECT COUNT(*) FROM {TABLE_NAME};")
        db_row_count = cursor.fetchone()[0]
        print(f"Verification Successful: {db_row_count} rows currently reside in '{TABLE_NAME}'.")

    except Exception as e:
        print(f"Pipeline Failure during Database Load Phase: {e}")
        if 'conn' in locals():
            conn.rollback()
            print("Transaction rolled back safely.")
            
    finally:
        # 6. closeing network connections to prevent leaks
        if 'cursor' in locals():
            cursor.close()
        if 'conn' in locals():
            conn.close()
        print("Database connection closed cleanly.")

if __name__ == "__main__":
    load_csv_to_staging()