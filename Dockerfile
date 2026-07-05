FROM python:alpine

WORKDIR /app
COPY pyproject.toml README.md LICENSE ./
COPY src ./src
RUN pip install --no-cache-dir '.[web]'

RUN adduser -D -s /sbin/nologin juanita
USER juanita

EXPOSE 8000
CMD ["juanita-web"]
