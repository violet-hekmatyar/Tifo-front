const http = require('http');

const targetPort = 18082;
const listenPort = 8080;

const server = http.createServer((req, res) => {
  const upstream = http.request(
    {
      hostname: '127.0.0.1',
      port: targetPort,
      path: req.url,
      method: req.method,
      headers: { ...req.headers, host: `127.0.0.1:${targetPort}` },
    },
    (response) => {
      res.writeHead(response.statusCode ?? 502, response.headers);
      response.pipe(res);
    },
  );

  upstream.on('error', (error) => {
    if (!res.headersSent) res.writeHead(502, { 'content-type': 'text/plain' });
    res.end(`proxy error: ${error.message}`);
  });

  req.pipe(upstream);
});

server.listen(listenPort, '0.0.0.0', () => {
  console.log(`VR7 API proxy listening on ${listenPort} -> ${targetPort}`);
});
