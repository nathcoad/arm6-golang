# arm6-golang
docker build -t minio-arm . -f Dockerfile.rpi
docker run -p 9000:9000 minio-arm:latest server /data