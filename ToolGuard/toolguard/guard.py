from detector import detect, NORMAL, FAIL_PLAIN_TEXT, FAIL_SCHEMA_LEAK, FAIL_WRONG_TOOL_NAME
from fixer import fix_plain_text_call, fix_wrong_tool_name, fix_schema_leak, fix_dropped_stream


def guard_response(response_json, original_messages, ask_model_fn):
    label, detail = detect(response_json)

    if label == NORMAL:
        call = response_json["choices"][0]["message"]["tool_calls"][0]["function"]
        return {
            "outcome": label,
            "detail": detail,
            "fixed_by_toolguard": False,
            "final_call": {"name": call["name"], "arguments": call.get("arguments", "{}")},
        }

    if label == FAIL_PLAIN_TEXT:
        content = response_json["choices"][0]["message"].get("content", "")
        repaired = fix_plain_text_call(content, original_messages, ask_model_fn)
        repaired_label, _ = detect(repaired)
        if repaired_label == NORMAL:
            call = repaired["choices"][0]["message"]["tool_calls"][0]["function"]
            return {
                "outcome": label, "detail": detail, "fixed_by_toolguard": True,
                "final_call": {"name": call["name"], "arguments": call.get("arguments", "{}")},
            }
        return {"outcome": label, "detail": detail, "fixed_by_toolguard": False, "final_call": None}

    if label == FAIL_WRONG_TOOL_NAME:
        repaired = fix_wrong_tool_name(response_json, original_messages, ask_model_fn)
        repaired_label, _ = detect(repaired)
        if repaired_label == NORMAL:
            call = repaired["choices"][0]["message"]["tool_calls"][0]["function"]
            return {
                "outcome": label, "detail": detail, "fixed_by_toolguard": True,
                "final_call": {"name": call["name"], "arguments": call.get("arguments", "{}")},
            }
        return {"outcome": label, "detail": detail, "fixed_by_toolguard": False, "final_call": None}

    if label == FAIL_SCHEMA_LEAK:
        retry_response = fix_schema_leak(original_messages, ask_model_fn)
        retry_label, _ = detect(retry_response)
        if retry_label == NORMAL:
            call = retry_response["choices"][0]["message"]["tool_calls"][0]["function"]
            return {
                "outcome": label,
                "detail": detail,
                "fixed_by_toolguard": True,
                "final_call": {"name": call["name"], "arguments": call.get("arguments", "{}")},
            }
        return {"outcome": label, "detail": detail, "fixed_by_toolguard": False, "final_call": None}

    return {"outcome": label, "detail": detail, "fixed_by_toolguard": False, "final_call": None}


def guard_dropped_stream(original_messages, ask_model_fn):
    retry_response = fix_dropped_stream(original_messages, ask_model_fn)
    retry_label, _ = detect(retry_response)
    if retry_label == NORMAL:
        call = retry_response["choices"][0]["message"]["tool_calls"][0]["function"]
        return {
            "outcome": "FAIL_DROPPED_STREAM",
            "detail": "Stream was cut off before completion",
            "fixed_by_toolguard": True,
            "final_call": {"name": call["name"], "arguments": call.get("arguments", "{}")},
        }
    return {
        "outcome": "FAIL_DROPPED_STREAM",
        "detail": "Stream was cut off before completion",
        "fixed_by_toolguard": False,
        "final_call": None,
    }
