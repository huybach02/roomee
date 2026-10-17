import { spawn } from "node:child_process";

const isWindows = process.platform === "win32";
const children = [];
let stopping = false;

function kill(child) {
  if (child.exitCode !== null || child.signalCode !== null) return;
  if (isWindows) {
    spawn("taskkill", ["/pid", String(child.pid), "/T", "/F"], { stdio: "ignore" });
  } else {
    child.kill("SIGTERM");
  }
}

function stop(code = 0) {
  if (stopping) return;
  stopping = true;

  let pending = 0;
  const done = () => {
    pending -= 1;
    if (pending <= 0) process.exit(code);
  };

  for (const child of children) {
    if (child.exitCode !== null || child.signalCode !== null) continue;
    pending += 1;
    child.once("exit", done);
    kill(child);
  }

  if (pending === 0) process.exit(code);
  setTimeout(() => process.exit(code), 5000).unref();
}

function start(command, args, useShell) {
  const child = spawn(command, args, { stdio: "inherit", shell: useShell });
  children.push(child);

  child.on("exit", (code) => {
    if (stopping) return;
    console.log(`\n"${command}" đã dừng. Dừng dev server...`);
    stop(code ?? 0);
  });

  return child;
}

process.on("SIGINT", () => stop(0));
process.on("SIGTERM", () => stop(0));

// Trên Windows `tsc` là shim .cmd nên phải chạy qua shell; `process.execPath` thì không.
start("tsc", ["--watch", "--preserveWatchOutput"], isWindows);
start(process.execPath, ["--watch", "dist/index.js"], false);
