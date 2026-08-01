import json
import os
from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI()

LOG_FILE = os.path.join(os.path.dirname(__file__), "call_log.jsonl")


@app.get("/api/calls")
def get_calls():
    if not os.path.exists(LOG_FILE):
        return []
    with open(LOG_FILE) as f:
        lines = f.readlines()
    entries = [json.loads(line) for line in lines[-50:]]
    entries.reverse()
    return entries


@app.get("/", response_class=HTMLResponse)
def index():
    return """
    <html>
    <head>
      <title>ToolGuard Dashboard</title>
      <style>
        body { font-family: sans-serif; margin: 2rem; background:#111; color:#eee; }
        h1 { color: #4caf50; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #444; padding: 8px; text-align: left; font-size: 14px; }
        th { background: #222; }
        .fixed-yes { color: #4caf50; font-weight: bold; }
        .fixed-no { color: #f44336; font-weight: bold; }
        #summary { margin-bottom: 1rem; font-size: 16px; }
      </style>
    </head>
    <body>
      <h1>ToolGuard - Live Reliability Dashboard</h1>
      <div id="summary">Loading...</div>
      <table>
        <thead>
          <tr><th>Time</th><th>Outcome</th><th>Detail</th><th>Fixed by ToolGuard?</th><th>Final Call</th></tr>
        </thead>
        <tbody id="rows"></tbody>
      </table>
      <script>
        async function refresh() {
          const res = await fetch('/api/calls');
          const calls = await res.json();
          const total = calls.length;
          const fixed = calls.filter(c => c.fixed_by_toolguard).length;
          const normal = calls.filter(c => c.outcome === 'NORMAL').length;
          document.getElementById('summary').innerText =
            `Total calls: ${total} | Normal: ${normal} | Caught & Fixed: ${fixed}`;
          const rows = calls.map(c => `
            <tr>
              <td>${c.timestamp}</td>
              <td>${c.outcome}</td>
              <td>${c.detail}</td>
              <td class="${c.fixed_by_toolguard ? 'fixed-yes' : 'fixed-no'}">${c.fixed_by_toolguard ? 'YES' : (c.outcome === 'NORMAL' ? '-' : 'NO')}</td>
              <td>${c.final_call ? JSON.stringify(c.final_call) : '-'}</td>
            </tr>`).join('');
          document.getElementById('rows').innerHTML = rows;
        }
        refresh();
        setInterval(refresh, 2000);
      </script>
    </body>
    </html>
    """
