FROM google/dart

EXPOSE 8080

WORKDIR /app

ADD ./pubspec.yaml /tmp/pubspec.yaml
ADD ./example/pubspec-dev-dependencies.yaml /tmp/pubspec-dev-dependencies.yaml
RUN cat /tmp/pubspec.yaml /tmp/pubspec-dev-dependencies.yaml > /app/pubspec.yaml
RUN pub get

ADD ./lib /app/lib
ADD ./example /app/example
RUN pub get --offline

RUN dartanalyzer --strong lib/jsonp.dart

RUN pub build example

CMD ["pub", "serve", "example", "--port=8080", "--hostname=0.0.0.0"]
