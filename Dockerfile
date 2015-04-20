FROM nginx:1.7.11

COPY _site /usr/share/nginx/html

EXPOSE 80 443

CMD echo 'The webserver is now running'; nginx -g "daemon off;"

