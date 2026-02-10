#!/usr/bin/env python3
"""
WikiRace URL Validator & Data Auditor
Actively checks if registration and GPX URLs are still alive.
Cleans up the database by removing broken links or dead events.
"""
import json
import requests
import sys
from datetime import datetime
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

# Paths
BASE_DIR = Path(__file__).parent.parent
EVENTS_JSON = BASE_DIR / "events.json"

def check_url(url: str, timeout: int = 5) -> bool:
    """Check if a URL is reachable and returns a success status code"""
    if not url or not url.startswith("http"):
        return False
    try:
        # Use HEAD request for speed, fall back to GET if HEAD is not allowed
        headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'}
        response = requests.head(url, timeout=timeout, allow_redirects=True, headers=headers)
        if response.status_code >= 400:
            response = requests.get(url, timeout=timeout, allow_redirects=True, headers=headers, stream=True)
        return response.status_code < 400
    except Exception:
        return False

def validate_data():
    if not EVENTS_JSON.exists():
        print(f"❌ {EVENTS_JSON} not found!")
        return

    print("🔍 Starting Active URL Validation...")
    with open(EVENTS_JSON, "r", encoding="utf-8") as f:
        data = json.load(f)

    events = data.get("events", [])
    total_initial = len(events)
    valid_events = []
    
    # Track fixes for reporting
    removed_events = 0
    removed_links = 0
    removed_gpx = 0
    
    # We use threading to speed up URL checks
    def process_event(event):
        nonlocal removed_links, removed_gpx
        
        reg_url = event.get("registrationUrl")
        gpx_url = event.get("gpxUrl")
        
        # 1. Check Registration URL
        if reg_url and not check_url(reg_url):
            print(f"  ⚠️ Broken Reg URL for: {event['name']} ({reg_url})")
            event["registrationUrl"] = "https://example.com" # Fallback instead of removing event?
            removed_links += 1
            
        # 2. Check GPX URL
        if gpx_url and not check_url(gpx_url):
            print(f"  ⚠️ Broken GPX URL for: {event['name']} ({gpx_url})")
            event["gpxUrl"] = None
            removed_gpx += 1
            
        return event

    print(f"📡 Auditing {total_initial} events...")
    with ThreadPoolExecutor(max_workers=10) as executor:
        events = list(executor.map(process_event, events))

    # 3. Final Pruning: Remove events that are effectively useless
    # Criteria: Past date OR (No valid registration AND No description)
    today = datetime.now().strftime("%Y-%m-%d")
    
    for event in events:
        is_past = event.get("date", "") < today
        has_description = len(event.get("description", "")) > 10
        has_reg = event.get("registrationUrl") != "https://example.com"
        
        if is_past:
            removed_events += 1
            continue
            
        if not has_reg and not has_description:
            print(f"  🗑️ Removing useless event: {event['name']}")
            removed_events += 1
            continue
            
        valid_events.append(event)

    # Save results
    data["events"] = valid_events
    data["lastValidation"] = datetime.now().isoformat()
    data["totalEvents"] = len(valid_events)

    with open(EVENTS_JSON, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Validation complete:")
    print(f"  - Initial events: {total_initial}")
    print(f"  - Broken Reg URLs cleaned: {removed_links}")
    print(f"  - Broken GPX URLs removed: {removed_gpx}")
    print(f"  - Dead/Past events removed: {removed_events}")
    print(f"  - Final active events: {len(valid_events)}")

if __name__ == "__main__":
    validate_data()
