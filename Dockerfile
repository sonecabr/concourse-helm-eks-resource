FROM linkyard/docker-helm:2.12.2

RUN apk add --update --upgrade --no-cache jq bash curl

RUN apk -v --update add \
        python \
        py-pip \
        groff \
        less \
        mailcap \
        && \
        pip install --upgrade awscli==1.16.93 s3cmd==2.0.1 python-magic && \
        apk -v --purge del py-pip && \
        rm /var/cache/apk/*

#VOLUME /root/.aws

ARG KUBERNETES_VERSION=1.11.6
ARG AWS_IAM_AUTHENTICATOR_VERSION=0.3.0

RUN curl -L -o /usr/local/bin/aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTHENTICATOR_VERSION}/heptio-authenticator-aws_${AWS_IAM_AUTHENTICATOR_VERSION}_linux_amd64 && \
    chmod +x /usr/local/bin/aws-iam-authenticator

RUN curl -L -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl; \
    chmod +x /usr/local/bin/kubectl

ADD .aws /root/.aws # add your std aws credentials to been able to configure kubectl without sts
ADD assets /opt/resource
RUN chmod +x /opt/resource/*
RUN chmod +x /root/.aws

RUN mkdir -p "$(helm home)/plugins"
RUN helm plugin install https://github.com/databus23/helm-diff

ENTRYPOINT [ "/bin/bash" ]
