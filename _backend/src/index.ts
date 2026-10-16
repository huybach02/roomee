import "dotenv/config";
import App from "./app.js";
import { DEFAULT_PORT } from "./utils/constanst.js";

const PORT = Number(process.env.PORT) || DEFAULT_PORT;

const server = new App(PORT);
server.listen();
