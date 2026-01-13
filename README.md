# asterisk-tiny

# Update .env file

# build Asterisk image
docker build -t local/asterisk:22 . --no-cache

## Run docker-compose
docker compose up -d