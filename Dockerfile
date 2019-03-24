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

RUN mkdir -p /gateone/logs /gateone/users /gateone/GateOne \
             /etc/gateone/conf.d /etc/gateone/ssl

COPY docker/60docker.conf /etc/gateone/conf.d/60docker.conf

#made transactional to clear up after compiling
RUN apk add --update --no-cache g++ linux-headers openssl && \
    pip install -r /tmp/requirements.txt && \
    cd /gateone/GateOne && \
    wget https://github.com/xykonur/GateOne/archive/master.zip && \
    unzip master.zip && \
    rm -f master.zip && \
    python setup.py install && \
    /usr/local/bin/gateone --configure \
    --log_file_prefix="/gateone/logs/gateone.log" && \
    rm -f /etc/gateone/ssl/key.pem /etc/gateone/ssl/certificate.pem && \
    apk del g++ linux-headers && \
    cd / && \
    rm -rf /gateone/GateOne

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/gateone", "--log_file_prefix=/gateone/logs/gateone.log"]
