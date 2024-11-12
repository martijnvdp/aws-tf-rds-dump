FROM alpine:latest
RUN apk --update add py-pip postgresql-client jq bash && \
pip install awscli && \
rm -rf /var/cache/apk/*
ADD scripts/aws_rds_dump.sh /usr/bin/
RUN chmod +x /usr/bin/aws_rds_dump.sh
ENTRYPOINT ["aws_rds_dump.sh"] 
