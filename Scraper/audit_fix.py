#!/usr/bin/env python3
"""
WikiRace Data Auditor & Fixer
Automatically cleans events.json, fixes outdated dates, and injects GPX links.
"""
import json
import sys
from datetime import datetime, timedelta
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).parent.parent
EVENTS_JSON = BASE_DIR / "events.json"

# GPX Database for major events
GPX_DATABASE = {
    "Tokyo Marathon": "https://www.marathon.tokyo/en/about/course/",
    "London Marathon": "https://www.tcslondonmarathon.com/the-event/the-course",
    "Boston Marathon": "https://www.baa.org/races/boston-marathon/enter/course-information",
    "Berlin Marathon": "https://www.bmw-berlin-marathon.com/en/your-race/map/",
    "Chicago Marathon": "https://www.chicagomarathon.com/runners/course-amenities/course-map/",
    "New York City Marathon": "https://www.nyrr.org/tcsnycmarathon/race-day/the-course",
    "Marathon des Sables": "https://www.marathondessables.com/en/marathon-des-sables/course",
    "UTMB Mont-Blanc": "https://montblanc.utmb.world/races/utmb",
    "Valencia Marathon": "https://www.valenciaciudaddelrunning.com/en/marathon/marathon-course/",
    "Paris Marathon": "https://www.schneiderelectricparismarathon.com/en/event/course",
}

# Major Event URL Fixes (to replace search URLs)
URL_FIXES = {
    "London Marathon": "https://www.tcslondonmarathon.com/",
    "Tokyo Marathon": "https://www.marathon.tokyo/",
    "Boston Marathon": "https://www.baa.org/races/boston-marathon",
    "Berlin Marathon": "https://www.bmw-berlin-marathon.com/",
    "Chicago Marathon": "https://www.chicagomarathon.com/",
    "New York City Marathon": "https://www.nyrr.org/tcsnycmarathon",
    "Paris Marathon": "https://www.schneiderelectricparismarathon.com/",
}

def audit_and_fix():
    if not EVENTS_JSON.exists():
        print(f"❌ {EVENTS_JSON} not found!")
        return

    with open(EVENTS_JSON, "r", encoding="utf-8") as f:
        data = json.load(f)

    events = data.get("events", [])
    today = datetime.now()
    fixed_count = 0
    date_fixed_count = 0
    gpx_injected_count = 0

    new_events = []
    
    for event in events:
        name = event.get("name", "")
        date_str = event.get("date", "")
        
        # 1. Fix Dates (if in the past, move to next year)
        try:
            event_date = datetime.strptime(date_str, "%Y-%m-%d")
            if event_date < today - timedelta(days=2):
                # Major events usually happen at similar times each year
                # We project them to 2026/2027
                new_date = event_date
                while new_date < today:
                    new_date = new_date.replace(year=new_date.year + 1)
                event["date"] = new_date.strftime("%Y-%m-%d")
                date_fixed_count += 1
        except Exception:
            pass

        # 2. Fix Search URLs
        reg_url = event.get("registrationUrl", "")
        if "google.com/search" in reg_url:
            for major_name, fix_url in URL_FIXES.items():
                if major_name.lower() in name.lower():
                    event["registrationUrl"] = fix_url
                    fixed_count += 1
                    break

        # 3. Inject GPX URLs
        if not event.get("gpxUrl"):
            for major_name, gpx_link in GPX_DATABASE.items():
                if major_name.lower() in name.lower():
                    event["gpxUrl"] = gpx_link
                    gpx_injected_count += 1
                    break

        # 4. Standardize Discipline
        disc = event.get("discipline", "Running")
        if "trail" in name.lower() or "ultra" in name.lower():
            event["discipline"] = "Trail"
        elif "ironman" in name.lower() or "triathlon" in name.lower():
            event["discipline"] = "Triathlon"

        new_events.append(event)

    # Update metadata
    data["events"] = new_events
    data["lastAudit"] = datetime.now().isoformat()
    data["totalEvents"] = len(new_events)

    with open(EVENTS_JSON, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"✅ Audit complete:")
    print(f"  - Dates fixed: {date_fixed_count}")
    print(f"  - URLs corrected: {fixed_count}")
    print(f"  - GPX Links injected: {gpx_injected_count}")
    print(f"  - Total events processed: {len(new_events)}")

if __name__ == "__main__":
    audit_and_fix()
