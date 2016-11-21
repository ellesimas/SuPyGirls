FROM ubuntu:16.04
MAINTAINER labase

# Install nginx, uwsgi and pip.
RUN echo 'deb http://archive.ubuntu.com/ubuntu xenial main universe' > /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y nginx-full uwsgi-plugin-python3 uwsgi python3-pip

# Install virtualenv for python3 to avoid installing python2.7.
RUN pip3 install virtualenv

# Set-up app folder.
RUN mkdir -p /var/www/igames

# Add local files to the image.
ADD ./server /var/www/igames/

# Add kwarwp files to the image.
ADD ./kwarwp/ /var/www/igames/apps

# Configure nginx to run well with docker?
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Remove default nginx site config.
RUN rm /etc/nginx/sites-enabled/default

# Symlink nginx and uwsgi config files for the app.
RUN ln -s /var/www/igames/nginx_bottlebase /etc/nginx/sites-enabled/
RUN ln -s /var/www/igames/uwsgi_bottlebase.ini /etc/uwsgi/apps-enabled/

# Set-up virtualenv with system Python 3.4
RUN mkdir /opt/venv
RUN virtualenv /opt/venv/igames -p python3

# Add bottle to the virtualenv.
# TODO Use a pip requirements file in the future.
RUN /opt/venv/igames/bin/pip install bottle

# Set permissions so that uwsgi can access app and virtualenv.
RUN chown -R www-data:www-data /opt/venv/igames
RUN chown -R www-data:www-data /var/www/igames
RUN chmod 755 /var/www

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

# Expose port 80.
EXPOSE 80 443

# To avoid udev related error from uwsgi service start, run the following:
# ln -s /proc/self/fd /dev/fd

CMD ln -s /proc/self/fd /dev/fd; service uwsgi restart; nginx