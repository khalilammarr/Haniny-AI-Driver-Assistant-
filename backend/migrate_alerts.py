"""
Migration script to rename 'type' column to 'alert_type' in alerts table.
Run this before restarting the backend server.
"""
from sqlalchemy import create_engine, text
import os

# Path to the database
DB_PATH = "sql_app.db"
DATABASE_URL = f"sqlite:///./{DB_PATH}"

def migrate_database():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found at {DB_PATH}")
        print("ℹ️  The database will be created with the correct schema when the backend starts.")
        return
    
    engine = create_engine(DATABASE_URL)
    
    try:
        with engine.connect() as conn:
            # Check if the 'type' column exists
            result = conn.execute(text("PRAGMA table_info(alerts)"))
            columns = result.fetchall()
            column_names = [col[1] for col in columns]
            
            if 'type' in column_names and 'alert_type' not in column_names:
                print("🔄 Migrating 'type' column to 'alert_type'...")
                
                # SQLite doesn't support column renaming directly, so we need to:
                # 1. Create a new table with the correct schema
                # 2. Copy data from old table
                # 3. Drop old table
                # 4. Rename new table
                
                conn.execute(text("""
                    CREATE TABLE alerts_new (
                        id INTEGER PRIMARY KEY,
                        alert_type VARCHAR,
                        message VARCHAR,
                        severity VARCHAR,
                        timestamp DATETIME,
                        user_id INTEGER,
                        trip_id INTEGER,
                        FOREIGN KEY(user_id) REFERENCES users (id),
                        FOREIGN KEY(trip_id) REFERENCES trips (id)
                    )
                """))
                
                conn.execute(text("""
                    INSERT INTO alerts_new (id, alert_type, message, severity, timestamp, user_id, trip_id)
                    SELECT id, type, message, severity, timestamp, user_id, trip_id
                    FROM alerts
                """))
                
                conn.execute(text("DROP TABLE alerts"))
                conn.execute(text("ALTER TABLE alerts_new RENAME TO alerts"))
                
                # Recreate indexes
                conn.execute(text("CREATE INDEX ix_alerts_id ON alerts (id)"))
                conn.execute(text("CREATE INDEX ix_alerts_alert_type ON alerts (alert_type)"))
                
                conn.commit()
                print("✅ Migration completed successfully!")
                
            elif 'alert_type' in column_names:
                print("✅ Database already has 'alert_type' column. No migration needed.")
            else:
                print("⚠️  Unexpected database schema. Please check manually.")
                
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    print("🔧 Starting database migration...")
    migrate_database()
    print("✨ Done!")

