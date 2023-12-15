FROM golang:1.20-alpine AS build-sk

# Set the current Working Directory inside the container
WORKDIR /app

RUN apk update && apk add --no-cache gcc git
RUN apk add musl-dev

# Copy go mod and sum files
COPY go.mod go.sum ./

ARG GO_DEPS_GITHUB_TOKEN
RUN git config --global url."https://${GO_DEPS_GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "https://github.com/"

ENV GOPRIVATE github.com/patiyan-sukkasem
# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN go mod download && go mod verify

# Copy the source from the current directory to the Working Directory inside the container
COPY . .

ARG VERSION
ARG APP_PACKAGE=github.com/patiyan-sukkasem/goapp/cmd/main
RUN go build -o main cmd/main.go

FROM alpine:3.16

ARG user=swadm  
ENV HOME /home/$USER

RUN apk update && apk --no-cache add tzdata

WORKDIR /app

RUN adduser -D $user -u 1000
RUN chown -R $user:$user $HOME
RUN chown -R $user:$user /app
USER $user

COPY --from=build-sk /app/main /app/main
COPY --from=build-dev /app/etc /app/etc


EXPOSE 8080

CMD ["./main"]
