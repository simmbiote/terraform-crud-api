const AWS = require("aws-sdk");

const dynamo = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event, context) => {
  let body;
  let statusCode = 200;
  const headers = {
    "Content-Type": "application/json",
  };

  const routePath = `${event.httpMethod} ${event.resource}`;

  try {
    switch (routePath) {
      case "DELETE /items/{id}":
        await dynamo
          .delete({
            TableName: "ProductCollections",
            Key: {
              id: event.pathParameters.id,
            },
          })
          .promise();
        body = {
          success: true,
          message: `Deleted item ${event.pathParameters.id}`,
        };
        break;
      case "GET /items/{id}":
        body = await dynamo
          .get({
            TableName: "ProductCollections",
            Key: {
              id: event.pathParameters.id,
            },
          })
          .promise();
        break;
      case "GET /items":
        body = await dynamo.scan({ TableName: "ProductCollections" }).promise();
        break;
      case "PUT /items":
      case "POST /items":
        let requestJSON = JSON.parse(event.body);
        const id = requestJSON.id || `${new Date().getTime()}`;
        await dynamo
          .put({
            TableName: "ProductCollections",
            Item: {
              ...requestJSON,
              id,
            },
          })
          .promise();
        body = { success: true, message: `Put item ${id}` };
        break;
      default:
        throw new Error(`Unsupported route: "${routePath}"`);
    }
  } catch (err) {
    statusCode = 400;
    body = err.message;
  } finally {
    body = JSON.stringify(body);
  }

  return {
    statusCode,
    body,
    headers,
  };
};
