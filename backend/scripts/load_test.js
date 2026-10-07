const http = require('http');

const HOST = 'localhost';
const PORT = 3000;
const DURATION_SECONDS = 3;
const CONCURRENCY = 5;

const endpoints = [
  '/api/v1/sync?since=0',
  '/api/v1/announcements',
  '/api/v1/places',
  '/api/v1/events',
  '/api/v1/parking'
];

async function runApplicationBenchmark() {
  console.log('====================================================');
  console.log('⚡ NASHIK KUMBH MELA — REAL APPLICATION THROUGHPUT BENCHMARK');
  console.log(`Target: http://${HOST}:${PORT}`);
  console.log(`Concurrency: ${CONCURRENCY} workers | Duration: ${DURATION_SECONDS}s`);
  console.log('====================================================');

  const startTime = Date.now();
  const latencies = [];
  let successCount = 0;
  let rateLimitedCount = 0;
  let errorCount = 0;
  let isRunning = true;

  setTimeout(() => {
    isRunning = false;
  }, DURATION_SECONDS * 1000);

  async function worker(workerId) {
    let endpointIdx = 0;
    while (isRunning) {
      const endpoint = endpoints[endpointIdx % endpoints.length];
      endpointIdx++;
      
      const reqStart = Date.now();
      await new Promise((resolve) => {
        const req = http.request({
          host: HOST,
          port: PORT,
          path: endpoint,
          method: 'GET',
          headers: {
            'X-Forwarded-For': `10.0.${workerId}.${Math.floor(Math.random() * 250)}` // Simulate distributed clients
          }
        }, (res) => {
          res.on('data', () => {});
          res.on('end', () => {
            const elapsed = Date.now() - reqStart;
            if (res.statusCode >= 200 && res.statusCode < 400) {
              successCount++;
              latencies.push(elapsed);
            } else if (res.statusCode === 429) {
              rateLimitedCount++;
              latencies.push(elapsed);
            } else {
              errorCount++;
            }
            resolve();
          });
        });
        req.on('error', () => {
          errorCount++;
          resolve();
        });
        req.end();
      });

      // Small delay between requests to simulate real mobile clients
      await new Promise(r => setTimeout(r, 20));
    }
  }

  const workers = Array.from({ length: CONCURRENCY }, (_, i) => worker(i + 1));
  await Promise.all(workers);

  const totalTimeSec = (Date.now() - startTime) / 1000;
  latencies.sort((a, b) => a - b);

  const totalRequests = successCount + rateLimitedCount + errorCount;
  const reqPerSec = (totalRequests / totalTimeSec).toFixed(2);
  const successReqPerSec = (successCount / totalTimeSec).toFixed(2);
  const p50 = latencies[Math.floor(latencies.length * 0.50)] || 0;
  const p95 = latencies[Math.floor(latencies.length * 0.95)] || 0;
  const p99 = latencies[Math.floor(latencies.length * 0.99)] || 0;

  console.log(`\n📊 MEASURED APPLICATION BENCHMARK RESULTS:`);
  console.log(`   - Total Requests Executed:    ${totalRequests}`);
  console.log(`   - Successful (HTTP 200/304):  ${successCount} (${successReqPerSec} req/s)`);
  console.log(`   - Rate Limited (HTTP 429):    ${rateLimitedCount}`);
  console.log(`   - Unexpected Errors:          ${errorCount}`);
  console.log(`   - Overall Throughput:         ${reqPerSec} req/s`);
  console.log(`   - Latency p50 (Median):      ${p50} ms`);
  console.log(`   - Latency p95:                ${p95} ms`);
  console.log(`   - Latency p99:                ${p99} ms`);
  console.log('====================================================');
}

runApplicationBenchmark();
