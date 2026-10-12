FROM nginx:alpine

# Copy trang HTML đơn giản để demo backend
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
