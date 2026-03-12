FROM alpine:3.19

RUN apk add --no-cache python3 py3-pip
ENV PYTHONUNBUFFERED=1

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --break-system-packages -r requirements.txt
COPY . .

ENV FLASK_APP=app.py
EXPOSE 3000
CMD ["flask", "run", "--host=0.0.0.0", "--port=3000"]
