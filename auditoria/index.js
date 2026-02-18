require('dotenv').config();
const express = require('express');
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const redis = require('redis');

const app = express();
app.use(express.json());

// 1. Configuración de AWS S3
const s3 = new S3Client({
    region: process.env.AWS_REGION || "us-east-1",
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
        sessionToken: process.env.AWS_SESSION_TOKEN
    }
});

// 2. Configuración de Redis
const redisClient = redis.createClient({
    url: `redis://${process.env.REDIS_HOST}:6379`
});

redisClient.on('error', err => console.log('Redis Client Error', err));
redisClient.connect().then(() => console.log('Connected to Redis'));

// 3. Endpoint de Registro
app.post('/registrar', async (req, res) => {
    const { usuario, accion, timestamp } = req.body;
    const logId = `audit-${Date.now()}`;

    try {
        // Guardar en Redis (Caché rápida)
        await redisClient.set(logId, JSON.stringify({ usuario, accion, timestamp }));

        // Guardar en S3 (Persistencia a largo plazo)
        const command = new PutObjectCommand({
            Bucket: process.env.BUCKET_NAME,
            Key: `logs/${logId}.json`,
            Body: JSON.stringify({ logId, usuario, accion, timestamp }),
            ContentType: "application/json"
        });

        await s3.send(command);

        console.log(`✅ Registro exitoso: ${logId}`);
        res.status(200).json({ success: true, id: logId });
        
    } catch (error) {
        console.error('Error en Auditoría:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
    console.log(` Microservicio de Auditoría corriendo en puerto ${PORT}`);
    console.log(` Usando Bucket: ${process.env.BUCKET_NAME}`);
});