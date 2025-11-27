FROM nginx:alpine

# アプリケーションファイルをコピー
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/

# ポート8080を公開
EXPOSE 8080

# nginxを起動
CMD ["nginx", "-g", "daemon off;"]