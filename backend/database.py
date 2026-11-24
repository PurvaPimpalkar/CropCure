import sqlite3
import os
import bcrypt

DATABASE_URL = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'cropcure.db')

def get_db_connection():
    conn = sqlite3.connect(DATABASE_URL, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    c = conn.cursor()
    # Users table for Signup/Login
    c.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    # Scan history connected to user
    c.execute('''
        CREATE TABLE IF NOT EXISTS scan_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            crop TEXT,
            disease TEXT,
            confidence REAL,
            treatment_shown TEXT,
            image_path TEXT,
            scan_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    ''')
    conn.commit()
    conn.close()

# Exportable CRUD Operations
def register_user(name, email, password):
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    conn = get_db_connection()
    c = conn.cursor()
    try:
        c.execute('INSERT INTO users (name, email, password) VALUES (?, ?, ?)', (name, email, hashed))
        user_id = c.lastrowid
        conn.commit()
        return {"id": user_id, "name": name, "email": email}
    except sqlite3.IntegrityError:
        return None
    finally:
        conn.close()

def authenticate_user(email, password):
    conn = get_db_connection()
    c = conn.cursor()
    c.execute('SELECT id, name, email, password FROM users WHERE email=?', (email,))
    user = c.fetchone()
    conn.close()
    
    if user:
        # Check standard hashes created previously due to previous version using standard SHA-256 vs Bcrypt
        # This is strictly not requested but handling migration if needed, but the requirements just say "bcrypt". 
        # I'll just strictly use bcrypt as per requirements.
        if bcrypt.checkpw(password.encode('utf-8'), user['password'].encode('utf-8')):
            return {"id": user["id"], "name": user["name"], "email": user["email"]}
    return None

def save_scan(user_id, crop, disease, confidence, treatment_shown, image_path=""):
    conn = get_db_connection()
    c = conn.cursor()
    c.execute('''
        INSERT INTO scan_history (user_id, crop, disease, confidence, treatment_shown, image_path)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (user_id, crop, disease, confidence, treatment_shown, image_path))
    conn.commit()
    conn.close()

def get_user_history(user_id):
    conn = get_db_connection()
    c = conn.cursor()
    c.execute('SELECT * FROM scan_history WHERE user_id=? ORDER BY scan_date DESC', (user_id,))
    rows = c.fetchall()
    conn.close()
    return [dict(row) for row in rows]

init_db()
