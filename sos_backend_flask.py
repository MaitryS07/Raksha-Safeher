from flask import Flask, request, jsonify
from twilio.rest import Client
import threading
import time
import os
import random
from datetime import datetime, timedelta
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch
import sys

app = Flask(__name__)

# ======================================================
# 📝 LOGGING HELPER
# ======================================================
def log_event(*args, **kwargs):
    """Prints and flushes to ensure real-time visibility in Windows terminals."""
    print(*args, **kwargs)
    sys.stdout.flush()

# ======================================================
# 🔐 TWILIO CREDENTIALS
# ======================================================
ACCOUNT_SID = os.getenv("TWILIO_SID")
AUTH_TOKEN = os.getenv("TWILIO_AUTH")
TWILIO_NUMBER = os.getenv("TWILIO_PHONE")
log_event("🔍 Backend booting...")
log_event("🔑 SID:", ACCOUNT_SID[-4:] if ACCOUNT_SID else "❌ MISSING")
log_event("🔑 AUTH:", "✅ FOUND" if AUTH_TOKEN else "❌ MISSING")
log_event("📞 FROM:", TWILIO_NUMBER if TWILIO_NUMBER else "❌ MISSING")
twilio_ready = bool(ACCOUNT_SID and AUTH_TOKEN and TWILIO_NUMBER)
client = Client(ACCOUNT_SID, AUTH_TOKEN) if twilio_ready else None
# ======================================================
# 🤖 AI DISTRESS MODEL
# ======================================================
log_event("🧠 Loading distress detection model...")
MODEL_PATH = "mobilebert_distress_final"  # folder of trained model

tokenizer_ai = AutoTokenizer.from_pretrained(MODEL_PATH)
model_ai = AutoModelForSequenceClassification.from_pretrained(MODEL_PATH)

def predict_distress(text):
    inputs = tokenizer_ai(text, return_tensors="pt", truncation=True, padding=True)
    outputs = model_ai(**inputs)
    probs = torch.softmax(outputs.logits, dim=1)
    pred = torch.argmax(probs, dim=1).item()
    return pred  # 1 = distress, 0 = normal

log_event("✅ AI Model Loaded")
# ======================================================
# 🎤 AI DISTRESS CHECK FROM VOICE TEXT
# ======================================================
distress_counter = 0
last_detection_time = 0

@app.route("/check_distress", methods=["POST"])
def check_distress():
    global distress_counter, last_detection_time

    data = request.json or {}
    text = data.get("text", "")

    if not text:
        return jsonify({"result": "no_text"}), 400

    result = predict_distress(text)
    label = "DISTRESS" if result == 1 else "NORMAL"

    log_event(f"🎤 Voice Text: {text} → {label}")

    # Count distress detections
    if result == 1:
        current_time = time.time()
        if current_time - last_detection_time > 20:
            distress_counter = 0  # reset if too late

        distress_counter += 1
        last_detection_time = current_time

        log_event(f"⚠️ Distress count: {distress_counter}")

        if distress_counter >= 3:
            log_event("🚨 3 DISTRESS DETECTIONS — TRIGGERING SOS")
            distress_counter = 0
            threading.Thread(target=call_user, daemon=True).start()

    return jsonify({"result": label}), 200

# ======================================================
# 🧠 IN-MEMORY STATE (DEV ONLY)
# ======================================================
USER_PROFILE = {
    "user_phone": None,
    "pin": None,
    "guardians": []
}

OTP_STORE = {
    "otp": None,
    "expires_at": None,
    "phone": None
}

# 🔴 SOS STATE
sos_active = False
latest_location = "unknown"

# 🔒 FLAGS
call_answered = False
call_completed = False
call_duration = 0  # New: to track duration on completion
pin_cancelled = False
user_call_failed = False

# ======================================================
# 🔁 RESET SOS STATE
# ======================================================
def reset_sos_state():
    global sos_active, call_answered, call_completed, call_duration, pin_cancelled, user_call_failed
    sos_active = False
    call_answered = False
    call_completed = False
    call_duration = 0
    pin_cancelled = False
    user_call_failed = False
    log_event("🔄 SOS STATE RESET")

# ======================================================
# 🟢 HEALTH CHECK
# ======================================================
@app.route("/", methods=["GET"])
def health():
    return jsonify({
        "status": "backend_running",
        "twilio_ready": twilio_ready,
        "sos_active": sos_active,
        "user_registered": USER_PROFILE["user_phone"] is not None
    }), 200

# ======================================================
# 🟢 SEND OTP
# ======================================================
@app.route("/send_otp", methods=["POST"])
def send_otp():
    data = request.json or {}
    phone = data.get("phone")
    if not phone:
        return jsonify({"error": "Phone required"}), 400
    otp = str(random.randint(100000, 999999))
    OTP_STORE["otp"] = otp
    OTP_STORE["expires_at"] = datetime.now() + timedelta(minutes=5)
    OTP_STORE["phone"] = phone
    log_event(f"🔐 OTP GENERATED: {otp} for {phone}")
    if twilio_ready:
        client.messages.create(
            from_=TWILIO_NUMBER,
            to=phone,
            body=f"Your Raksha OTP is {otp}"
        )
        log_event("📩 OTP SENT")
    return jsonify({"status": "otp_sent"}), 200

# ======================================================
# 🟢 VERIFY OTP
# ======================================================
@app.route("/verify_otp", methods=["POST"])
def verify_otp():
    data = request.json or {}
    entered = data.get("otp")
    if not OTP_STORE["otp"]:
        return jsonify({"error": "OTP not generated"}), 400
    if datetime.now() > OTP_STORE["expires_at"]:
        return jsonify({"error": "OTP expired"}), 401
    if entered != OTP_STORE["otp"]:
        return jsonify({"error": "Invalid OTP"}), 401
    OTP_STORE["otp"] = None
    OTP_STORE["expires_at"] = None
    log_event("✅ OTP VERIFIED")
    return jsonify({"status": "otp_verified"}), 200

# ======================================================
# 🟢 SIGNUP
# ======================================================
@app.route("/signup", methods=["POST"])
def signup():
    data = request.json or {}
    phone = data.get("user_phone")
    pin = data.get("pin")
    if not phone or not pin:
        return jsonify({"error": "Phone & PIN required"}), 400
    USER_PROFILE["user_phone"] = phone
    USER_PROFILE["pin"] = pin
    log_event("✅ USER REGISTERED:", phone)
    return jsonify({"status": "signup_saved"}), 200

# ======================================================
# 🟢 ADD GUARDIAN (NEW ENDPOINT)
# ======================================================
@app.route("/add_guardian", methods=["POST"])
def add_guardian():
    data = request.json or {}
    guardian_phone = data.get("guardian_phone")
    if not guardian_phone:
        return jsonify({"error": "Guardian phone required"}), 400
    if guardian_phone not in USER_PROFILE["guardians"]:
        USER_PROFILE["guardians"].append(guardian_phone)
        log_event(f"✅ GUARDIAN ADDED: {guardian_phone}")
    return jsonify({"status": "guardian_added"}), 200

# ======================================================
# 📞 CALL USER (SOS)
# ======================================================
def call_user():
    global call_answered, call_completed
    if not twilio_ready or not USER_PROFILE["user_phone"]:
        log_event("❌ CALL FAILED: Twilio not ready or no user phone")
        return
    log_event("📞 INITIATING CALL TO USER...")
    twiml = """
    <Response>
        <Say voice="Polly.Joanna" language="en-US">
            Emergency SOS activated. If you are safe, stay on the line for at least 30 seconds to confirm. Otherwise, help will be alerted.
        </Say>
        <Pause length="5"/>
        <Say voice="Polly.Joanna" language="en-US" loop="20">
            This is an automated emergency check. Stay connected if safe.
        </Say>
    </Response>
    """
    call = client.calls.create(
        from_=TWILIO_NUMBER,
        to=USER_PROFILE["user_phone"],
        status_callback="http://192.168.17.116:5000/call_status",  # Replace with ngrok/public URL in prod
        status_callback_event=["initiated", "ringing", "answered", "completed"],
        status_callback_method="POST",
        twiml=twiml
    )
    log_event(f"📞 CALL CREATED: SID={call.sid}")

# ======================================================
# 📞 CALL STATUS WEBHOOK
# ======================================================
@app.route("/call_status", methods=["POST"])
def call_status():
    global call_answered, call_completed, call_duration, user_call_failed
    status = request.form.get("CallStatus")
    sid = request.form.get("CallSid")
    log_event(f"📞 CALL STATUS UPDATE [SID={sid}]: {status}")
    
    if status == "in-progress":
        call_answered = True
        log_event("✅ USER ANSWERED THE CALL (in-progress)")
    elif status == "completed":
        call_completed = True
        duration_str = request.form.get("CallDuration")
        call_duration = int(duration_str) if duration_str else 0
        log_event(f"⚠️ CALL COMPLETED: Duration={call_duration} seconds")
    elif status in ["no-answer", "failed", "busy"]:
        user_call_failed = True
        log_event(f"❌ USER CALL {status.upper()} — PREPARING IMMEDIATE ALERTS")
    return "", 200

# ======================================================
# 📞 CALL GUARDIAN (ALERT)
# ======================================================
def call_guardian(phone):
    if not twilio_ready: return
    log_event(f"📞 CALLING GUARDIAN {phone}...")
    twiml = """
    <Response>
        <Say voice="Polly.Joanna" language="en-US">
            This is an emergency alert from Raksha. The user has triggered an SOS. Please check your SMS for their location immediately.
        </Say>
        <Pause length="2"/>
        <Say voice="Polly.Joanna" language="en-US">
            I repeat. Emergency alert. Check your SMS for location.
        </Say>
    </Response>
    """
    try:
        call = client.calls.create(
            from_=TWILIO_NUMBER,
            to=phone,
            twiml=twiml
        )
        log_event(f"📞 GUARDIAN CALL STARTED: {call.sid}")
    except Exception as e:
        log_event(f"❌ FAILED TO CALL GUARDIAN {phone}: {e}")

# ======================================================
# ✉️ ALERT GUARDIANS
# ======================================================
def alert_guardians():
    global sos_active, call_duration
    # Wait for up to 25 seconds (20s timer + 5s buffer)
    for i in range(25):
        time.sleep(1)
        if pin_cancelled:
            log_event("🛑 SOS CANCELLED BY PIN — ACTION ABORTED (NO SMS SENT)")
            reset_sos_state()
            return

        if user_call_failed:
             log_event("⚠️ TRIGGERING ALERTS IMMEDIATELY DUE TO CALL FAILURE")
             break # Break loop early to send SMS
    
    if not sos_active:
        log_event("❌ SOS NOT ACTIVE (Manual Reset?) — NO SMS SENT")
        return
    
    # Decision logic:
    if call_answered and call_duration >= 30:
        # Answered and stayed on line long enough → assume safe
        log_event("✅ USER ANSWERED & STAYED ON LINE (duration >=30s) — ASSUMED SAFE, NO SMS SENT")
    else:
        # No answer, short call (manual cut), or auto-end without long duration → send SMS
        reason = ""
        if not call_answered:
            reason = "NO ANSWER / FAILED / BUSY"
        elif call_duration < 30:
            reason = "ANSWERED BUT CUT MANUALLY (short duration)"
        else:
            reason = "CALL ENDED AUTOMATICALLY WITHOUT CONFIRMATION"
        
        log_event(f"⚠️ SENDING ALERTS TO GUARDIANS: Reason={reason}")
        
        if not USER_PROFILE["guardians"]:
            log_event("❌ NO GUARDIANS REGISTERED — SKIPPING ALERTS")
        else:
            maps_link = f"https://maps.google.com/?q={latest_location}"

            message = (
                f"⚠️ SOS ALERT!\n"
                f"User may be in danger.\n"
                f"📍 Live Location: {maps_link}\n"
                f"Reason: {reason}"
            )

            # 1. SEND SMS
            for g in USER_PROFILE["guardians"]:
                try:
                    client.messages.create(
                        from_=TWILIO_NUMBER,
                        to=g,
                        body=message
                    )
                    log_event(f"📩 SMS SENT to {g}")
                    
                    # 2. CALL GUARDIAN (New Feature)
                    call_guardian(g)
                    
                except Exception as e:
                    log_event(f"❌ Failed to alert {g}: {e}")
    
    reset_sos_state()

# ======================================================
# 📍 UPDATE LOCATION
# ======================================================
@app.route("/update_location", methods=["POST"])
def update_location():
    global latest_location
    data = request.json or {}
    latest_location = data.get("location", "unknown")
    log_event("📍 LOCATION UPDATED:", latest_location)
    return jsonify({"status": "location_updated"}), 200

# ======================================================
# 🚨 TRIGGER SOS
# ======================================================
@app.route("/sos_trigger", methods=["POST"])
def sos_trigger():
    global sos_active, latest_location
    if sos_active:
        log_event("⚠️ SOS ALREADY ACTIVE — IGNORING TRIGGER")
        return jsonify({"status": "already_active"}), 200
    reset_sos_state()
    data = request.json or {}
    latest_location = data.get("location", "unknown")
    if not USER_PROFILE["user_phone"]:
        log_event("❌ SOS TRIGGER FAILED: User not registered")
        return jsonify({"error": "User not registered"}), 400
    sos_active = True
    log_event("🚨 SOS ACTIVATED — STARTING CALL & GUARDIAN ALERT THREADS")
    threading.Thread(target=call_user, daemon=True).start()
    threading.Thread(target=alert_guardians, daemon=True).start()
    return jsonify({"status": "SOS started"}), 200

# ======================================================
# 🟢 CANCEL SOS (PIN)
# ======================================================
@app.route("/cancel_sos", methods=["POST"])
def cancel_sos():
    global pin_cancelled
    data = request.json or {}
    if data.get("pin") != USER_PROFILE["pin"]:
        log_event("❌ CANCEL FAILED: Invalid PIN")
        return jsonify({"error": "Invalid PIN"}), 401
    pin_cancelled = True
    log_event("🛑 USER ENTERED PIN — STOPPING SOS PROCESS...")
    # NOTE: We do NOT call reset_sos_state() here immediately.
    # We let the 'alert_guardians' thread see the flag, print the log, and THEN reset.
    return jsonify({"status": "SOS cancelled"}), 200

# ======================================================
# ▶ RUN SERVER
# ======================================================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)