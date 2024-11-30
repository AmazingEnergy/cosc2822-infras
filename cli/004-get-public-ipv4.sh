
mkdir ./_output
mkdir ./_output/get-public-ipv4
OUTPUT_DIR="./_output/get-public-ipv4"

curl 'https://api.whatismyip.com/wimi.php' \
  -X 'POST' \
  -H 'accept: */*' \
  -H 'accept-language: en-US,en;q=0.9,vi;q=0.8' \
  -H 'content-length: 0' \
  -H 'origin: https://www.whatismyip.com' \
  -H 'priority: u=1, i' \
  -H 'referer: https://www.whatismyip.com/' \
  -H 'sec-ch-ua: "Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-site' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36' \
	> $OUTPUT_DIR/my-ip-response.json

MY_IP=$(jq -r '.ip' $OUTPUT_DIR/my-ip-response.json)

echo "$MY_IP/32"