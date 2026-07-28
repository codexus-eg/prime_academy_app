#!/usr/bin/env node
/**
 * Local dev proxy for Flutter web — bypasses production CORS during `flutter run -d chrome`.
 *
 * Routes:
 *   /api/*         → https://primeacademy.education/api/*
 *   /cdn-statics/* → https://cdn-statics.primeacademy.education/*
 *   /cdn-media/*   → https://cdn.primeacademy.education/primeacademy/*
 *   PUT /r2-put    → forwards PUT body to presigned R2 URL (?url=...)
 *
 * Usage: node tool/web_dev_proxy.js
 */

const http = require('http');
const https = require('https');
const { URL } = require('url');

const PROXY_HOST = '127.0.0.1';
const PROXY_PORT = 8787;

const ROUTES = [
  { prefix: '/api', target: 'https://primeacademy.education' },
  {
    prefix: '/cdn-statics',
    target: 'https://cdn-statics.primeacademy.education',
    stripPrefix: true,
  },
  {
    prefix: '/cdn-media',
    target: 'https://cdn.primeacademy.education/primeacademy',
    stripPrefix: true,
  },
];

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers':
    'Content-Type, Accept, Accept-Language, Authorization, x-device-identifier, x-platform',
};

function sendOptions(res) {
  res.writeHead(204, corsHeaders);
  res.end();
}

function resolveRoute(url) {
  for (const route of ROUTES) {
    if (url.startsWith(route.prefix)) {
      let path = url;
      if (route.stripPrefix) {
        path = url.slice(route.prefix.length) || '/';
      }
      return { target: route.target, path };
    }
  }
  return null;
}

function proxyRequest(req, res, targetOrigin, targetPath) {
  const targetUrl = new URL(targetPath, targetOrigin);

  const headers = { ...req.headers, host: targetUrl.host };
  delete headers.origin;
  delete headers.referer;

  const options = {
    protocol: targetUrl.protocol,
    hostname: targetUrl.hostname,
    port: targetUrl.port || 443,
    path: targetUrl.pathname + targetUrl.search,
    method: req.method,
    headers,
  };

  const transport = targetUrl.protocol === 'https:' ? https : http;

  const upstream = transport.request(options, (upstreamRes) => {
    const responseHeaders = {
      ...corsHeaders,
      ...upstreamRes.headers,
    };
    delete responseHeaders['access-control-allow-origin'];

    res.writeHead(upstreamRes.statusCode ?? 502, responseHeaders);
    upstreamRes.pipe(res);
  });

  upstream.on('error', (error) => {
    console.error('[proxy] upstream error:', error.message);
    res.writeHead(502, { ...corsHeaders, 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ message: 'Proxy upstream error' }));
  });

  req.pipe(upstream);
}

/// Forwards browser PUT to a presigned R2 URL — bypasses R2 CORS on localhost.
function handleR2Put(req, res) {
  const parsed = new URL(req.url, `http://${PROXY_HOST}:${PROXY_PORT}`);
  const target = parsed.searchParams.get('url');
  if (!target) {
    res.writeHead(400, { ...corsHeaders, 'Content-Type': 'text/plain' });
    res.end('Missing url parameter');
    return;
  }

  let targetUrl;
  try {
    targetUrl = new URL(target);
  } catch {
    res.writeHead(400, { ...corsHeaders, 'Content-Type': 'text/plain' });
    res.end('Invalid url parameter');
    return;
  }

  const chunks = [];
  req.on('data', (chunk) => chunks.push(chunk));
  req.on('end', () => {
    const body = Buffer.concat(chunks);
    const contentType = req.headers['content-type'] || 'application/octet-stream';

    const options = {
      protocol: targetUrl.protocol,
      hostname: targetUrl.hostname,
      port: targetUrl.port || (targetUrl.protocol === 'https:' ? 443 : 80),
      path: targetUrl.pathname + targetUrl.search,
      method: 'PUT',
      headers: {
        'Content-Type': contentType,
        'Content-Length': body.length,
        host: targetUrl.host,
      },
    };

    const transport = targetUrl.protocol === 'https:' ? https : http;
    const upstream = transport.request(options, (upstreamRes) => {
      res.writeHead(upstreamRes.statusCode ?? 502, corsHeaders);
      upstreamRes.pipe(res);
    });

    upstream.on('error', (error) => {
      console.error('[proxy] r2-put error:', error.message);
      res.writeHead(502, { ...corsHeaders, 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: 'R2 upload proxy error' }));
    });

    upstream.end(body);
  });

  req.on('error', (error) => {
    console.error('[proxy] r2-put request error:', error.message);
    if (!res.headersSent) {
      res.writeHead(500, corsHeaders);
      res.end();
    }
  });
}

const server = http.createServer((req, res) => {
  if (req.method === 'OPTIONS') {
    sendOptions(res);
    return;
  }

  const pathname = req.url.split('?')[0];
  if (pathname === '/r2-put' && req.method === 'PUT') {
    handleR2Put(req, res);
    return;
  }

  const route = resolveRoute(req.url);
  if (!route) {
    res.writeHead(404, corsHeaders);
    res.end('Not found');
    return;
  }

  proxyRequest(req, res, route.target, route.path);
});

server.listen(PROXY_PORT, PROXY_HOST, () => {
  console.log(`[web_dev_proxy] http://${PROXY_HOST}:${PROXY_PORT}`);
  console.log('  /api/*         → primeacademy.education/api/*');
  console.log('  /cdn-statics/* → cdn-statics.primeacademy.education/*');
  console.log('  /cdn-media/*   → cdn.primeacademy.education/primeacademy/*');
  console.log('  PUT /r2-put    → presigned R2 upload (dev CORS bypass)');
});
