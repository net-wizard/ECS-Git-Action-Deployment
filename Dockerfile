FROM nginx:alpine

COPY ./Web/ /usr/share/nginx/html

EXPOSE 80
docker run -d -p 8080:80 --name my-static-site my-static-website