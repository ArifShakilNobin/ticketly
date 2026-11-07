#!/usr/bin/env bash
# End-to-end smoke test through the API gateway.
#   GATEWAY=http://localhost:8080 bash scripts/smoke-test.sh
set -euo pipefail

GATEWAY="${GATEWAY:-http://localhost:8080}"
API_PREFIX="/api/v1"
STAMP="$(date +%s)"
PASS=0
FAIL=0
TOKEN=""
BODY=""
STATUS=""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

say()  { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$*"; PASS=$((PASS + 1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$*"; FAIL=$((FAIL + 1)); }

# call METHOD PATH [JSON_BODY] [TOKEN] -> sets STATUS + BODY
call() {
  local method="$1" path="$2" data="${3:-}" token="${4:-}"
  local args=(-sS -o "$TMP/body" -w '%{http_code}' -X "$method" -H 'Content-Type: application/json')
  [[ -n "$token" ]] && args+=(-H "Authorization: Bearer $token")
  [[ -n "$data" ]] && args+=(--data "$data")
  STATUS="$(curl "${args[@]}" "${GATEWAY}${path}" 2>/dev/null || echo 000)"
  BODY="$(cat "$TMP/body" 2>/dev/null || true)"
}

expect_status() {
  local want="$1" label="$2"
  if [[ "$STATUS" == "$want" ]]; then
    ok "$label (HTTP $STATUS)"
  else
    bad "$label — expected HTTP $want, got ${STATUS:-none}"
    echo "       body: ${BODY:0:400}"
    return 1
  fi
}

jq_assert() {
  local expr="$1" label="$2"
  if jq -e "$expr" >/dev/null 2>&1 <<<"$BODY"; then
    ok "$label"
  else
    bad "$label"
    echo "       body: ${BODY:0:400}"
    return 1
  fi
}

# ---------------------------------------------------------------- 1. health
say "1. Gateway health"
call GET "/actuator/health"
expect_status 200 "gateway is up" || { echo "Is the platform running? (make dev / make up)"; exit 1; }

# --------------------------------------------------------------- 2. register
say "2. Register a new user"
PHONE="017$(printf '%08d' "$((STAMP % 100000000))" | tail -c 8)"
REGISTER_BODY="$(jq -n --arg n "Smoke Test" --arg p "$PHONE" --arg e "smoke-$STAMP@example.com" \
  '{name:$n, phone:$p, email:$e, password:"secret123"}')"
call POST "$API_PREFIX/auth/register" "$REGISTER_BODY"
expect_status 201 "user created"
jq_assert '.token and (.token | length > 20)' "JWT returned"
TOKEN="$(jq -r '.token // empty' <<<"$BODY")"
jq_assert '.user.phone' "user profile returned"

# ------------------------------------------------------------------- 3. me
say "3. Current user"
call GET "$API_PREFIX/users/me" "" "$TOKEN"
expect_status 200 "GET /users/me"
jq_assert '.name == "Smoke Test"' "profile name matches"

# ------------------------------------------------------------ 4. voice parse
say "4. Parse a Bengali/Banglish query"
PARSE_BODY='{"text":"আগামী শুক্রবার ঢাকা থেকে খুলনার সবচেয়ে কম ভাড়ার টিকিট দেখাও","sessionId":"smoke-'$STAMP'"}'
call POST "$API_PREFIX/nlp/parse" "$PARSE_BODY"
expect_status 200 "POST /nlp/parse"
jq_assert '.intent != null and .detectedTerms != null' "intent + terms extracted"
SOURCE="$(jq -r '.source // empty' <<<"$BODY")"
DESTINATION="$(jq -r '.destination // empty' <<<"$BODY")"
INTENT="$(jq -r '.intent // empty' <<<"$BODY")"
TRAVEL_DATE="$(jq -r '.travelDate // empty' <<<"$BODY")"
echo "       intent=$INTENT source=${SOURCE:-?} destination=${DESTINATION:-?} date=${TRAVEL_DATE:-?}"
SOURCE="${SOURCE:-ঢাকা}"
DESTINATION="${DESTINATION:-খুলনা}"
TRAVEL_DATE="${TRAVEL_DATE:-$(date -d '+3 days' +%F 2>/dev/null || date -v+3d +%F)}"

# ---------------------------------------------------------------- 5. search
say "5. Multi-modal search (aggregator + cost engine)"
SEARCH_BODY="$(jq -n --arg s "$SOURCE" --arg d "$DESTINATION" --arg dt "$TRAVEL_DATE" \
  '{source:$s, destination:$d, travelDate:$dt, transportType:"ALL", priority:"CHEAPEST", sessionId:"smoke-'$STAMP'"}')"
call POST "$API_PREFIX/search" "$SEARCH_BODY"
expect_status 200 "POST /search"
jq_assert '.items | length > 0' "at least one fare returned"
TOTAL="$(jq -r '.totalFound // 0' <<<"$BODY")"
echo "       totalFound=$TOTAL"
echo "       top 3 by effective price:"
jq -r '.items[:3][] | "         \(.price.effectivePrice) BDT  \(.fare.provider)  \(.fare.transportType)  \(.fare.departTime)->\(.fare.arriveTime)  \(.badge // "-")"' <<<"$BODY" 2>/dev/null || true
SEARCH_ID="$(jq -r '.searchId // empty' <<<"$BODY")"
FARE_JSON="$(jq -c '.items[0].fare' <<<"$BODY")"
EFFECTIVE="$(jq -r '.items[0].price.effectivePrice' <<<"$BODY")"

# ---------------------------------------------------------------- 6. offers
say "6. Active MFS / bank offers"
call GET "$API_PREFIX/offers"
expect_status 200 "GET /offers"
jq_assert 'type == "array" and length > 0' "offer catalogue seeded"
echo "       $(jq -r 'length' <<<"$BODY") active offer(s)"

# --------------------------------------------------------------- 7. booking
say "7. Create a booking (mock bKash payment)"
BOOKING_BODY="$(jq -n --argjson fare "$FARE_JSON" --arg sid "$SEARCH_ID" --arg phone "$PHONE" \
  '{searchId:$sid, fare:$fare, passengerName:"Smoke Test", passengerPhone:$phone,
    quantity:1, paymentMethod:"MFS", mfsProvider:"bKash"}')"
call POST "$API_PREFIX/bookings" "$BOOKING_BODY" "$TOKEN"
expect_status 201 "POST /bookings"
jq_assert '.pnr and .status == "CONFIRMED"' "booking confirmed with PNR"
PNR="$(jq -r '.pnr // empty' <<<"$BODY")"
BOOKING_ID="$(jq -r '.id // empty' <<<"$BODY")"
echo "       PNR=$PNR  effectivePrice=${EFFECTIVE} BDT"

# ----------------------------------------------------------- 8. my bookings
say "8. My bookings"
call GET "$API_PREFIX/bookings" "" "$TOKEN"
expect_status 200 "GET /bookings"
jq_assert "type == \"array\" and any(.[]; .id == \"$BOOKING_ID\")" "new booking appears in the list"

# --------------------------------------------------------- 9. notifications
say "9. Kafka -> notification delivery (waits up to 20s)"
NOTIFICATIONS=""
for _ in $(seq 1 10); do
  call GET "$API_PREFIX/notifications" "" "$TOKEN"
  if [[ "$STATUS" == "200" ]] && jq -e 'type == "array" and length > 0' >/dev/null 2>&1 <<<"$BODY"; then
    NOTIFICATIONS="$BODY"
    break
  fi
  sleep 2
done
if [[ -n "$NOTIFICATIONS" ]]; then
  expect_status 200 "GET /notifications"
  jq_assert 'length > 0' "confirmation notification received"
  jq -r '.[:3][] | "         [\(.status)] \(.title)"' <<<"$NOTIFICATIONS" 2>/dev/null || true
else
  bad "no notification arrived within 20s (Kafka consumer?)"
fi

# ----------------------------------------------------------------- 10. cancel
say "10. Cancel the booking"
call POST "$API_PREFIX/bookings/$BOOKING_ID/cancel" '{"reason":"smoke test"}' "$TOKEN"
expect_status 200 "POST /bookings/{id}/cancel"
jq_assert '.status == "CANCELLED"' "status is CANCELLED"

# ----------------------------------------------------------------- summary
printf '\n\033[1m%s\033[0m\n' "----------------------------------------"
printf '\033[32m%d passed\033[0m, \033[31m%d failed\033[0m\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
