FROM node:23-alpine

WORKDIR /docs

# Actualiza npm a una versión segura (>=10.9.1) para eliminar la vulnerabilidad de cross-spawn
RUN npm install -g npm@10.9.1 \
    && npm install -g docsify-cli

EXPOSE 3000

CMD ["docsify", "serve", ".", "--port", "3000"]
