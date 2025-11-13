FROM public.ecr.aws/amazonlinux/amazonlinux:2023

RUN dnf update -y && \
    dnf install -y httpd && \
    dnf clean all

# HTMLファイルをコピー
COPY index.html /var/www/html/

# ヘルスチェック用
RUN echo 'OK' > /var/www/html/health

RUN echo 'ServerName localhost' >> /etc/httpd/conf/httpd.conf

EXPOSE 80
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]