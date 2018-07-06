# arm6-golang
docker build -t minio-arm . -f Dockerfile.rpi
docker run -p 9000:9000 --restart=always -d \
  --name minio1 \
  -v /minio/data:/data \
  -v /minio/config:/root/.minio \
  minio-arm:latest server /data