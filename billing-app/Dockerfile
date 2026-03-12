FROM alpine:3.19

RUN apk add --no-cache python3 py3-pip
ENV PYTHONUNBUFFERED=1

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --break-system-packages -r requirements.txt
COPY . .

EXPOSE 8080
CMD ["python", "worker.py"]
