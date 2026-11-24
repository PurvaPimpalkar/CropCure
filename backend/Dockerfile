# Use official Python slim image

FROM python:3.10-slim

# Set working directory

WORKDIR /app

# Copy requirements file

COPY requirements.txt .

# Install Python dependencies

RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source code

COPY . .

# Expose port used by FastAPI

EXPOSE 8000

# Start FastAPI server

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
