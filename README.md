# PHP + Image + Video  

- PHP 7.1 (PHP-FPM)
- ImageMagick
- Inkscape
- FFmpeg  

## How to use
Network Mode = host

**docker-compose**
```yaml
  php:
    container_name: "php"
    image: positron/php-image-video
    environment:
      - PHP_TIMEZONE=Asia/Bangkok
      - PHP_PORT=9000
      - PHP_STATUS_URL=/status
    restart: always
    privileged: true
    volumes:
      - /var/www:/var/www
    network_mode: "host"
```

# Package
- Centos 7
- PHP with FPM 7.1 (Remi's RPM repository)
ext:  php-common php-cli php-process php-gd php-mbstring php-pecl-zip php-mcrypt php-xml php-pecl-apc php-pecl-mongodb php-xmlrpc php-opcache php-fpm
- ImageMagick 6.7.8
- Inkscape 0.91
- FFmpeg  3.2

.

# Note
**build**
```
sudo docker build -t positron/php-image-video -t positron/php-image-video:7 -t positron/php-image-video:7.1 -t positron/php-image-video:latest /home/positron/My/Webs/.docker/php-image-video/ --no-cache=true
```
**push**
```
sudo docker push positron/php-image-video
```

.
