#!/bin/bash
# ══════════════════════════════════════════════════════════════
# run_tests.sh — Execute jMeter performance test in headless mode
# Usage: ./run_tests.sh [threads] [rampup] [duration]
# Defaults: 50 threads, 30s ramp-up, 60s duration
# ══════════════════════════════════════════════════════════════

set -e

# ── Config ────────────────────────────────────────────────────
THREADS=${1:-50}
RAMPUP=${2:-30}
DURATION=${3:-60}
ERROR_THRESHOLD=1   # fail if error rate exceeds this %

JMETER_HOME="${JMETER_HOME:-/opt/apache-jmeter-5.6.3}"
JMETER="$JMETER_HOME/bin/jmeter"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="results/results_${TIMESTAMP}.jtl"
REPORT_DIR="results/report_${TIMESTAMP}"

# ── Pre-flight checks ─────────────────────────────────────────
if [ ! -f "$JMETER" ]; then
  echo "ERROR: jMeter not found at $JMETER"
  echo "Set JMETER_HOME environment variable or install jMeter."
  echo "Download: https://jmeter.apache.org/download_jmeter.cgi"
  exit 1
fi

if [ ! -f "api_performance_test.jmx" ]; then
  echo "ERROR: Test plan api_performance_test.jmx not found."
  echo "Run this script from the project root directory."
  exit 1
fi

mkdir -p results

# ── Run ───────────────────────────────────────────────────────
echo "══════════════════════════════════════════════"
echo " API Performance Test — $(date)"
echo " Target:   https://jsonplaceholder.typicode.com"
echo " Threads:  $THREADS users"
echo " Ramp-up:  ${RAMPUP}s"
echo " Duration: ${DURATION}s"
echo " Results:  $RESULTS_FILE"
echo " Report:   $REPORT_DIR/index.html"
echo "══════════════════════════════════════════════"

"$JMETER" \
  -n \
  -t api_performance_test.jmx \
  -l "$RESULTS_FILE" \
  -e -o "$REPORT_DIR" \
  -Jthreads="$THREADS" \
  -Jrampup="$RAMPUP" \
  -Jduration="$DURATION" \
  -j "results/jmeter_${TIMESTAMP}.log"

echo ""
echo "Test complete. Analysing results..."

# ── Pass / Fail analysis ──────────────────────────────────────
# Count lines: total samples and failures
# .jtl CSV format: timestamp,elapsed,label,responseCode,responseMessage,
#                  threadName,dataType,success,...
TOTAL=$(tail -n +2 "$RESULTS_FILE" | wc -l | tr -d ' ')
ERRORS=$(tail -n +2 "$RESULTS_FILE" | awk -F',' '$8 == "false"' | wc -l | tr -d ' ')

if [ "$TOTAL" -eq 0 ]; then
  echo "ERROR: No results recorded. Check jmeter log."
  exit 1
fi

ERROR_PCT=$(awk "BEGIN {printf \"%.2f\", ($ERRORS / $TOTAL) * 100}")

echo "══════════════════════════════════════════════"
echo " RESULTS SUMMARY"
echo " Total requests:  $TOTAL"
echo " Failures:        $ERRORS"
echo " Error rate:      ${ERROR_PCT}%"
echo " Threshold:       ${ERROR_THRESHOLD}%"
echo "══════════════════════════════════════════════"

# Check against threshold
FAIL=$(awk "BEGIN {print ($ERROR_PCT > $ERROR_THRESHOLD) ? 1 : 0}")
if [ "$FAIL" -eq 1 ]; then
  echo " ❌  FAIL — error rate ${ERROR_PCT}% exceeds threshold ${ERROR_THRESHOLD}%"
  echo " Open report: $REPORT_DIR/index.html"
  exit 1
else
  echo " ✅  PASS — error rate ${ERROR_PCT}% within threshold"
  echo " Open report: $REPORT_DIR/index.html"
  exit 0
fi
