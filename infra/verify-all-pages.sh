#!/bin/bash
# Comprehensive live-site verification.
# Checks every URL in the sitemap across all 3 locales, asserts HTTP 200,
# and grep-validates that locale-specific content markers are present.
#
# Usage: bash infra/verify-all-pages.sh
# Exit code: non-zero if any URL fails or any content marker is missing.

set -u

BASE="${BASE:-https://thinkingmachine.uk}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'

fails=0

check() {
  local url=$1 must_contain=$2 label=$3
  local tmp=$(mktemp)
  local resp=$(curl -sS -o "$tmp" -w "%{http_code}|%{size_download}|%{time_total}" --max-time 10 "$url")
  local code=$(echo "$resp" | cut -d'|' -f1)
  local size=$(echo "$resp" | cut -d'|' -f2)
  local time=$(echo "$resp" | cut -d'|' -f3)
  local marker=""
  if [ -n "$must_contain" ]; then
    if grep -q -F "$must_contain" "$tmp"; then
      marker=" ${GREEN}✓ '$must_contain'${NC}"
    else
      marker=" ${RED}✗ missing '$must_contain'${NC}"
      fails=$((fails+1))
    fi
  fi
  if [ "$code" = "200" ]; then
    printf "${GREEN}[200]${NC} %-65s %6sB %.2fs%b\n" "$label" "$size" "$time" "$marker"
  else
    printf "${RED}[%s]${NC} %-65s %6sB%b\n" "$code" "$label" "$size" "$marker"
    fails=$((fails+1))
  fi
  rm -f "$tmp"
}

echo "═══ EN ═══"
check "$BASE/"                                            "Recently engaged by"               "/ (home)"
check "$BASE/services"                                    "Three lanes"                       "/services"
check "$BASE/pricing"                                     "Where engagements actually land"   "/pricing"
check "$BASE/process"                                     ""                                  "/process"
check "$BASE/about"                                       "Bruno Božić"                       "/about"
check "$BASE/contact"                                     "Thirty minutes"                    "/contact"
check "$BASE/work"                                        "If you only read one"              "/work"
check "$BASE/notes"                                       ""                                  "/notes"
check "$BASE/404"                                         ""                                  "/404"
check "$BASE/rss.xml"                                     "Thinking Machine"                  "/rss.xml"
check "$BASE/sitemap-index.xml"                           "sitemap"                           "/sitemap-index.xml"
check "$BASE/robots.txt"                                  "Allow"                             "/robots.txt"
check "$BASE/.well-known/security.txt"                    "Contact"                           "/.well-known/security.txt"

echo
echo "═══ Case studies — EN ═══"
for slug in clinical-video-consultation-mental-health cloud-cost-finops cra-readiness-eu-manufacturer nfr-compliance-energy supply-chain-iac-saas-platform; do
  check "$BASE/work/$slug" "Quick read" "/work/$slug"
done

echo
echo "═══ Notes (EN-only) ═══"
for slug in cra-article-14-reporting-clocks energy-procurement-nfr-saas healthcare-lab-to-iot-onboarding healthcare-nfr-from-energy; do
  check "$BASE/notes/$slug" "Verified as of" "/notes/$slug"
done

echo
echo "═══ DE ═══"
check "$BASE/de"                "Zuletzt beauftragt"             "/de"
check "$BASE/de/services"       ""                               "/de/services"
check "$BASE/de/pricing"        "Wo Mandate tatsächlich landen"  "/de/pricing"
check "$BASE/de/process"        ""                               "/de/process"
check "$BASE/de/about"          ""                               "/de/about"
check "$BASE/de/contact"        ""                               "/de/contact"
check "$BASE/de/work"           "Wenn Sie nur eine lesen"        "/de/work"
for slug in clinical-video-consultation-mental-health cloud-cost-finops cra-readiness-eu-manufacturer nfr-compliance-energy supply-chain-iac-saas-platform; do
  check "$BASE/de/work/$slug" "Kurzfassung" "/de/work/$slug"
done

echo
echo "═══ HR ═══"
check "$BASE/hr"                "Nedavno angažirani"             "/hr"
check "$BASE/hr/services"       ""                               "/hr/services"
check "$BASE/hr/pricing"        "Gdje mandati zaista završavaju" "/hr/pricing"
check "$BASE/hr/process"        ""                               "/hr/process"
check "$BASE/hr/about"          ""                               "/hr/about"
check "$BASE/hr/contact"        ""                               "/hr/contact"
check "$BASE/hr/work"           "Ako pročitate samo jednu"       "/hr/work"
for slug in clinical-video-consultation-mental-health cloud-cost-finops cra-readiness-eu-manufacturer nfr-compliance-energy supply-chain-iac-saas-platform; do
  check "$BASE/hr/work/$slug" "Brzi pregled" "/hr/work/$slug"
done

echo
echo "═══ Security headers ═══"
curl -sI --max-time 10 "$BASE/" | grep -iE "(content-security|strict-transport|x-content-type|referrer|permissions-policy)" | head -10

echo
echo "═══ TLS ═══"
echo | openssl s_client -servername thinkingmachine.uk -connect thinkingmachine.uk:443 2>/dev/null | openssl x509 -noout -dates -subject -issuer

echo
if [ "$fails" -eq 0 ]; then
  echo -e "${GREEN}═══ ALL CHECKS PASSED ═══${NC}"
  exit 0
else
  echo -e "${RED}═══ $fails CHECKS FAILED ═══${NC}"
  exit 1
fi
