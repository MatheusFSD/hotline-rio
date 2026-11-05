// Local client for the installed Blender MCP addon JSON bridge.
const net = require('node:net');
const fs = require('node:fs');
const path = require('node:path').resolve(process.argv[2]);
const code = `import runpy; runpy.run_path(${JSON.stringify(path)}, run_name='__main__')`;
const socket = net.createConnection({host:'127.0.0.1', port:9876});
let data = '';
socket.setTimeout(240000);
socket.on('connect', () => socket.write(JSON.stringify({type:'execute_code', params:{code}})));
socket.on('data', chunk => {
  data += chunk;
  let result;
  try { result = JSON.parse(data); } catch { return; }
  console.log(JSON.stringify(result));
  socket.end();
  if (result.status === 'error') process.exitCode = 1;
});
socket.on('timeout', () => { socket.destroy(); process.exitCode = 1; });
socket.on('error', err => { console.error(err.message); process.exitCode = 1; });
