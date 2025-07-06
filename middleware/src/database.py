import duckdb
import asyncio
from threading import Lock
from datetime import datetime

db_lock = Lock()
DB_PATH = "tokens_data.duckdb"

def init_db():
    with duckdb.connect(DB_PATH) as conn:

        conn.execute("""
        CREATE TABLE IF NOT EXISTS projects (
            project_id TEXT PRIMARY KEY
        )
        """)

        conn.execute("""
        CREATE SEQUENCE IF NOT EXISTS seq_access_logs_id START 1;
        """)

        conn.execute("""
        CREATE TABLE IF NOT EXISTS access_logs (
            access_logs_id INTEGER PRIMARY KEY DEFAULT nextval('seq_access_logs_id'),
            project_id TEXT,
            project_source TEXT,
            tokens_in INTEGER,
            tokens_out INTEGER,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (project_id) REFERENCES projects(project_id)
        )
        """)
        
        conn.execute("""
        CREATE OR REPLACE VIEW recent_erro_log_view AS
        SELECT
            erro_id,
            project_id,
            inference_log,
            middleware_log,
            timestamp
        FROM erro_log
        ORDER BY timestamp DESC
        """)
        
        conn.execute("CREATE SEQUENCE IF NOT EXISTS seq_erro_log_id START 1;")

        conn.execute("""
        CREATE TABLE IF NOT EXISTS erro_log (
            erro_id INTEGER PRIMARY KEY DEFAULT nextval('seq_erro_log_id'),
            project_id TEXT,
            inference_log TEXT,
            middleware_log TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (project_id) REFERENCES projects(project_id)
        )
        """)

def insert_usage(project_id: str, project_source:str, tokens_in:int, tokens_out:int):
    with db_lock:
        with duckdb.connect(DB_PATH) as conn:
            conn.execute("""
            INSERT INTO access_logs (project_id, project_source, tokens_in, tokens_out)
            VALUES (?, ?, ?, ?)
            """, (project_id, project_source, tokens_in, tokens_out))

def query_usage_month(project_id: str | None, year: int, month: int):
    month_start = datetime(year, month, 1, 0, 0, 0, 0)
    with db_lock:
        with duckdb.connect(DB_PATH) as conn:
            query = """
            SELECT project_id, tokens_usage, last_update
            FROM tokens_usage_view
            WHERE month = ?
            """
            params:list[str|datetime] = [month_start]
            if project_id:
                query += " AND project_id = ?"
                params.append(project_id)
            result = conn.execute(query, params).fetchall()
    return result

def get_last_error_logs(n: int, project_id: str | None = None):
    with db_lock:
        with duckdb.connect(DB_PATH) as conn:
            query = """
            SELECT erro_id, project_id, inference_log, middleware_log, timestamp
            FROM recent_erro_log_view
            """
            params = []

            if project_id is not None:
                query += " WHERE project_id = ?"

            query += " ORDER BY timestamp DESC LIMIT ?"

            params.append(n)
            if project_id is not None:
                params.insert(0, project_id)

            result = conn.execute(query, params).fetchall()
    return result


async def async_insert_usage(project_id: str, project_source:str, tokens_in:int, tokens_out:int):
    await asyncio.to_thread(async_insert_usage,project_id, project_source, tokens_in, tokens_out)

async def async_get_last_error_logs(n: int, project_id: str | None = None):
    await asyncio.to_thread(get_last_error_logs, n, project_id )

async def async_query_usage_month(project_id: str | None, year: int, month: int):
    return await asyncio.to_thread(query_usage_month, project_id, year, month)