app [main] {
	pf: platform "platform/main.roc",
	api: "api/main.roc",
}

import api.Protocol

main = |text| if Protocol.decode_response(text).is_ok() "ok" else "no"
