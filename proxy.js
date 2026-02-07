/**
 * Lightweight reverse proxy that sits in front of OpenClaw.
 * - Serves /api/workspace-files by reading .md files from the workspace directory
 * - Proxies all other requests to the OpenClaw gateway running on OPENCLAW_PORT
 */

const http = require('http')
const fs = require('fs')
const path = require('path')

const PORT = parseInt(process.env.PORT || '3000', 10)
const OPENCLAW_PORT = parseInt(process.env.OPENCLAW_PORT || '4000', 10)
const GATEWAY_TOKEN = process.env.OPENCLAW_GATEWAY_TOKEN || ''
const WORKSPACE_DIR = path.join(__dirname, 'workspace')

function checkAuth(req) {
  if (!GATEWAY_TOKEN) return true
  const auth = req.headers['authorization'] || ''
  return auth === `Bearer ${GATEWAY_TOKEN}`
}

function handleWorkspaceFiles(req, res) {
  if (!checkAuth(req)) {
    res.writeHead(401, { 'Content-Type': 'application/json' })
    res.end(JSON.stringify({ error: 'Unauthorized' }))
    return
  }

  fs.readdir(WORKSPACE_DIR, (err, entries) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'application/json' })
      res.end(JSON.stringify({ error: 'Failed to read workspace directory' }))
      return
    }

    const mdFiles = entries.filter(f => f.endsWith('.md')).sort()
    let pending = mdFiles.length
    const files = []

    if (pending === 0) {
      res.writeHead(200, { 'Content-Type': 'application/json' })
      res.end(JSON.stringify({ files: [] }))
      return
    }

    mdFiles.forEach(filename => {
      fs.readFile(path.join(WORKSPACE_DIR, filename), 'utf-8', (err, content) => {
        if (!err) {
          files.push({ name: filename, content, source: 'live' })
        }
        pending--
        if (pending === 0) {
          // Sort to match the original order
          files.sort((a, b) => mdFiles.indexOf(a.name) - mdFiles.indexOf(b.name))
          res.writeHead(200, { 'Content-Type': 'application/json' })
          res.end(JSON.stringify({ files, source: 'live' }))
        }
      })
    })
  })
}

function proxyToOpenClaw(req, res) {
  const options = {
    hostname: '127.0.0.1',
    port: OPENCLAW_PORT,
    path: req.url,
    method: req.method,
    headers: req.headers,
  }

  const proxyReq = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers)
    proxyRes.pipe(res, { end: true })
  })

  proxyReq.on('error', (err) => {
    console.error('Proxy error:', err.message)
    if (!res.headersSent) {
      res.writeHead(502, { 'Content-Type': 'application/json' })
      res.end(JSON.stringify({ error: 'Gateway not ready' }))
    }
  })

  req.pipe(proxyReq, { end: true })
}

// Handle WebSocket upgrades (for OpenClaw's live features)
const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/api/workspace-files') {
    handleWorkspaceFiles(req, res)
  } else {
    proxyToOpenClaw(req, res)
  }
})

server.on('upgrade', (req, socket, head) => {
  const options = {
    hostname: '127.0.0.1',
    port: OPENCLAW_PORT,
    path: req.url,
    method: req.method,
    headers: req.headers,
  }

  const proxyReq = http.request(options)
  proxyReq.on('upgrade', (proxyRes, proxySocket, proxyHead) => {
    socket.write(
      `HTTP/1.1 101 Switching Protocols\r\n` +
      Object.entries(proxyRes.headers).map(([k, v]) => `${k}: ${v}`).join('\r\n') +
      '\r\n\r\n'
    )
    if (proxyHead.length) socket.write(proxyHead)
    proxySocket.pipe(socket)
    socket.pipe(proxySocket)
  })

  proxyReq.on('error', () => {
    socket.destroy()
  })

  proxyReq.end()
})

server.listen(PORT, () => {
  console.log(`✓ Proxy listening on :${PORT} → OpenClaw on :${OPENCLAW_PORT}`)
})
