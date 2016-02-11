FROM google/dart

EXPOSE 8080

ADD . /app

WORKDIR /app
RUN pub get
RUN pub get --offline
RUN pub build example

CMD ["pub", "serve", "example", "--port=8080", "--hostname=0.0.0.0"]
