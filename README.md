# API Performance Testing Suite
### Apache jMeter · JSONPlaceholder REST API · CI/CD integrated

---

## Overview

A complete API performance testing procedure demonstrating load test design,
execution, assertions, and CI/CD integration using Apache jMeter.

**Target:** [JSONPlaceholder](https://jsonplaceholder.typicode.com/) — a free
public REST API purpose-built for testing and prototyping.

**Purpose:** Portfolio demonstration of API performance testing skills aligned
with AT*SQA API Testing micro-credential syllabus.

---

## Test Scenarios

| # | Scenario | Endpoint | Method | Pass Criteria |
|---|---|---|---|---|
| SC1 | List all posts | `/posts` | GET | Status 200 · Response time < 2000ms · Body is JSON array |
| SC2 | Fetch single post | `/posts/{id}` | GET | Status 200 · Response time < 1000ms · Body contains `"id"` field |
| SC3 | Create a post | `/posts` | POST | Status 201 · Response time < 1500ms · Body contains new `"id"` |

---

## Load Profile

| Parameter | Value | Override flag |
|---|---|---|
| Virtual users (threads) | 50 | `-Jthreads=N` |
| Ramp-up period | 30 seconds | `-Jrampup=N` |
| Sustained duration | 60 seconds | `-Jduration=N` |
| Think time between steps | 300–500 ms | (edit in .jmx) |
| Test data | 20 post/user ID pairs | `test_data/post_ids.csv` |

**Thread lifecycle:** Each virtual user executes SC1 → SC2 → SC3 in sequence,
with a think time pause between steps, then loops for the test duration.
The CSV Data Set ensures each thread uses a different post ID, simulating
realistic diverse user behaviour rather than all threads hitting the same cache.

---

## Project Structure

```
jmeter-performance-test/
├── api_performance_test.jmx      # jMeter test plan (open in jMeter GUI)
├── test_data/
│   └── post_ids.csv              # Test data: postId,userId pairs
├── results/                      # Generated at runtime (gitignored)
│   ├── results_<timestamp>.jtl   # Raw results (CSV)
│   └── report_<timestamp>/       # HTML report (open index.html)
├── run_tests.sh                  # Headless runner with pass/fail check
├── .github/workflows/
│   └── performance.yml           # GitHub Actions CI/CD integration
└── README.md
```

---

## Running the Tests

### Prerequisites

- Java 11+ (`java -version`)
- [Apache jMeter 5.6.3+](https://jmeter.apache.org/download_jmeter.cgi)
- Set `JMETER_HOME` environment variable

```bash
# Linux/Mac
export JMETER_HOME=/opt/apache-jmeter-5.6.3

# Verify
$JMETER_HOME/bin/jmeter --version
```

### GUI mode — explore and edit the test plan

```bash
$JMETER_HOME/bin/jmeter -t api_performance_test.jmx
```

Open the test plan in the GUI to inspect component configuration,
add assertions, or adjust the thread group before running.

### Headless mode — for CI/CD pipelines

```bash
chmod +x run_tests.sh
./run_tests.sh              # 50 users, 30s ramp, 60s duration
./run_tests.sh 100 60 120   # 100 users, 60s ramp, 120s duration
```

The script:
1. Runs jMeter in non-GUI mode (`-n`)
2. Generates a timestamped `.jtl` results file
3. Generates an HTML report at `results/report_<timestamp>/index.html`
4. Checks error rate against 1% threshold
5. Exits 0 (pass) or 1 (fail) — usable directly in pipelines

### Override parameters without editing the .jmx

```bash
$JMETER_HOME/bin/jmeter \
  -n \
  -t api_performance_test.jmx \
  -l results/results.jtl \
  -e -o results/report \
  -Jthreads=100 \
  -Jrampup=60 \
  -Jduration=180
```

---

## Reading the HTML Report

Open `results/report_<timestamp>/index.html` in a browser. Key sections:

| Section | What to look for |
|---|---|
| **Statistics** | Throughput (req/s), error rate, p90/p95/p99 response times |
| **Response Times Over Time** | Spot degradation as load increases during ramp-up |
| **Active Threads Over Time** | Confirms ramp-up shape matches configuration |
| **Transactions Per Second** | Sustained throughput at full load |
| **Response Time Percentiles** | p99 spikes indicate tail latency issues |

---

## Assertions

Every scenario has three layers of assertions:

1. **HTTP status code** — exact match (200 or 201)
2. **Response body** — content validation (JSON structure check)
3. **Duration** — response time threshold (varies by scenario criticality)

A failed assertion marks the sample as an error in the `.jtl` file and
contributes to the error rate. The pipeline fails if error rate exceeds 1%.

---

## CI/CD Integration

The included GitHub Actions workflow (`.github/workflows/performance.yml`):

- Runs automatically on push to `main` or `develop`
- Runs nightly at 02:00 UTC
- Can be triggered manually with custom thread/duration parameters
- Uploads the HTML report as a build artifact (retained 30 days)
- Posts a summary table to the GitHub Actions job summary

---

## Skills Demonstrated

- jMeter test plan design (Thread Groups, HTTP Samplers, Assertions, Listeners)
- Realistic load simulation (ramp-up, think time, CSV-driven data)
- Multi-assertion strategy (status, body, duration)
- Parameterised configuration (variables overrideable from CLI)
- Headless execution with programmatic pass/fail evaluation
- CI/CD pipeline integration (GitHub Actions)
- Test result interpretation (percentiles, throughput, error rate)

---

## Author

Ilan · QA Automation Engineer · ISTQB CTFL · CTAL-TAE v2.0 · AT*SQA API Testing
