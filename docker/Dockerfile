# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation

FROM nginx:alpine

# Copy custom nginx configs
COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static HTML page
COPY index.html /usr/share/nginx/html/

# Create necessary directories with proper permissions
RUN mkdir -p /tmp/nginx/run /tmp/nginx/client_body /tmp/nginx/proxy /tmp/nginx/fastcgi /tmp/nginx/uwsgi /tmp/nginx/scgi \
    && chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d /tmp/nginx

# Switch to the non-root user
USER nginx

# Expose the port for access
EXPOSE 8080

# Run nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
