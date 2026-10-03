FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY . .

RUN chmod +x gradlew
RUN ./gradlew build -x test

EXPOSE 9000

CMD ["java", "-jar", "build/libs/server-0.0.1-SNAPSHOT.jar"]