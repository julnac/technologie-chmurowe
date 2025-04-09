
ARG PYTHON_VERSION=latest
FROM python:$PYTHON_VERSION

WORKDIR /usr/src/app
COPY myapp/ .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]

# docker build --build-arg PYTHON_VERSION=3.11 -t my-python-app .
# docker run -d my-python-app