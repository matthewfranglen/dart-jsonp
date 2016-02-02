FROM google/dart

EXPOSE 8080

ADD . /app

WORKDIR /app
RUN pub get
RUN pub get --offline
RUN pub build example

WORKDIR /app/example
RUN pub get
RUN pub get --offline

CMD ["pub", "serve", "web", "--port=8080", "--hostname=0.0.0.0"]
