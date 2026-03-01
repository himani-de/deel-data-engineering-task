# Use official Python slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app
COPY ./app .

# Expose port for FastAPI
EXPOSE 3000

# Run the app
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3000", "--reload"]