FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app
COPY static ./static
COPY config ./config

# OpenShift runs containers with a random UID in group 0 by default -
# make sure that UID can read everything it needs.
RUN chgrp -R 0 /app && chmod -R g=u /app

ENV CONFIG_PATH=/app/config/support.yaml
EXPOSE 8080

USER 1001

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
