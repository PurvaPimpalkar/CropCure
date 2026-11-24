"""
CropCure – Blog Module Database Layer
Manages blogs, ratings, and comments tables.
Uses the same SQLite database as the main app.
"""

import sqlite3
import os
import json
from typing import Optional, List

DATABASE_URL = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'cropcure.db')

MEDIA_BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'media')
BLOG_IMAGES_DIR = os.path.join(MEDIA_BASE, 'blog_images')
BLOG_VIDEOS_DIR = os.path.join(MEDIA_BASE, 'blog_videos')

# Ensure media directories exist
os.makedirs(BLOG_IMAGES_DIR, exist_ok=True)
os.makedirs(BLOG_VIDEOS_DIR, exist_ok=True)


def get_db_connection():
    conn = sqlite3.connect(DATABASE_URL, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_blog_db():
    """Create blog-related tables if they don't already exist."""
    conn = get_db_connection()
    c = conn.cursor()

    # Blogs table
    c.execute('''
        CREATE TABLE IF NOT EXISTS blogs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            crop_name TEXT NOT NULL,
            description TEXT NOT NULL,
            farmer_name TEXT NOT NULL,
            image_paths TEXT DEFAULT '[]',
            video_path TEXT DEFAULT '',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            average_rating REAL DEFAULT 0.0,
            rating_count INTEGER DEFAULT 0
        )
    ''')

    # Ratings table (one rating per user per blog)
    c.execute('''
        CREATE TABLE IF NOT EXISTS blog_ratings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            blog_id INTEGER NOT NULL,
            user_identifier TEXT NOT NULL,
            rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(blog_id, user_identifier),
            FOREIGN KEY (blog_id) REFERENCES blogs(id) ON DELETE CASCADE
        )
    ''')

    # Comments table
    c.execute('''
        CREATE TABLE IF NOT EXISTS blog_comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            blog_id INTEGER NOT NULL,
            farmer_name TEXT NOT NULL,
            comment TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (blog_id) REFERENCES blogs(id) ON DELETE CASCADE
        )
    ''')

    conn.commit()
    conn.close()


# ── Blog CRUD ────────────────────────────────────────────────────────────────

def create_blog(title: str, crop_name: str, description: str,
                farmer_name: str, image_paths: list, video_path: str) -> dict:
    conn = get_db_connection()
    c = conn.cursor()
    c.execute(
        '''INSERT INTO blogs (title, crop_name, description, farmer_name, image_paths, video_path)
           VALUES (?, ?, ?, ?, ?, ?)''',
        (title, crop_name.strip(), description, farmer_name,
         json.dumps(image_paths), video_path)
    )
    blog_id = c.lastrowid
    conn.commit()
    conn.close()
    return get_blog_by_id(blog_id)


def get_all_blogs(search_crop: Optional[str] = None,
                  page: int = 1, page_size: int = 20) -> List[dict]:
    conn = get_db_connection()
    c = conn.cursor()
    offset = (page - 1) * page_size
    if search_crop:
        c.execute(
            '''SELECT * FROM blogs
               WHERE LOWER(crop_name) LIKE ?
               ORDER BY average_rating DESC, rating_count DESC, created_at DESC
               LIMIT ? OFFSET ?''',
            (f'%{search_crop.lower()}%', page_size, offset)
        )
    else:
        c.execute(
            '''SELECT * FROM blogs
               ORDER BY average_rating DESC, rating_count DESC, created_at DESC
               LIMIT ? OFFSET ?''',
            (page_size, offset)
        )
    rows = c.fetchall()
    conn.close()
    return [_blog_to_dict(row) for row in rows]


def get_blog_by_id(blog_id: int) -> Optional[dict]:
    conn = get_db_connection()
    c = conn.cursor()
    c.execute('SELECT * FROM blogs WHERE id = ?', (blog_id,))
    row = c.fetchone()
    conn.close()
    return _blog_to_dict(row) if row else None


def _blog_to_dict(row) -> dict:
    d = dict(row)
    # Deserialize JSON image_paths
    try:
        d['image_paths'] = json.loads(d.get('image_paths', '[]') or '[]')
    except Exception:
        d['image_paths'] = []
    return d


# ── Ratings ──────────────────────────────────────────────────────────────────

def rate_blog(blog_id: int, user_identifier: str, rating: int) -> dict:
    """
    Insert or update a rating for a blog.
    Returns updated blog dict with new average_rating.
    """
    conn = get_db_connection()
    c = conn.cursor()

    # Upsert rating
    c.execute(
        '''INSERT INTO blog_ratings (blog_id, user_identifier, rating)
           VALUES (?, ?, ?)
           ON CONFLICT(blog_id, user_identifier)
           DO UPDATE SET rating = excluded.rating''',
        (blog_id, user_identifier, rating)
    )

    # Recalculate average
    c.execute(
        'SELECT AVG(rating) as avg_r, COUNT(*) as cnt FROM blog_ratings WHERE blog_id = ?',
        (blog_id,)
    )
    agg = c.fetchone()
    avg_r = round(agg['avg_r'] or 0, 2)
    cnt = agg['cnt'] or 0

    c.execute(
        'UPDATE blogs SET average_rating = ?, rating_count = ? WHERE id = ?',
        (avg_r, cnt, blog_id)
    )
    conn.commit()
    conn.close()
    return get_blog_by_id(blog_id)


def get_user_rating(blog_id: int, user_identifier: str) -> Optional[int]:
    conn = get_db_connection()
    c = conn.cursor()
    c.execute(
        'SELECT rating FROM blog_ratings WHERE blog_id = ? AND user_identifier = ?',
        (blog_id, user_identifier)
    )
    row = c.fetchone()
    conn.close()
    return row['rating'] if row else None


# ── Comments ─────────────────────────────────────────────────────────────────

def add_comment(blog_id: int, farmer_name: str, comment: str) -> dict:
    conn = get_db_connection()
    c = conn.cursor()
    c.execute(
        'INSERT INTO blog_comments (blog_id, farmer_name, comment) VALUES (?, ?, ?)',
        (blog_id, farmer_name, comment.strip())
    )
    comment_id = c.lastrowid
    conn.commit()
    c.execute('SELECT * FROM blog_comments WHERE id = ?', (comment_id,))
    row = c.fetchone()
    conn.close()
    return dict(row)


def get_comments(blog_id: int) -> List[dict]:
    conn = get_db_connection()
    c = conn.cursor()
    c.execute(
        'SELECT * FROM blog_comments WHERE blog_id = ? ORDER BY created_at DESC',
        (blog_id,)
    )
    rows = c.fetchall()
    conn.close()
    return [dict(r) for r in rows]


# Initialise tables on import
init_blog_db()
