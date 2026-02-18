require('dotenv').config();
const axios = require('axios');

// Definimos la mutación de GraphQL como un String
const graphqlQuery = {
    query: `
        mutation RegistrarNuevaAccion($usuario: String!, $accion: String!) {
            enviarAccion(usuario: $usuario, accion: $accion) {
                success
                message
                id
            }
        }
    `,
    variables: {
        usuario: "Mauro_UCE",
        accion: "Login_Sistema_Laboratorios"
    }
};

async function enviarPrueba() {
    try {
        console.log(`Enviando petición GraphQL a: ${process.env.API_URL}`);
        
        const response = await axios.post(process.env.API_URL, graphqlQuery, {
            headers: {
                'Content-Type': 'application/json'
            }
        });

        const resultado = response.data.data.enviarAccion;
        
        if (resultado.success) {
            console.log("✅ Éxito en la comunicación:");
            console.log(`   ID del Log: ${resultado.id}`);
            console.log(`   Mensaje: ${resultado.message}`);
        } else {
            console.log("❌ Error en el servidor:", resultado.message);
        }

    } catch (error) {
        console.error(" Error de conexión:", error.message);
        if (error.response) {
            console.error("Detalle:", error.response.data);
        }
    }
}

// Ejecutar la prueba
enviarPrueba();