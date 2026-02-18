require('dotenv').config();
const { ApolloServer, gql } = require('apollo-server-express');
const express = require('express');
const axios = require('axios');
const cors = require('cors');

const typeDefs = gql`
  type Response {
    success: Boolean
    message: String
    id: String
  }

  type Query {
    health: String
  }

  type Mutation {
    enviarAccion(usuario: String!, accion: String!): Response
  }
`;

const resolvers = {
  Query: {
    health: () => "Gateway GraphQL funcionando correctamente"
  },
  Mutation: {
    enviarAccion: async (_, { usuario, accion }) => {
      try {
        // Usamos la variable de entorno para la URL interna
        const response = await axios.post(process.env.AUDITORIA_URL, {
          usuario,
          accion,
          timestamp: new Date().toISOString()
        });

        return {
          success: true,
          message: "Acción procesada por microservicios",
          id: response.data.id
        };
      } catch (error) {
        console.error('Error comunicación interna:', error.message);
        return {
          success: false,
          message: "El servicio de auditoría no responde"
        };
      }
    }
  }
};

async function startServer() {
  const app = express();
  app.use(cors());

  const server = new ApolloServer({ typeDefs, resolvers });
  await server.start();
  server.applyMiddleware({ app, path: '/graphql' });

  // Endpoint de salud para el Load Balancer de AWS
  app.get('/health', (req, res) => res.status(200).send('OK'));

  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(` Gateway listo en puerto ${PORT}`);
    console.log(`Conectado a Auditoría en: ${process.env.AUDITORIA_URL}`);
  });
}

startServer();