"""
CropCure – Blog Module API Router
Provides REST endpoints for the Farmer Community Blog feature.

Endpoints:
    POST /blogs/create        → Create a new blog post (multipart/form-data)
    GET  /blogs/all           → Get all blogs (with optional crop filter + pagination)
    GET  /blogs/search        → Search blogs by crop name
    GET  /blogs/{id}          → Get single blog details
    POST /blogs/rate          → Rate a blog (1–5 stars)
    GET  /blogs/{id}/my-rating → Get current user's rating for a blog
    POST /blogs/comment       → Add comment to a blog
    GET  /blogs/{id}/comments → Get all comments for a blog
    GET  /media/blog_images/{filename} → Serve blog images
    GET  /media/blog_videos/{filename} → Serve blog videos
"""

import os
import uuid
import logging
from typing import Optional, List

from fastapi import APIRouter, File, UploadFile, Form, HTTPException, Query
from fastapi.responses import FileResponse
from pydantic import BaseModel

import blog_database as bdb

logger = logging.getLogger(__name__)

# ── Translation helper ────────────────────────────────────────────────────────
# Maps Flutter appLanguage codes to deep-translator language codes.
_LANG_MAP = {'en': 'en', 'hi': 'hi', 'mr': 'mr'}

# Fields that hold content we want to translate.
_TRANSLATABLE = ('title', 'crop_name', 'description')
# Note: farmer_name is a proper noun — never translated.

def _translate_blog(blog: dict, target_lang: str) -> dict:
    """
    Translate blog text fields to target_lang using Google Translate (via
    deep-translator). Returns the original dict unchanged on any error or
    when target_lang is 'en'.
    """
    dest = _LANG_MAP.get(target_lang, 'en')
    if dest == 'en':
        return blog
    try:
        from deep_translator import GoogleTranslator
        translated = dict(blog)
        for field in _TRANSLATABLE:
            value = translated.get(field, '')
            if value:
                try:
                    translated[field] = GoogleTranslator(
                        source='auto', target=dest
                    ).translate(value)
                except Exception as te:
                    logger.warning(f"Translation failed for field '{field}': {te}")
        return translated
    except ImportError:
        logger.warning("deep-translator not installed; serving original content.")
        return blog
    except Exception as e:
        logger.warning(f"Translation error: {e}")
        return blog


def _translate_blogs(blogs: list, target_lang: str) -> list:
    """Batch translate a list of blog dicts."""
    if _LANG_MAP.get(target_lang, 'en') == 'en':
        return blogs
    return [_translate_blog(b, target_lang) for b in blogs]

router = APIRouter(prefix="/blogs", tags=["Community Blog"])

ALLOWED_IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png'}
ALLOWED_VIDEO_EXTENSIONS = {'.mp4'}
MAX_IMAGE_SIZE = 10 * 1024 * 1024   # 10 MB
MAX_VIDEO_SIZE = 100 * 1024 * 1024  # 100 MB


# ── Pydantic Models ──────────────────────────────────────────────────────────

class RatingRequest(BaseModel):
    blog_id: int
    user_identifier: str  # farmer name or device-unique ID
    rating: int           # 1–5


class CommentRequest(BaseModel):
    blog_id: int
    farmer_name: str
    comment: str


# ── Helpers ──────────────────────────────────────────────────────────────────

def _save_file(upload: UploadFile, dest_dir: str, allowed_exts: set,
               max_size: int, kind: str) -> str:
    """Validate, save, and return the stored filename."""
    ext = os.path.splitext(upload.filename or '')[1].lower()
    if ext not in allowed_exts:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid {kind} format '{ext}'. Allowed: {allowed_exts}"
        )
    content = upload.file.read()
    if len(content) > max_size:
        raise HTTPException(
            status_code=413,
            detail=f"{kind.capitalize()} too large. Max size: {max_size // (1024*1024)}MB"
        )
    filename = f"{uuid.uuid4().hex}{ext}"
    path = os.path.join(dest_dir, filename)
    with open(path, 'wb') as f:
        f.write(content)
    return filename


def _sanitize_text(text: str, max_len: int = 5000) -> str:
    """Basic text sanitization."""
    return text.strip()[:max_len]


# ── Endpoints ────────────────────────────────────────────────────────────────

@router.post("/create")
async def create_blog(
    title: str = Form(..., max_length=200),
    crop_name: str = Form(..., max_length=100),
    description: str = Form(..., max_length=5000),
    farmer_name: str = Form(..., max_length=100),
    images: Optional[List[UploadFile]] = File(default=None),
    video: Optional[UploadFile] = File(default=None),
):
    """
    Create a new farmer blog post.
    Accepts multipart/form-data with text fields + optional image/video uploads.
    """
    # Sanitize text
    title = _sanitize_text(title, 200)
    crop_name = _sanitize_text(crop_name, 100)
    description = _sanitize_text(description, 5000)
    farmer_name = _sanitize_text(farmer_name, 100)

    # Save images
    saved_images: List[str] = []
    if images:
        for img_file in images:
            if img_file and img_file.filename:
                fname = _save_file(
                    img_file, bdb.BLOG_IMAGES_DIR,
                    ALLOWED_IMAGE_EXTENSIONS, MAX_IMAGE_SIZE, 'image'
                )
                saved_images.append(fname)

    # Save video
    saved_video = ''
    if video and video.filename:
        saved_video = _save_file(
            video, bdb.BLOG_VIDEOS_DIR,
            ALLOWED_VIDEO_EXTENSIONS, MAX_VIDEO_SIZE, 'video'
        )

    blog = bdb.create_blog(title, crop_name, description, farmer_name,
                           saved_images, saved_video)
    return {"message": "Blog created successfully", "blog": blog}


@router.get("/all")
async def get_all_blogs(
    crop: Optional[str] = Query(default=None, description="Filter by crop name"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    lang: str = Query(default='en', description="Language code: en | hi | mr"),
):
    """
    Retrieve all blogs ordered by rating (highest first).
    Optionally filter by crop name. Pass lang=hi for Hindi, lang=mr for Marathi.
    """
    blogs = bdb.get_all_blogs(search_crop=crop, page=page, page_size=page_size)
    blogs = _translate_blogs(blogs, lang)
    return {"total": len(blogs), "blogs": blogs}


@router.get("/search")
async def search_blogs(
    crop: str = Query(..., description="Crop name to search for"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    lang: str = Query(default='en', description="Language code: en | hi | mr"),
):
    """Search blogs by crop name. Results ordered by rating."""
    blogs = bdb.get_all_blogs(search_crop=crop, page=page, page_size=page_size)
    blogs = _translate_blogs(blogs, lang)
    return {"query": crop, "total": len(blogs), "blogs": blogs}


@router.get("/{blog_id}")
async def get_blog_detail(
    blog_id: int,
    lang: str = Query(default='en', description="Language code: en | hi | mr"),
):
    """Get full details for a single blog post, translated to lang."""
    blog = bdb.get_blog_by_id(blog_id)
    if not blog:
        raise HTTPException(status_code=404, detail="Blog not found.")
    return _translate_blog(blog, lang)


@router.post("/rate")
async def rate_blog(req: RatingRequest):
    """
    Rate a blog. One rating per user_identifier per blog.
    Automatically recalculates average_rating.
    """
    if not 1 <= req.rating <= 5:
        raise HTTPException(status_code=400, detail="Rating must be between 1 and 5.")
    if not bdb.get_blog_by_id(req.blog_id):
        raise HTTPException(status_code=404, detail="Blog not found.")

    updated_blog = bdb.rate_blog(req.blog_id, req.user_identifier.strip(), req.rating)
    return {
        "message": "Rating submitted successfully",
        "average_rating": updated_blog['average_rating'],
        "rating_count": updated_blog['rating_count'],
    }


@router.get("/{blog_id}/my-rating")
async def get_my_rating(blog_id: int, user_identifier: str = Query(...)):
    """Get the current user's rating for a specific blog (0 if not rated)."""
    rating = bdb.get_user_rating(blog_id, user_identifier)
    return {"blog_id": blog_id, "rating": rating or 0}


@router.post("/comment")
async def add_comment(req: CommentRequest):
    """Add a comment to a blog post."""
    if not bdb.get_blog_by_id(req.blog_id):
        raise HTTPException(status_code=404, detail="Blog not found.")
    farmer_name = _sanitize_text(req.farmer_name, 100)
    comment_text = _sanitize_text(req.comment, 1000)
    if not comment_text:
        raise HTTPException(status_code=400, detail="Comment cannot be empty.")
    result = bdb.add_comment(req.blog_id, farmer_name, comment_text)
    return {"message": "Comment added successfully", "comment": result}


@router.get("/{blog_id}/comments")
async def get_comments(blog_id: int):
    """Get all comments for a blog post."""
    if not bdb.get_blog_by_id(blog_id):
        raise HTTPException(status_code=404, detail="Blog not found.")
    comments = bdb.get_comments(blog_id)
    return {"total": len(comments), "comments": comments}


# ── Media serving router (separate prefix) ───────────────────────────────────
media_router = APIRouter(prefix="/media", tags=["Media"])


@media_router.get("/blog_images/{filename}")
async def serve_blog_image(filename: str):
    path = os.path.join(bdb.BLOG_IMAGES_DIR, filename)
    if not os.path.exists(path):
        raise HTTPException(status_code=404, detail="Image not found.")
    return FileResponse(path)


@media_router.get("/blog_videos/{filename}")
async def serve_blog_video(filename: str):
    path = os.path.join(bdb.BLOG_VIDEOS_DIR, filename)
    if not os.path.exists(path):
        raise HTTPException(status_code=404, detail="Video not found.")
    return FileResponse(path)
