FROM nginx:alpine

COPY index.html /usr/share/nginx/html/
COPY css /usr/share/nginx/html/css
COPY js /usr/share/nginx/html/js
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN touch /var/run/nginx.pid \
    && chown -R nginx:nginx /var/cache/nginx /var/run/nginx.pid /usr/share/nginx/html /etc/nginx/conf.d

USER nginx

EXPOSE 8080
