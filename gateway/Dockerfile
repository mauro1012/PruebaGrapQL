FROM node:18-slim

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

# No copiamos el .env aquí, las variables se inyectan en el docker-compose
EXPOSE 3000

CMD ["node", "index.js"]