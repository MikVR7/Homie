# --- Stage 1: The "Builder" ---
# We start with a full Python image to install dependencies
FROM python:3.12-slim as builder

# Set the working directory inside the container
WORKDIR /app

# Install uv for fast package management
RUN pip install uv

# Copy only the requirements file first to leverage Docker's caching
COPY requirements.txt .

# Install dependencies into a virtual environment
RUN uv venv && \
    uv pip install --no-cache-dir -r requirements.txt

# --- Stage 2: The "Final" Image ---
# Start from a clean, minimal Python image
FROM python:3.12-slim

WORKDIR /app

# Copy the virtual environment with all its packages from the "builder" stage
COPY --from=builder /app/.venv ./.venv

# Set the PATH to use the virtual environment's executables
ENV PATH="/app/.venv/bin:$PATH"

# Copy your application code into the final image
COPY . .

# Expose the port your backend runs on (e.g., 8000 for FastAPI/Uvicorn)
EXPOSE 8000

# The command that will be run when the container starts
# IMPORTANT: Adjust this to match how you start your backend server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
