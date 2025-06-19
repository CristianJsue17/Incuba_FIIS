FROM ruby:3.3.8

# Instalación de dependencias básicas del sistema
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    postgresql-client \
    imagemagick \
    libvips \
    curl \
    git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Directorio de trabajo
WORKDIR /app

# Copiar Gemfile y Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Instalar gems
RUN bundle install

# Copiar el resto de la aplicación
COPY . .

# Exponer puerto 3200
EXPOSE 3200

# Script de inicio limpio
RUN echo '#!/bin/bash\nrm -f /app/tmp/pids/server.pid\nexec rails server -b 0.0.0.0 -p 3200' > /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

#   sudo chown -R 1000:1000 *