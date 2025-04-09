ARG PYTHON_VERSION=latest
FROM python:$PYTHON_VERSION-alpine
WORKDIR /usr/src/app
ARG SERVER_PORT=3000
ENV PYTHON_VERSION=$PYTHON_VERSION
ENV APP_PORT=$SERVER_PORT
COPY myapp/ .
RUN pip install -r requirements.txt
VOLUME /usr/src/app/data
EXPOSE $APP_PORT
CMD ["python", "app.py"]

# docker build --build-arg PYTHON_VERSION=3.11 --build-arg APP_PORT=8080 -t my-alpine-app .
# docker run -d -p 8080:8080 -v myapp_data:/usr/src/app/data my-alpine-app