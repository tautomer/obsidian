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

# Install obsidian
RUN poetry config virtualenvs.create false && \
    poetry install --extras "app" --no-interaction --no-ansi

RUN poetry add jupyterlab

# Expose dash port
EXPOSE 8050
# Expose jupyter port
EXPOSE 8888

# In case the server is running on a different host
RUN sed -i 's/run_server(/run_server(host="0.0.0.0", /g' app.py

# Run the web server
CMD ["python", "app.py"]

