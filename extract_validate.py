import pandas as pd
import os

# file path
RAW_DATA_PATH = '../data_raw/HI-Small_Trans.csv' # Adjust filename if you downloaded the 'HI' version
CLEAN_DATA_PATH = '../data_raw/validated_transactions.csv'
CHUNK_SIZE = 100000

def clean_column_names(df):
    """
    Standardizes column names for SQL compatibility.
    Example: 'From Bank' becomes 'from_bank'
    """
    df.columns = (df.columns
                  .str.strip()
                  .str.lower()
                  .str.replace(' ', '_')
                  .str.replace('.', '_'))
    
    # Renameing 'account_1' to 'to_account' for clarity
    if 'account_1' in df.columns:
        df = df.rename(columns={'account_1': 'to_account', 'account': 'from_account'})
    
    return df

def validate_chunk(df):
    """
    Applies business rules and data quality checks.
    """
    initial_len = len(df)
    
    # 1. Droping the rows with missing critical identifiers
    df = df.dropna(subset=['from_account', 'to_account', 'from_bank', 'to_bank'])
    
    # 2. Ensureing monetary amounts are not negative
    df = df[(df['amount_paid'] >= 0) & (df['amount_received'] >= 0)]
    
    # 3. Validateing 'is_laundering' is strictly boolean (0 or 1)
    df = df[df['is_laundering'].isin([0, 1])]
    
    dropped_rows = initial_len - len(df)
    return df, dropped_rows

def process_data():
    print("Starting ETL Extraction Phase...")
    
    if not os.path.exists(RAW_DATA_PATH):
        print(f"Error: Could not find data at {RAW_DATA_PATH}")
        return

    total_processed = 0
    total_dropped = 0
    
    # Removeing existing output file if it exists to start fresh
    if os.path.exists(CLEAN_DATA_PATH):
        os.remove(CLEAN_DATA_PATH)

    # Reading the data in chunks
    for i, chunk in enumerate(pd.read_csv(RAW_DATA_PATH, chunksize=CHUNK_SIZE)):
        
        chunk = clean_column_names(chunk)
        valid_chunk, dropped = validate_chunk(chunk)
        
        # Keeping the track of metrics
        total_processed += len(valid_chunk)
        total_dropped += dropped
        
        # adding a new validated CSV
        # If it's the first chunk (i=0), write the header. Otherwise, don't.
        write_header = (i == 0)
        valid_chunk.to_csv(CLEAN_DATA_PATH, mode='a', index=False, header=write_header)
        
        print(f"Processed batch {i+1}... ({total_processed} valid rows saved)")

    print("-" * 30)
    print("EXTRACTION COMPLETE")
    print(f"Total Valid Rows: {total_processed}")
    print(f"Total Dropped Rows: {total_dropped}")
    print(f"Validated data saved to: {CLEAN_DATA_PATH}")

if __name__ == "__main__":
    process_data()