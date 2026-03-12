FROM alpine:3.19

RUN apk add --no-cache python3 py3-pip

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --break-system-packages -r requirements.txt
COPY . .

ENV FLASK_APP=app.py
EXPOSE 8080
CMD ["sh", "-c", "python -c 'from app import init_db; init_db()' && flask run --host=0.0.0.0 --port=8080"]
