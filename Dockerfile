FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt update && apt install -y git curl && rm -rf /var/lib/apt/lists/*

# Install poetry
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    ln -s /root/.local/bin/poetry /usr/local/bin/poetry

# Copy the project files
COPY . .

RUN git fetch --tags && \
    git checkout $(git describe --tags $(git rev-list --tags --max-count=1))

# Install CPU-only PyTorch
RUN poetry source add --priority explicit pytorch_cpu https://download.pytorch.org/whl/cpu
RUN sed -i 's/^torch = "2\.3\.0"/torch = { version = "2.3.0", source = "pytorch_cpu" }/' pyproject.toml

# Install obsidian
RUN poetry config virtualenvs.create false && \
    poetry install --extras "app" --no-interaction --no-ansi

RUN poetry add jupyterlab

# Remove install cache to minimize the image size
RUN poetry cache clear . --all --no-interaction && rm -rf /root/.cache /root/.local/share/pip

# Expose dash port
EXPOSE 8050
# Expose jupyter port
EXPOSE 8888

# In case the server is running on a different host
RUN sed -i 's/run_server(/run_server(host="0.0.0.0", /g' app.py

# Run the web server
CMD ["python", "app.py"]

