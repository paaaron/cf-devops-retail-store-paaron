#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
systemctl enable docker
usermod -a -G docker ec2-user
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Create directory structure
mkdir -p /home/ec2-user/monitoring
mkdir -p /home/ec2-user/monitoring/tools/otel-collector
mkdir -p /home/ec2-user/monitoring/tools/loki
mkdir -p /home/ec2-user/monitoring/tools/prometheus
mkdir -p /home/ec2-user/monitoring/tools/grafana
mkdir -p /home/ec2-user/monitoring/tools/tempo

# Create docker-compose.yml file
cat > /home/ec2-user/monitoring/docker-compose.yml << 'DOCKERCOMPOSE'
version: '3'
services:
  # Colector OpenTelemetry - Recopila métricas y trazas de los servicios
  otel:
    image: otel/opentelemetry-collector-contrib:latest
    command: [--config=/etc/otel-collector-config.yaml]
    volumes:
      - ./tools/otel-collector/otel-collector-config.yaml:/etc/otel-collector-config.yaml
    ports:
      - '13133:13133' # health_check extension
      - '8888:8888' # Prometheus metrics exposed by the collector
      - '8889:8889' # Prometheus exporter metrics
    networks:
      - store
    depends_on:
      - jaeger
      - prometheus
      - loki
  # Loki - Sistema de agregación de logs
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
      - "9095:9095"
      - "7946:7946"
    volumes:
      - ./tools/loki/loki.yaml:/etc/loki/local-config.yaml
      - loki-data:/etc/loki
    command: -config.file=/etc/loki/local-config.yaml
    user: "10001:10001"
    networks:
      - store
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3100/ready || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
  # Jaeger - Sistema de trazabilidad distribuida
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - '4317:4317' # gRPC protocol
      - '9411:9411'
      - '16686:16686' # Jaeger UI
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    networks:
      - store
  # Prometheus - Sistema de monitoreo y alertas
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./tools/prometheus/prometheus.yaml:/etc/prometheus.yaml
      - "./tools/prometheus/rules.yml:/etc/prometheus/rules.yml"
      - prometheus-data:/prometheus
    command:
      - --web.enable-lifecycle
      - --config.file=/etc/prometheus.yaml
      - --enable-feature=otlp-write-receiver
    restart: always
    ports:
      - '9090:9090' # UI
    networks:
      - store
  # Grafana - Plataforma de visualización de métricas y logs
  grafana:
    image: grafana/grafana:latest
    restart: unless-stopped
    ports:
      - '8081:3000'
    depends_on:
      - otel
    volumes:
      - './tools/grafana/grafana.ini:/etc/grafana/grafana.ini'
      - 'grafana-storage:/var/lib/grafana'
      - ./tools/grafana/:/etc/grafana/provisioning/datasources
    networks:
      - store
  # Tempo - Sistema de almacenamiento de trazas distribuidas
  tempo:
    container_name: tempo
    image: grafana/tempo:latest
    command: [ "-config.file=/etc/tempo.yml" ]
    volumes:
      - ./tools/tempo/tempo.yml:/etc/tempo.yml
      - tempo-data:/var/tempo
    restart: always
    ports:
      - "4327:4327"  # otlp grpc 
      - "4328:4328"  # otlp http 
      - "3200:3200"  # tempo
    networks:
      - store
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3200/ready"]
      interval: 10s
      timeout: 5s
      retries: 3
  # Zipkin - Sistema alternativo de trazabilidad distribuida
  zipkin:
    image: openzipkin/zipkin:3.4.2
    container_name: zipkin
    networks:
      - store
    ports:
      - "9412:9411"
  # Node Exporter - Exportador de métricas del sistema
  node-exporter:
    image: prom/node-exporter:v1.8.2
    networks:
      - store
    ports:
      - 9110:9100
  # Alert Manager - Gestor de alertas para Prometheus
  alert-manager:
    image: prom/alertmanager:v0.27.0
    networks:
      - store
    ports:
      - 9093:9093
# Definición de volúmenes persistentes
volumes:
  log-data:
    driver: local
  prometheus-data:
  loki-data:
  grafana-storage:      
  tempo-data:
# Definición de red para los servicios
networks:
  store:
DOCKERCOMPOSE

# Set permissions
chown -R ec2-user:ec2-user /home/ec2-user/monitoring

# Create placeholder config files
mkdir -p /home/ec2-user/monitoring/tools/otel-collector
mkdir -p /home/ec2-user/monitoring/tools/loki
mkdir -p /home/ec2-user/monitoring/tools/prometheus
mkdir -p /home/ec2-user/monitoring/tools/grafana
mkdir -p /home/ec2-user/monitoring/tools/tempo

echo "# Placeholder config - replace with your config" > /home/ec2-user/monitoring/tools/otel-collector/otel-collector-config.yaml
echo "# Placeholder config - replace with your config" > /home/ec2-user/monitoring/tools/loki/loki.yaml
echo "# Placeholder config - replace with your config" > /home/ec2-user/monitoring/tools/prometheus/prometheus.yaml
echo "# Placeholder config - replace with your config" > /home/ec2-user/monitoring/tools/prometheus/rules.yml
echo "# Placeholder config - replace with your config" > /home/ec2-user/monitoring/tools/tempo/tempo.yml
echo "# Placeholder config - replace with your config" > /home/ec2-user/monitoring/tools/grafana/grafana.ini

# Set proper ownership
chown -R ec2-user:ec2-user /home/ec2-user/monitoring

# Note: You will need to manually upload your proper config files or modify them after deployment