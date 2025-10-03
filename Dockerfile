FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
ENV PORT=8080
CMD ["sh", "-c", "gunicorn -b 0.0.0.0:${PORT:-8080} -w 1 -k gevent -t 0 app:app"]
