############################################################
# Dockerfile that creates a container for running Gate One.
# Inside the container Gate One will run as the 'gateone'
# user and will listen on port 8000.  docker run example:
#
#   docker run -t --name=gateone -p 443:8000 gateone
#
# That would run Gate One; accessible via port 443 from
# outside the container.  It will also run in the foreground
# with pretty-printed log output (so you can see what's
# going on).  To run Gate One in the background:
#
#   docker run -d --name=gateone -p 443:8000 gateone
#
# You could then stop or start the container like so:
#
#   docker stop gateone
#   docker start gateone
#
# The script that starts Gate One inside of the container
# performs a 'git pull' and will automatically install the
# latest code whenever it runs.  To disable this feature
# simply pass --noupdate when running the container:
#
#   docker run -d --name=gateone -p 443:8000 gateone --noupdate
#
# Note that merely stopping & starting the container doesn't
# pull in updates.  That will only happen if you 'docker rm'
# the container and start it back up again.
#
############################################################

FROM python:2.7-alpine

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

COPY docker/requirements.txt /tmp/requirements.txt

RUN mkdir -p /gateone/logs /gateone/users \
             /etc/gateone/conf.d /etc/gateone/ssl

COPY docker/60docker.conf /etc/gateone/conf.d/60docker.conf

# Create a system user group 'gateone'
RUN addgroup -S gateone

# Create a system user 'gateone' under group 'gateone'
RUN adduser -S -D -h /gateone gateone gateone

#made transactional to clear up after compiling
RUN apk add --update g++ linux-headers busybox-extras \
             openssh-client openssl git && \
	pip install --upgrade pip && \
    pip install -r /tmp/requirements.txt && \
    cd /gateone && \
    git clone -b dev --depth=1 https://github.com/ntaken/gateone.git GateOne && \
    cd GateOne && \
    python setup.py install && \
    /usr/local/bin/gateone --configure \
       --log_file_prefix="/gateone/logs/gateone.log" && \
    cd /etc/gateone/ssl && \
    rm -f key.pem certificate.pem && \
    apk del g++ linux-headers git && \
    rm -rf /gateone/GateOne && \
    rm -rf /var/cache/apk/*

# Chown necessary files to the user.
RUN chown -R gateone:gateone /gateone /etc/gateone /usr/local/lib/python2.7/site-packages/gateone-1.2.0-py2.7.egg

# USER gateone # Disable switch because gateone needs to be able to generate new key.pem certificate.pem 
	       # GateOne will be run by gateone user regardless  
EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/gateone"]
